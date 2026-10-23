/// SSE（Server-Sent Events / `text/event-stream`）行协议解码。
///
/// 解析规则遵循 WHATWG EventSource 规范：
/// - 行以 `\r\n` / `\n` / `\r` 分隔（交给 [LineSplitter]，本模块按行工作）；
/// - `:` 开头为注释行，忽略；
/// - `field: value` 形式，值若以单个空格开头则去掉一个空格；
/// - `field` 无冒号时值视为空串；
/// - `data` 字段多次出现时用 `\n` 连接；
/// - **空行派发事件**；派发时若没有任何字段则丢弃；
/// - 流结束时若缓冲区还有未派发的数据，[flush] 会补发。
///
/// OpenAI 约定的 `data: [DONE]` 在消费端判断，本模块按普通事件透传。
library;

import 'dart:async';
import 'dart:convert';

/// 一条完整的 SSE 事件。
class SseEvent {
  /// `event:` 字段值；缺省为 `message`（规范默认）。
  final String event;

  /// 所有 `data:` 行用 `\n` 连接后的载荷。
  final String data;

  /// `id:` 字段值（OpenAI 兼容 API 不使用，保留）。
  final String? id;

  const SseEvent({required this.event, required this.data, this.id});

  @override
  String toString() => 'SseEvent(event: $event, data: $data)';
}

/// 按行喂入、按事件吐出的有状态解码器。
///
/// 单独封装成纯类是为了可单测：网络层拿到任意字节切块后
/// 经 `utf8.decoder` + [LineSplitter] 逐行调用 [addLine] 即可。
class SseDecoder {
  final List<String> _dataLines = [];
  String? _eventType;
  String? _lastId;
  bool _hasAnyField = false;

  /// 喂入一行（不含行终止符）。
  ///
  /// 若该行触发事件派发，返回非空列表（至多一个事件），否则返回空列表。
  List<SseEvent> addLine(String line) {
    // 空行 = 派发事件。
    if (line.isEmpty) {
      final e = _dispatch();
      return e == null ? const [] : [e];
    }
    // 注释行。
    if (line.startsWith(':')) return const [];

    final colon = line.indexOf(':');
    final String field;
    final String value;
    if (colon == -1) {
      field = line;
      value = '';
    } else {
      field = line.substring(0, colon);
      value = line.substring(colon + 1);
      // 规范：值前恰好一个空格属于分隔符。
    }
    final trimmedValue = (value.startsWith(' ')) ? value.substring(1) : value;

    switch (field) {
      case 'data':
        _dataLines.add(trimmedValue);
        _hasAnyField = true;
      case 'event':
        _eventType = trimmedValue;
        _hasAnyField = true;
      case 'id':
        // 规范：含 NUL 的 id 应忽略。
        if (!trimmedValue.contains(' ')) {
          _lastId = trimmedValue;
          _hasAnyField = true;
        }
      case 'retry':
        _hasAnyField = true; // 重连间隔，API 场景无用，记录后忽略。
      default:
        break; // 未知字段忽略，且不算"有字段"。
    }
    return const [];
  }

  /// 流结束时调用：若仍有未派发数据则补发。
  SseEvent? flush() => _dispatch();

  SseEvent? _dispatch() {
    if (!_hasAnyField) return null;
    final data = _dataLines.join('\n');
    final event = SseEvent(
      event: _eventType ?? 'message',
      data: data,
      id: _lastId,
    );
    _dataLines.clear();
    _eventType = null;
    _hasAnyField = false;
    return event;
  }
}

/// 把字节流解码为 [SseEvent] 流。
///
/// UTF-8 多字节字符被 chunk 切断的情况由 [utf8.decoder] 处理。
Stream<SseEvent> decodeSseStream(Stream<List<int>> byteStream) async* {
  final decoder = SseDecoder();
  final lines =
      byteStream.transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    for (final e in decoder.addLine(line)) {
      yield e;
    }
  }
  final tail = decoder.flush();
  if (tail != null) yield tail;
}