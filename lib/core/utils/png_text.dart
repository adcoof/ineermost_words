/// PNG tEXt 块读写：角色卡导出时把 JSON 写进 PNG 的 `chara` / `ccv3` 块。
///
/// PNG 的 tEXt 文本按 Latin-1 存储；角色卡数据是「JSON → UTF-8 → base64」，
/// 因此实际写入的永远是 ASCII，不会丢中文。
library;

import 'dart:convert';
import 'dart:typed_data';

class PngTextChunk {
  final String keyword;
  final String text;

  const PngTextChunk({required this.keyword, required this.text});
}

const List<int> _pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

/// 单块上限，防止异常文件把内存打满。
const int _maxChunkBytes = 32 * 1024 * 1024;

bool isPngBytes(List<int> bytes) =>
    bytes.length >= 8 &&
    bytes[0] == _pngSignature[0] &&
    bytes[1] == _pngSignature[1] &&
    bytes[2] == _pngSignature[2] &&
    bytes[3] == _pngSignature[3] &&
    bytes[4] == _pngSignature[4] &&
    bytes[5] == _pngSignature[5] &&
    bytes[6] == _pngSignature[6] &&
    bytes[7] == _pngSignature[7];

/// 读取 PNG 里所有 tEXt 块（按文件顺序）。
List<PngTextChunk> readPngTextChunks(Uint8List png) {
  _requirePng(png);
  final chunks = <PngTextChunk>[];
  var offset = 8;
  while (offset + 8 <= png.length) {
    final length = _readUint32(png, offset);
    final typeStart = offset + 4;
    final dataStart = typeStart + 4;
    final dataEnd = dataStart + length;
    if (dataEnd + 4 > png.length) {
      throw const FormatException('PNG 数据块越界');
    }
    if (length > _maxChunkBytes) {
      throw const FormatException('PNG 数据块过大');
    }
    final type = String.fromCharCodes(png.sublist(typeStart, typeStart + 4));
    if (type == 'tEXt') {
      final data = Uint8List.sublistView(png, dataStart, dataEnd);
      final nul = data.indexOf(0);
      if (nul > 0) {
        chunks.add(
          PngTextChunk(
            keyword: latin1.decode(data.sublist(0, nul)),
            text: latin1.decode(data.sublist(nul + 1)),
          ),
        );
      }
    }
    if (type == 'IEND') break;
    offset = dataEnd + 4;
  }
  return chunks;
}

/// 在 IEND 前插入 tEXt 块；同名 keyword 的旧块会被移除，避免重复。
///
/// 其余块与 IEND 之后的尾随字节原样保留。
Uint8List insertPngTextChunks(Uint8List png, List<PngTextChunk> chunks) {
  _requirePng(png);
  final replaceKeys = {for (final chunk in chunks) chunk.keyword};
  final out = BytesBuilder();
  out.add(png.sublist(0, 8));

  var offset = 8;
  while (offset + 8 <= png.length) {
    final length = _readUint32(png, offset);
    final typeStart = offset + 4;
    final dataStart = typeStart + 4;
    final dataEnd = dataStart + length;
    if (dataEnd + 4 > png.length) {
      throw const FormatException('PNG 数据块越界');
    }
    if (length > _maxChunkBytes) {
      throw const FormatException('PNG 数据块过大');
    }
    final type = String.fromCharCodes(png.sublist(typeStart, typeStart + 4));

    if (type == 'tEXt') {
      final data = Uint8List.sublistView(png, dataStart, dataEnd);
      final nul = data.indexOf(0);
      if (nul > 0) {
        final keyword = latin1.decode(data.sublist(0, nul));
        if (replaceKeys.contains(keyword)) {
          offset = dataEnd + 4; // 跳过旧块（含 CRC）。
          continue;
        }
      }
    }

    if (type == 'IEND') {
      for (final chunk in chunks) {
        out.add(_encodeTextChunk(chunk.keyword, chunk.text));
      }
      out.add(png.sublist(offset)); // IEND 及其后的尾随字节。
      return out.toBytes();
    }

    out.add(png.sublist(offset, dataEnd + 4));
    offset = dataEnd + 4;
  }
  throw const FormatException('PNG 缺少 IEND 块');
}

/// PNG 标准的 CRC32（多项式 0xEDB88320）。
int pngCrc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

final List<int> _crcTable = _buildCrcTable();

List<int> _buildCrcTable() {
  final table = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}

Uint8List _encodeTextChunk(String keyword, String text) {
  if (keyword.isEmpty || keyword.length > 79) {
    throw ArgumentError.value(keyword, 'keyword', 'PNG tEXt 关键字长度须为 1–79');
  }
  final keywordBytes = ascii.encode(keyword);
  final textBytes = latin1.encode(text);
  final data = <int>[...keywordBytes, 0, ...textBytes];
  final type = ascii.encode('tEXt');
  final body = <int>[...type, ...data];
  final crc = pngCrc32(body);
  return Uint8List.fromList([
    ..._uint32(data.length),
    ...body,
    ..._uint32(crc),
  ]);
}

int _readUint32(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

List<int> _uint32(int value) => [
  (value >> 24) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
];

void _requirePng(Uint8List png) {
  if (!isPngBytes(png)) {
    throw const FormatException('不是合法的 PNG 文件');
  }
}
