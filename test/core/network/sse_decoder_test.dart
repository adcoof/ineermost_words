import 'dart:convert';

import 'package:ai_roleplay_chat/core/network/sse_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SseDecoder.addLine', () {
    test('空行派发 data 事件', () {
      final d = SseDecoder();
      expect(d.addLine('data: hello'), isEmpty);
      final events = d.addLine('');
      expect(events, hasLength(1));
      expect(events.single.data, 'hello');
      expect(events.single.event, 'message');
    });

    test('多个 data 行用换行连接', () {
      final d = SseDecoder();
      d.addLine('data: line1');
      d.addLine('data: line2');
      final e = d.addLine('').single;
      expect(e.data, 'line1\nline2');
    });

    test('event 字段命名事件类型', () {
      final d = SseDecoder();
      d.addLine('event: delta');
      d.addLine('data: x');
      expect(d.addLine('').single.event, 'delta');
    });

    test('值前单个空格被剥离，后续空格保留', () {
      final d = SseDecoder();
      d.addLine('data:  two spaces');
      expect(d.addLine('').single.data, ' two spaces');
    });

    test('无冒号的 data 行值为空串', () {
      final d = SseDecoder();
      d.addLine('data');
      expect(d.addLine('').single.data, '');
    });

    test('注释行忽略', () {
      final d = SseDecoder();
      d.addLine(': this is a comment');
      expect(d.addLine(''), isEmpty);
    });

    test('无任何字段的空事件不派发', () {
      final d = SseDecoder();
      expect(d.addLine(''), isEmpty);
    });

    test('未知字段被忽略', () {
      final d = SseDecoder();
      d.addLine('foo: bar');
      expect(d.addLine(''), isEmpty);
    });

    test('连续两个事件互不串扰', () {
      final d = SseDecoder();
      d.addLine('data: first');
      expect(d.addLine('').single.data, 'first');
      d.addLine('data: second');
      expect(d.addLine('').single.data, 'second');
    });
  });

  group('SseDecoder.flush', () {
    test('流结束时补发未派发的数据', () {
      final d = SseDecoder();
      d.addLine('data: tail');
      final e = d.flush();
      expect(e, isNotNull);
      expect(e!.data, 'tail');
      // 二次 flush 无内容。
      expect(d.flush(), isNull);
    });

    test('无内容时 flush 返回 null', () {
      expect(SseDecoder().flush(), isNull);
    });
  });

  group('decodeSseStream', () {
    test('OpenAI 风格：data: {json} 多帧 + [DONE]', () async {
      const raw = 'data: {"choices":[{"delta":{"content":"你"}}]}\n'
          '\n'
          'data: {"choices":[{"delta":{"content":"好"}}]}\n'
          '\n'
          'data: [DONE]\n'
          '\n';
      final events =
          await decodeSseStream(Stream.value(utf8.encode(raw))).toList();
      expect(events, hasLength(3));
      expect(events[0].data, contains('你'));
      expect(events[1].data, contains('好'));
      expect(events[2].data, '[DONE]');
    });

    test('chunk 在多字节 UTF-8 字符中间切断仍能正确解码', () async {
      final full = utf8.encode('data: 你好\n\n');
      // 把字节流切成 1 字节一块，模拟任意网络切块。
      final chunks = Stream.fromIterable([
        for (var i = 0; i < full.length; i++) [full[i]]
      ]);
      final events = await decodeSseStream(chunks).toList();
      expect(events.single.data, '你好');
    });

    test('CRLF 行终止符', () async {
      const raw = 'data: a\r\n\r\ndata: b\r\n\r\n';
      final events =
          await decodeSseStream(Stream.value(utf8.encode(raw))).toList();
      expect(events.map((e) => e.data), ['a', 'b']);
    });

    test('事件被网络 chunk 从中间切断仍能正确拼回', () async {
      const raw = 'data: {"par';
      const raw2 = 'tial": true}\n\n';
      final events = await decodeSseStream(Stream.fromIterable([
        utf8.encode(raw),
        utf8.encode(raw2),
      ])).toList();
      expect(events.single.data, '{"partial": true}');
    });

    test('流末尾无空行时补发', () async {
      const raw = 'data: last';
      final events =
          await decodeSseStream(Stream.value(utf8.encode(raw))).toList();
      expect(events.single.data, 'last');
    });
  });
}