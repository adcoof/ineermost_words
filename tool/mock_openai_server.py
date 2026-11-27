#!/usr/bin/env python3
"""Minimal OpenAI-compatible mock server for 心语 manual testing.

Why this file lives in tool/ instead of build/:
    `flutter clean` deletes build/, which previously removed the old mock
    server. tool/ survives clean.

Usage:
    python tool/mock_openai_server.py
    # device/emulator: adb reverse tcp:8089 tcp:8089
    # app API base URL: http://127.0.0.1:8089/v1

Scenarios are selected by keywords in the last user message:
    空流 / empty      -> no content deltas (empty reply)
    长度 / length     -> content then finish_reason=length
    整包 / json       -> a single non-SSE JSON response
    推理 / reasoning  -> reasoning_content only, no content
    错误 / error      -> HTTP 500 JSON error
    anything else     -> two short streamed bubbles with emotion tags
"""

from __future__ import annotations

import argparse
import json
import socketserver
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any


def _chunk(model: str, delta: dict[str, Any], finish: str | None = None) -> dict[str, Any]:
    return {
        "id": "chatcmpl-mock",
        "object": "chat.completion.chunk",
        "created": int(time.time()),
        "model": model,
        "choices": [
            {
                "index": 0,
                "delta": delta,
                "finish_reason": finish,
            }
        ],
    }


def _completion(model: str, content: str) -> dict[str, Any]:
    return {
        "id": "chatcmpl-mock",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": model,
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": content},
                "finish_reason": "stop",
            }
        ],
    }


def _last_user_text(body: dict[str, Any]) -> str:
    messages = body.get("messages")
    if not isinstance(messages, list):
        return ""
    for message in reversed(messages):
        if isinstance(message, dict) and message.get("role") == "user":
            content = message.get("content", "")
            if isinstance(content, str):
                return content
            if isinstance(content, list):
                parts = [
                    part.get("text", "")
                    for part in content
                    if isinstance(part, dict) and part.get("type") == "text"
                ]
                return "\n".join(parts)
    return ""


class MockServer(ThreadingHTTPServer):
    """HTTPServer without socket.getfqdn().

    On some Windows setups the machine hostname is not valid UTF-8, so
    HTTPServer.server_bind() crashes inside socket.getfqdn(host). We only
    need a local mock, so bind the socket and use the host string directly.
    """

    def server_bind(self) -> None:
        socketserver.TCPServer.server_bind(self)
        host, port = self.server_address[:2]
        self.server_name = str(host)
        self.server_port = port


class Handler(BaseHTTPRequestHandler):
    server_version = "XinyuMock/1.0"

    # BaseHTTPRequestHandler.address_string() does a reverse DNS lookup
    # (socket.getfqdn), which can hang on some Windows/emulator networks.
    def address_string(self) -> str:
        return self.client_address[0]

    def log_message(self, fmt: str, *args: Any) -> None:
        print("[mock]", fmt % args, flush=True)

    def _write_json(self, status: int, payload: dict[str, Any]) -> None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _start_sse(self) -> None:
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        # Close after [DONE] so curl/scripts don't hang on keep-alive.
        self.send_header("Connection", "close")
        self.end_headers()

    def _sse(self, payload: dict[str, Any]) -> None:
        line = f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"
        self.wfile.write(line.encode("utf-8"))
        self.wfile.flush()

    def _done(self) -> None:
        self.wfile.write(b"data: [DONE]\n\n")
        self.wfile.flush()
        self.close_connection = True

    def do_GET(self) -> None:  # noqa: N802
        if self.path in ("/health", "/v1/health"):
            self._write_json(200, {"ok": True})
            return
        self._write_json(404, {"error": {"message": "not found"}})

    def do_POST(self) -> None:  # noqa: N802
        if self.path not in ("/v1/chat/completions", "/chat/completions"):
            self._write_json(404, {"error": {"message": "not found"}})
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            raw = self.rfile.read(length) if length > 0 else b"{}"
            body = json.loads(raw.decode("utf-8"))
        except (ValueError, json.JSONDecodeError) as exc:
            self._write_json(400, {"error": {"message": f"bad request: {exc}"}})
            return

        model = str(body.get("model") or "mock-model")
        stream = bool(body.get("stream", False))
        text = _last_user_text(body)
        lowered = text.lower()

        if "错误" in text or "error" in lowered:
            self._write_json(
                500,
                {"error": {"message": "mock error", "type": "mock_error"}},
            )
            return

        if "整包" in text or "json" in lowered:
            self._write_json(
                200,
                _completion(model, "这是整包 JSON 兜底回复。<emotion:amused>"),
            )
            return

        if not stream:
            if "空流" in text or "empty" in lowered:
                content = ""
            elif "推理" in text or "reasoning" in lowered:
                content = ""
            elif "长度" in text or "length" in lowered:
                content = "这是一段因为长度上限被截断的回复"
            else:
                content = "收到啦～\n[P]\n这是 mock 的回复"
            self._write_json(200, _completion(model, content))
            return

        self._start_sse()

        if "空流" in text or "empty" in lowered:
            self._sse(_chunk(model, {}, "stop"))
            self._done()
            return

        if "推理" in text or "reasoning" in lowered:
            self._sse(_chunk(model, {"reasoning_content": "先想一想……"}))
            self._sse(_chunk(model, {}, "stop"))
            self._done()
            return

        if "长度" in text or "length" in lowered:
            self._sse(_chunk(model, {"content": "这是一段因为长度上限被截断的回复"}))
            self._sse(_chunk(model, {}, "length"))
            self._done()
            return

        # Default: a realistic two-bubble reply.
        self._sse(_chunk(model, {"content": "<emotion:amused>收到啦～"}))
        self._sse(_chunk(model, {"content": "\n[P]\n"}))
        self._sse(_chunk(model, {"content": "<emotion:shy>这是 mock 的回复"}))
        self._sse(_chunk(model, {}, "stop"))
        self._done()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8089)
    args = parser.parse_args()

    server = MockServer((args.host, args.port), Handler)
    print(
        f"mock OpenAI server on http://{args.host}:{args.port}/v1\n"
        "scenarios: 空流 / 长度 / 整包 / 推理 / 错误\n"
        "device: adb reverse tcp:8089 tcp:8089",
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nbye", flush=True)
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
