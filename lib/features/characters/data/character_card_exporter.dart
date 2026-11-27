/// 角色卡导出：ST V2/V3 JSON 与 PNG 角色卡。
///
/// 已知字段写入标准键；心语扩展档案写入 `extensions.xinyu`（可选），
/// 第三方 extensions 与未识别字段原样合并回去；世界书条目按 ST 结构输出，
/// 未编辑过的条目从 `source_json` 合并原始字段。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../core/utils/png_text.dart';
import '../domain/character.dart';
import '../domain/lore_entry.dart';

enum CharacterCardFormat {
  v2Json('ST V2 JSON', 'json'),
  v3Json('ST V3 JSON', 'json'),
  png('PNG 角色卡', 'png');

  const CharacterCardFormat(this.label, this.extension);

  final String label;
  final String extension;
}

class CharacterExport {
  final Uint8List bytes;
  final String fileName;
  final List<String> warnings;

  const CharacterExport({
    required this.bytes,
    required this.fileName,
    required this.warnings,
  });
}

class CharacterCardExporter {
  const CharacterCardExporter();

  /// 导出 V2 JSON 文件。
  CharacterExport exportV2({
    required Character character,
    required List<LoreEntry> lore,
    bool includeXinyuExtension = true,
  }) {
    final json = exportJsonString(
      format: CharacterCardFormat.v2Json,
      character: character,
      lore: lore,
      includeXinyuExtension: includeXinyuExtension,
    );
    return CharacterExport(
      bytes: Uint8List.fromList(utf8.encode(json)),
      fileName: '${_safeName(character.name)}_v2.json',
      warnings: lossWarnings(
        character: character,
        includeXinyuExtension: includeXinyuExtension,
      ),
    );
  }

  /// 导出 V3 JSON 文件。
  CharacterExport exportV3({
    required Character character,
    required List<LoreEntry> lore,
    bool includeXinyuExtension = true,
  }) {
    final json = exportJsonString(
      format: CharacterCardFormat.v3Json,
      character: character,
      lore: lore,
      includeXinyuExtension: includeXinyuExtension,
    );
    return CharacterExport(
      bytes: Uint8List.fromList(utf8.encode(json)),
      fileName: '${_safeName(character.name)}_v3.json',
      warnings: lossWarnings(
        character: character,
        includeXinyuExtension: includeXinyuExtension,
      ),
    );
  }

  /// 导出 PNG 角色卡（立绘 + `chara`/`ccv3` tEXt 块）。
  CharacterExport exportPng({
    required Character character,
    required List<LoreEntry> lore,
    required Uint8List avatarBytes,
    bool includeXinyuExtension = true,
  }) {
    final png = exportPngBytes(
      character: character,
      lore: lore,
      avatarBytes: avatarBytes,
      includeXinyuExtension: includeXinyuExtension,
    );
    return CharacterExport(
      bytes: png,
      fileName: '${_safeName(character.name)}.png',
      warnings: lossWarnings(
        character: character,
        includeXinyuExtension: includeXinyuExtension,
      ),
    );
  }

  /// 生成 ST 角色卡 JSON 字符串（V2 或 V3）。
  String exportJsonString({
    required CharacterCardFormat format,
    required Character character,
    required List<LoreEntry> lore,
    bool includeXinyuExtension = true,
  }) {
    final isV3 = format == CharacterCardFormat.v3Json;
    final data = _buildData(
      character: character,
      lore: lore,
      isV3: isV3,
      includeXinyuExtension: includeXinyuExtension,
    );
    final root = <String, dynamic>{
      'spec': isV3 ? 'chara_card_v3' : 'chara_card_v2',
      'spec_version': isV3 ? '3.0' : '2.0',
      'data': data,
    };
    // 未识别的根字段原样带回；不覆盖 spec/data。
    for (final entry in character.extensions.unknownRoot.entries) {
      root.putIfAbsent(entry.key, () => entry.value);
    }
    return const JsonEncoder.withIndent('  ').convert(root);
  }

  /// 生成 PNG 角色卡字节。
  Uint8List exportPngBytes({
    required Character character,
    required List<LoreEntry> lore,
    required Uint8List avatarBytes,
    bool includeXinyuExtension = true,
  }) {
    final v2 = exportJsonString(
      format: CharacterCardFormat.v2Json,
      character: character,
      lore: lore,
      includeXinyuExtension: includeXinyuExtension,
    );
    final v3 = exportJsonString(
      format: CharacterCardFormat.v3Json,
      character: character,
      lore: lore,
      includeXinyuExtension: includeXinyuExtension,
    );
    final png = ensurePngBytes(avatarBytes);
    return insertPngTextChunks(png, [
      PngTextChunk(keyword: 'chara', text: base64Encode(utf8.encode(v2))),
      PngTextChunk(keyword: 'ccv3', text: base64Encode(utf8.encode(v3))),
    ]);
  }

  /// 目标格式无法携带的心语数据，导出前展示。
  List<String> lossWarnings({
    required Character character,
    required bool includeXinyuExtension,
  }) => [
    if (character.profile.promptText.isNotEmpty && !includeXinyuExtension)
      '外貌/背景/关系/语言风格等心语扩展档案不会写入角色卡',
    '跨会话记忆、长期事实、用户画像不会写入角色卡',
    '音色配置、Live2D/桌宠绑定、表情包不会写入角色卡',
    '角色版本历史与 AI 修改历史不会写入角色卡',
  ];

  Map<String, dynamic> _buildData({
    required Character character,
    required List<LoreEntry> lore,
    required bool isV3,
    required bool includeXinyuExtension,
  }) {
    final profile = character.profile;
    final data = <String, dynamic>{
      'name': character.name,
      'description': character.description,
      'personality': character.personality,
      'scenario': character.scenario,
      'first_mes': character.firstMessage,
      'mes_example': character.exampleDialogue,
      'creator_notes': profile.creator.notes,
      'system_prompt': profile.runConfig.systemPrompt,
      'post_history_instructions':
          profile.runConfig.postHistoryInstructions,
      'alternate_greetings': character.alternateGreetings,
      'tags': profile.creator.tags,
      'creator': profile.creator.author,
      'character_version': profile.creator.version,
      'extensions': _buildExtensions(
        character,
        includeXinyuExtension: includeXinyuExtension,
      ),
    };
    if (isV3 && profile.basic.nickname.trim().isNotEmpty) {
      data['nickname'] = profile.basic.nickname.trim();
    }
    final book = _buildCharacterBook(character, lore);
    if (book != null) data['character_book'] = book;

    // 未识别的 data 字段（assets/group_only_greetings/source_url 等）原样带回；
    // 已知字段优先，不被旧值覆盖。
    for (final entry in character.extensions.unknownData.entries) {
      data.putIfAbsent(entry.key, () => entry.value);
    }
    return data;
  }

  Map<String, dynamic> _buildExtensions(
    Character character, {
    required bool includeXinyuExtension,
  }) {
    final extensions = <String, dynamic>{
      ...character.extensions.stExtensions,
    };
    if (includeXinyuExtension) {
      extensions['xinyu'] = <String, dynamic>{
        'format': 1,
        'profile': character.profile.toJson(),
        'source': character.source,
      };
    } else {
      extensions.remove('xinyu');
    }
    return extensions;
  }

  Map<String, dynamic>? _buildCharacterBook(
    Character character,
    List<LoreEntry> lore,
  ) {
    final meta = character.extensions.bookMeta;
    if (lore.isEmpty && meta.isEmpty) return null;
    return <String, dynamic>{
      ...meta,
      'entries': [for (final entry in lore) _loreEntryJson(entry)],
    };
  }

  Map<String, dynamic> _loreEntryJson(LoreEntry entry) {
    final source = _decodeMap(entry.sourceJson);
    return <String, dynamic>{
      ...source,
      'keys': entry.keys,
      'content': entry.content,
      'enabled': entry.enabled,
      'position': entry.position == 'after' ? 'after_char' : 'before_char',
      'insertion_order': entry.priority,
      'depth': entry.depth,
    };
  }

  Map<String, dynamic> _decodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // 坏原文按空对象处理；当前字段仍会写入。
    }
    return const {};
  }

  String _safeName(String name) {
    var safe = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    safe = safe.replaceAll(RegExp('_+'), '_');
    safe = safe.replaceAll(RegExp(r'^_|_$'), '');
    if (safe.isEmpty) safe = 'character';
    if (safe.length > 40) safe = safe.substring(0, 40);
    return safe;
  }
}

/// 非 PNG 立绘先转 PNG；解码失败直接报错，不生成坏文件。
Uint8List ensurePngBytes(Uint8List bytes) {
  if (isPngBytes(bytes)) return bytes;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw ArgumentError('无法解析立绘图片');
  }
  return Uint8List.fromList(img.encodePng(decoded));
}
