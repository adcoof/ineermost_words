/// SillyTavern 角色卡导入：PNG（tEXt `chara`/`ccv3` 键，base64 JSON）或纯 JSON。
///
/// 兼容两种结构：
/// - V2 包装：`{"spec": "chara_card_v2", "data": {...}}`，正文在 data 下；
/// - 扁平结构（V1 / 部分工具导出）：字段直接在根对象。
///
/// ST 官方导出的 V2 PNG 同时写 `chara`（V1 投影）与 `ccv3`（V2 全量）两个
/// tEXt 块；本实现收集全部候选、逐个容错解码，ccv3 优先、chara 兜底。
library;

import 'dart:convert';
import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';

/// 单个 tEXt 数据块的大小上限（防超大卡在低端设备上 OOM）。
const int _maxChunkBytes = 16 * 1024 * 1024;

/// 从角色卡解析出的草稿（尚未入库）。
class CharacterDraft {
  final String name;
  final String description;
  final String personality;
  final String scenario;
  final String firstMessage;
  final String exampleDialogue;

  /// 原始 PNG 字节（卡片本身是图片时非空），可直接存为立绘。
  final Uint8List? pngBytes;

  const CharacterDraft({
    required this.name,
    required this.description,
    required this.personality,
    required this.scenario,
    required this.firstMessage,
    required this.exampleDialogue,
    this.pngBytes,
  });
}

class SillyTavernImporter {
  const SillyTavernImporter();

  /// 解析角色卡字节。PNG 走 tEXt 提取，其余按 JSON 尝试。
  CharacterDraft parse(Uint8List bytes) {
    if (_isPng(bytes)) {
      final candidates = _extractCardJsons(bytes);
      if (candidates.isEmpty) {
        throw const ParseException('PNG 中未找到 chara/ccv3 角色数据（tEXt 块）');
      }
      Object? lastError;
      for (final jsonText in candidates) {
        try {
          return _fromJsonText(jsonText, pngBytes: bytes);
        } catch (e) {
          lastError = e; // 该候选损坏，尝试下一个。
        }
      }
      throw ParseException('角色卡数据解析失败', lastError);
    }
    // 可能带 BOM 或前导空白。
    final text = utf8.decode(bytes, allowMalformed: true);
    return _fromJsonText(text);
  }

  CharacterDraft _fromJsonText(String jsonText, {Uint8List? pngBytes}) {
    final cleaned = jsonText.startsWith('﻿') ? jsonText.substring(1) : jsonText;
    final Object? decoded;
    try {
      decoded = jsonDecode(cleaned);
    } catch (e) {
      throw ParseException('角色卡 JSON 解析失败', e);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ParseException('角色卡 JSON 顶层必须是对象');
    }
    // V2：正文在 data 下；否则视为扁平结构。
    final data = decoded['data'] is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map)
        : decoded;

    return CharacterDraft(
      name: _str(data['name'], '未命名角色'),
      description: _str(data['description']),
      personality: _str(data['personality']),
      scenario: _str(data['scenario']),
      firstMessage: _str(data['first_mes'] ?? data['first_message']),
      exampleDialogue: _str(data['mes_example'] ?? data['example_dialogue']),
      pngBytes: pngBytes,
    );
  }

  /// 字段容错：字符串裁剪；数字转字符串；字符串数组按行拼接
  /// （部分工具会把结构化对话条目导出为数组而非字符串）。
  static String _str(Object? v, [String fallback = '']) {
    if (v == null) return fallback;
    if (v is String) return v.trim();
    if (v is num) return v.toString();
    if (v is List) {
      final parts = [
        for (final e in v)
          if (e is String && e.trim().isNotEmpty) e.trim(),
      ];
      return parts.isEmpty ? fallback : parts.join('\n');
    }
    return fallback;
  }

  static bool _isPng(List<int> b) =>
      b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47 &&
      b[4] == 0x0D &&
      b[5] == 0x0A &&
      b[6] == 0x1A &&
      b[7] == 0x0A;

  /// 遍历 PNG 块，收集 chara/ccv3 的 JSON 文本候选（ccv3 优先）。
  static List<String> _extractCardJsons(Uint8List bytes) {
    String? charaJson;
    String? ccv3Json;
    var offset = 8;
    while (offset + 8 <= bytes.length) {
      final length = (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
      final typeStart = offset + 4;
      final dataStart = typeStart + 4;
      final dataEnd = dataStart + length;
      if (dataEnd + 4 > bytes.length) break; // 块越界，文件损坏。
      if (length > _maxChunkBytes) {
        throw const ParseException('角色卡数据块过大，无法导入');
      }

      final type = String.fromCharCodes(bytes.sublist(typeStart, typeStart + 4));
      if (type == 'tEXt') {
        final data = Uint8List.sublistView(bytes, dataStart, dataEnd);
        final nul = data.indexOf(0);
        if (nul > 0) {
          final keyword = ascii.decode(data.sublist(0, nul), allowInvalid: true);
          if (keyword == 'chara' || keyword == 'ccv3') {
            final b64 = latin1.decode(data.sublist(nul + 1));
            final cleaned = b64.replaceAll(RegExp(r'\s'), '');
            String? json;
            try {
              json = utf8.decode(base64Decode(cleaned));
            } catch (_) {
              json = null; // 该块损坏，留给候选回退逻辑。
            }
            if (json != null) {
              if (keyword == 'ccv3') {
                ccv3Json ??= json;
              } else {
                charaJson ??= json;
              }
            }
          }
        }
      }
      if (type == 'IEND') break;
      offset = dataEnd + 4; // 跳过 CRC。
    }
    return [?ccv3Json, ?charaJson];
  }
}
