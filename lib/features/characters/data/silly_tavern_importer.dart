/// SillyTavern 角色卡导入：PNG（tEXt `chara`/`ccv3` 键，base64 JSON）或纯 JSON。
///
/// 兼容三种结构：
/// - V3 包装：`{"spec": "chara_card_v3", "data": {...}}`；
/// - V2 包装：`{"spec": "chara_card_v2", "data": {...}}`；
/// - 扁平结构（V1 / 部分工具导出）：字段直接在根对象。
///
/// ST 官方导出的 V2 PNG 同时写 `chara`（V1 投影）与 `ccv3`（V2/V3 全量）两个
/// tEXt 块；本实现收集全部候选、逐个容错解码，ccv3 优先、chara 兜底。
///
/// v2.1 起：已知字段映射到 CharacterProfile；未识别字段、第三方 extensions 与
/// 世界书条目原文全部保留，避免导入→导出丢数据。
library;

import 'dart:convert';
import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../domain/character_extensions.dart';
import '../domain/character_profile.dart';

/// 单个 tEXt 数据块的大小上限（防超大卡在低端设备上 OOM）。
const int _maxChunkBytes = 16 * 1024 * 1024;

/// 已映射到心语字段的 `data` 键；其余全部进入 extensions.unknownData。
const Set<String> _knownDataKeys = {
  'name',
  'description',
  'personality',
  'scenario',
  'first_mes',
  'first_message',
  'mes_example',
  'example_dialogue',
  'creator_notes',
  'system_prompt',
  'post_history_instructions',
  'alternate_greetings',
  'alternateGreetings',
  'character_book',
  'tags',
  'creator',
  'character_version',
  'extensions',
  'nickname',
  // 扁平卡偶尔也带 spec；它们是格式元数据，不应进入 unknownData。
  'spec',
  'spec_version',
};

/// 已处理的根键；其余进入 extensions.unknownRoot。
const Set<String> _knownRootKeys = {'spec', 'spec_version', 'data'};

/// 从角色卡解析出的草稿（尚未入库）。
class CharacterDraft {
  final String name;
  final String description;
  final String personality;
  final String scenario;
  final String firstMessage;
  final String exampleDialogue;
  final List<String> alternateGreetings;

  /// 角色卡内嵌世界书（character_book）；导入后默认不启用。
  final List<LoreDraft> loreDrafts;

  /// 扩展档案（昵称/创作者/运行配置等）。
  final CharacterProfile profile;

  /// 第三方扩展与未识别字段。
  final CharacterExtensions extensions;

  /// v1 | v2 | v3
  final String format;

  /// 导入过程中的提示（未知 spec、世界书跳过、卡内提示等）。
  final List<String> warnings;

  /// 原始 PNG 字节（卡片本身是图片时非空），可直接存为立绘。
  final Uint8List? pngBytes;

  const CharacterDraft({
    required this.name,
    required this.description,
    required this.personality,
    required this.scenario,
    required this.firstMessage,
    required this.exampleDialogue,
    this.alternateGreetings = const [],
    this.loreDrafts = const [],
    this.profile = CharacterProfile.empty,
    this.extensions = CharacterExtensions.empty,
    this.format = 'v1',
    this.warnings = const [],
    this.pngBytes,
  });

  int get preservedKeyCount => extensions.preservedKeyCount;
}

class LoreDraft {
  const LoreDraft({
    required this.keys,
    required this.content,
    this.position = 'before',
    this.depth = 0,
    this.priority = 0,
    this.sourceJson = '{}',
  });

  final List<String> keys;
  final String content;
  final String position;
  final int depth;
  final int priority;

  /// 导入时的完整条目原文，导出时合并。
  final String sourceJson;
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
      for (final candidate in candidates) {
        try {
          return _fromJsonText(
            candidate.json,
            pngBytes: bytes,
            keyword: candidate.keyword,
          );
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

  CharacterDraft _fromJsonText(
    String jsonText, {
    Uint8List? pngBytes,
    String? keyword,
  }) {
    final cleaned =
        jsonText.startsWith('﻿') ? jsonText.substring(1) : jsonText;
    final Object? decoded;
    try {
      decoded = jsonDecode(cleaned);
    } catch (e) {
      throw ParseException('角色卡 JSON 解析失败', e);
    }
    if (decoded is! Map) {
      throw const ParseException('角色卡 JSON 顶层必须是对象');
    }
    final root = Map<String, dynamic>.from(decoded);
    // V2/V3：正文在 data 下；否则视为扁平结构。
    final dataRaw = root['data'];
    final hasWrapper = dataRaw is Map;
    final data = hasWrapper
        ? Map<String, dynamic>.from(dataRaw)
        : root;

    final spec = _str(root['spec']);
    final format = _formatOf(spec, hasWrapper, keyword);
    final warnings = <String>[];
    if (spec.isNotEmpty &&
        spec != 'chara_card_v2' &&
        spec != 'chara_card_v3') {
      warnings.add('未知 spec「$spec」，按 ${format.toUpperCase()} 解析');
    }

    final mappedProfile = CharacterProfile(
      basic: BasicProfile(nickname: _str(data['nickname'])),
      creator: CreatorProfile(
        author: _str(data['creator']),
        version: _str(data['character_version']),
        tags: _tags(data['tags']),
        notes: _str(data['creator_notes']),
      ),
      runConfig: RunConfigProfile(
        systemPrompt: _str(data['system_prompt']),
        postHistoryInstructions: _str(data['post_history_instructions']),
      ),
    );
    // 心语导出的卡会把扩展档案写在 extensions.xinyu.profile；
    // 回读时以它为底，再用 ST 标准字段覆盖，保证导入→导出→再导入不丢档案。
    final profile = _mergeProfile(
      _profileFromXinyu(data['extensions']),
      mappedProfile,
    );

    final unknownData = <String, dynamic>{
      for (final entry in data.entries)
        if (!_knownDataKeys.contains(entry.key)) entry.key: entry.value,
    };
    final stExtensionsRaw = data['extensions'];
    final stExtensions = stExtensionsRaw is Map
        ? Map<String, dynamic>.from(stExtensionsRaw)
        : const <String, dynamic>{};
    if (stExtensionsRaw != null && stExtensionsRaw is! Map) {
      unknownData['extensions'] = stExtensionsRaw;
    }

    final unknownRoot = <String, dynamic>{};
    if (hasWrapper) {
      for (final entry in root.entries) {
        if (!_knownRootKeys.contains(entry.key)) {
          unknownRoot[entry.key] = entry.value;
        }
      }
    }

    final book = data['character_book'];
    var bookMeta = const <String, dynamic>{};
    var loreDrafts = const <LoreDraft>[];
    if (book is Map) {
      final bookMap = Map<String, dynamic>.from(book);
      bookMeta = Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(bookMap)..remove('entries'),
      );
      loreDrafts = _loreDrafts(bookMap);
      final rawEntries = bookMap['entries'];
      if (rawEntries is List && rawEntries.isNotEmpty && loreDrafts.isEmpty) {
        warnings.add('世界书条目缺少关键词或正文，已跳过');
      }
    } else if (book != null) {
      unknownData['character_book'] = book;
    }
    if (loreDrafts.isNotEmpty) {
      warnings.add('世界书 ${loreDrafts.length} 条待导入，默认禁用');
    }
    if (profile.runConfig.systemPrompt.isNotEmpty ||
        profile.runConfig.postHistoryInstructions.isNotEmpty) {
      warnings.add('角色卡自带的系统提示 / 历史后置指令已保存');
    }

    final extensions = CharacterExtensions(
      stExtensions: Map<String, dynamic>.unmodifiable(stExtensions),
      unknownData: Map<String, dynamic>.unmodifiable(unknownData),
      unknownRoot: Map<String, dynamic>.unmodifiable(unknownRoot),
      bookMeta: bookMeta,
    );

    return CharacterDraft(
      name: _str(data['name'], '未命名角色'),
      description: _str(data['description']),
      personality: _str(data['personality']),
      scenario: _str(data['scenario']),
      firstMessage: _str(data['first_mes'] ?? data['first_message']),
      exampleDialogue: _str(data['mes_example'] ?? data['example_dialogue']),
      alternateGreetings: _strList(
        data['alternate_greetings'] ?? data['alternateGreetings'],
      ),
      loreDrafts: loreDrafts,
      profile: profile,
      extensions: extensions,
      format: format,
      warnings: warnings,
      pngBytes: pngBytes,
    );
  }

  static String _formatOf(String spec, bool hasWrapper, String? keyword) {
    if (spec == 'chara_card_v3') return 'v3';
    if (spec == 'chara_card_v2') return 'v2';
    if (keyword == 'ccv3') return 'v3';
    if (hasWrapper) return 'v2';
    return 'v1';
  }

  /// 读取心语导出卡里的 `extensions.xinyu.profile`。
  static CharacterProfile? _profileFromXinyu(Object? extensions) {
    if (extensions is! Map) return null;
    final xinyu = extensions['xinyu'];
    if (xinyu is! Map) return null;
    final profile = xinyu['profile'];
    if (profile is! Map) return null;
    return CharacterProfile.fromJson(Map<String, dynamic>.from(profile));
  }

  /// 以心语扩展档案为底，用 ST 标准字段覆盖非空值。
  static CharacterProfile _mergeProfile(
    CharacterProfile? embedded,
    CharacterProfile mapped,
  ) {
    if (embedded == null) return mapped;
    return embedded.copyWith(
      basic: embedded.basic.copyWith(
        nickname: mapped.basic.nickname.trim().isNotEmpty
            ? mapped.basic.nickname
            : embedded.basic.nickname,
      ),
      creator: embedded.creator.copyWith(
        author: mapped.creator.author.trim().isNotEmpty
            ? mapped.creator.author
            : null,
        version: mapped.creator.version.trim().isNotEmpty
            ? mapped.creator.version
            : null,
        tags: mapped.creator.tags.isNotEmpty ? mapped.creator.tags : null,
        notes: mapped.creator.notes.trim().isNotEmpty
            ? mapped.creator.notes
            : null,
      ),
      runConfig: embedded.runConfig.copyWith(
        systemPrompt: mapped.runConfig.systemPrompt.trim().isNotEmpty
            ? mapped.runConfig.systemPrompt
            : null,
        postHistoryInstructions:
            mapped.runConfig.postHistoryInstructions.trim().isNotEmpty
            ? mapped.runConfig.postHistoryInstructions
            : null,
      ),
    );
  }

  /// ST V2/V3 character_book.entries → 世界书草稿（默认不启用）。
  static List<LoreDraft> _loreDrafts(Map<String, dynamic> book) {
    final entries = book['entries'];
    if (entries is! List) return const [];
    final drafts = <LoreDraft>[];
    for (final raw in entries) {
      if (raw is! Map) continue;
      final entry = Map<String, dynamic>.from(raw);
      final content = _str(entry['content']);
      final keys = _strList(entry['keys'] ?? entry['key']);
      if (content.isEmpty || keys.isEmpty) continue;
      final positionRaw = entry['position'];
      final position = positionRaw == 1 ||
              positionRaw == 'after' ||
              positionRaw == 'after_char'
          ? 'after'
          : 'before';
      final order = entry['insertion_order'] ?? entry['priority'];
      final priority = order is num ? order.toInt() : 0;
      final depthRaw = entry['depth'];
      final depth = depthRaw is num ? depthRaw.toInt() : 0;
      drafts.add(
        LoreDraft(
          keys: keys,
          content: content,
          position: position,
          depth: depth,
          priority: priority,
          sourceJson: jsonEncode(entry),
        ),
      );
    }
    return drafts;
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

  static List<String> _strList(Object? v) {
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is String && e.trim().isNotEmpty) e.trim(),
    ];
  }

  /// tags 可能是数组，也可能是逗号分隔字符串。
  static List<String> _tags(Object? v) {
    if (v is List) return _strList(v);
    if (v is String) {
      return [
        for (final part in v.split(RegExp(r'[,，]')))
          if (part.trim().isNotEmpty) part.trim(),
      ];
    }
    return const [];
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
  static List<({String keyword, String json})> _extractCardJsons(
    Uint8List bytes,
  ) {
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
    return [
      if (ccv3Json != null) (keyword: 'ccv3', json: ccv3Json),
      if (charaJson != null) (keyword: 'chara', json: charaJson),
    ];
  }
}
