import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/core/utils/png_text.dart';
import 'package:ai_roleplay_chat/features/characters/data/character_card_exporter.dart';
import 'package:ai_roleplay_chat/features/characters/data/silly_tavern_importer.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character_extensions.dart';
import 'package:ai_roleplay_chat/features/characters/domain/character_profile.dart';
import 'package:ai_roleplay_chat/features/characters/domain/lore_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  const exporter = CharacterCardExporter();

  final character = Character(
    id: 'c1',
    name: '阿雪',
    description: '银发红瞳',
    personality: '冷淡',
    scenario: '天台',
    firstMessage: '……你来干什么？',
    exampleDialogue: '{{user}}：你好\n{{char}}：哼。',
    alternateGreetings: const ['雨天', '放学后'],
    source: 'st_v3',
    profile: const CharacterProfile(
      basic: BasicProfile(nickname: '小雪', age: '17'),
      appearance: AppearanceProfile(hair: '银白长发', eyes: '红瞳'),
      background: BackgroundProfile(origin: '北境'),
      creator: CreatorProfile(
        author: '作者',
        version: '1.2',
        tags: ['校园'],
        notes: '备注',
      ),
      runConfig: RunConfigProfile(
        systemPrompt: '保持冷淡',
        postHistoryInstructions: '不要总结',
      ),
    ),
    extensions: const CharacterExtensions(
      stExtensions: {
        'depth_prompt': {'depth': 4},
      },
      unknownData: {
        'assets': [
          {'type': 'icon'},
        ],
        'group_only_greetings': ['群聊'],
      },
      unknownRoot: {'x_root': 'keep'},
      bookMeta: {'name': '世界观', 'scan_depth': 3},
    ),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final lore = [
    LoreEntry(
      id: 'l1',
      characterId: 'c1',
      keys: const ['天台'],
      content: '天台的风很大',
      position: 'after',
      depth: 2,
      priority: 5,
      enabled: false,
      sourceJson: '{"secondary_keys":["夜"],"extensions":{"x":1}}',
      createdAt: DateTime(2026),
    ),
  ];

  Map<String, dynamic> decodeExport({
    required CharacterCardFormat format,
    bool includeXinyuExtension = true,
  }) =>
      jsonDecode(
            exporter.exportJsonString(
              format: format,
              character: character,
              lore: lore,
              includeXinyuExtension: includeXinyuExtension,
            ),
          )
          as Map<String, dynamic>;

  test('V2 JSON：标准字段、扩展、世界书与根字段', () {
    final json = decodeExport(format: CharacterCardFormat.v2Json);
    expect(json['spec'], 'chara_card_v2');
    expect(json['spec_version'], '2.0');
    expect(json['x_root'], 'keep');

    final data = json['data'] as Map<String, dynamic>;
    expect(data['name'], '阿雪');
    expect(data['first_mes'], contains('你来干什么'));
    expect(data['alternate_greetings'], ['雨天', '放学后']);
    expect(data['creator'], '作者');
    expect(data['tags'], ['校园']);
    expect(data['system_prompt'], '保持冷淡');
    expect(data['post_history_instructions'], '不要总结');
    expect(data['nickname'], isNull); // V2 不写 nickname
    expect(data['group_only_greetings'], ['群聊']);

    final extensions = data['extensions'] as Map<String, dynamic>;
    expect(extensions['depth_prompt'], {'depth': 4});
    expect(extensions['xinyu'], isNotNull);

    final book = data['character_book'] as Map<String, dynamic>;
    expect(book['name'], '世界观');
    expect(book['scan_depth'], 3);
    final entry = (book['entries'] as List).single as Map<String, dynamic>;
    expect(entry['keys'], ['天台']);
    expect(entry['secondary_keys'], ['夜']);
    expect(entry['extensions'], {'x': 1});
    expect(entry['position'], 'after_char');
    expect(entry['insertion_order'], 5);
    expect(entry['depth'], 2);
    expect(entry['enabled'], isFalse);
  });

  test('V3 JSON 写 nickname 且 spec 正确', () {
    final json = decodeExport(format: CharacterCardFormat.v3Json);
    expect(json['spec'], 'chara_card_v3');
    expect(json['spec_version'], '3.0');
    expect((json['data'] as Map)['nickname'], '小雪');
  });

  test('关闭心语扩展：不写 xinyu，并提示档案丢失', () {
    final json = decodeExport(
      format: CharacterCardFormat.v3Json,
      includeXinyuExtension: false,
    );
    final data = json['data'] as Map<String, dynamic>;
    expect((data['extensions'] as Map)['xinyu'], isNull);

    final warnings = exporter.lossWarnings(
      character: character,
      includeXinyuExtension: false,
    );
    expect(warnings.any((w) => w.contains('扩展档案')), isTrue);
    expect(
      exporter
          .lossWarnings(character: character, includeXinyuExtension: true)
          .any((w) => w.contains('扩展档案')),
      isFalse,
    );
  });

  test('导出 V3 再导入：档案/世界书/书籍元数据不丢', () {
    final json = exporter.exportJsonString(
      format: CharacterCardFormat.v3Json,
      character: character,
      lore: lore,
    );
    final draft = const SillyTavernImporter().parse(
      Uint8List.fromList(utf8.encode(json)),
    );

    expect(draft.format, 'v3');
    expect(draft.name, '阿雪');
    expect(draft.profile.appearance.hair, '银白长发');
    expect(draft.profile.background.origin, '北境');
    expect(draft.profile.basic.nickname, '小雪');
    expect(draft.profile.creator.author, '作者');
    expect(draft.profile.runConfig.systemPrompt, '保持冷淡');
    expect(draft.loreDrafts, hasLength(1));
    expect(draft.loreDrafts.single.position, 'after');
    expect(draft.loreDrafts.single.sourceJson, contains('secondary_keys'));
    expect(draft.extensions.bookMeta['name'], '世界观');
    expect(draft.extensions.unknownData['group_only_greetings'], ['群聊']);
    expect(draft.extensions.stExtensions['depth_prompt'], {'depth': 4});
    // depth_prompt + assets + group_only_greetings + x_root；xinyu 不计入。
    expect(draft.preservedKeyCount, 4);
  });

  test('PNG 导出可被导入器解析，且保留立绘', () {
    final avatar = Uint8List.fromList(
      img.encodePng(img.Image(width: 2, height: 2)),
    );
    final export = exporter.exportPng(
      character: character,
      lore: lore,
      avatarBytes: avatar,
    );
    expect(export.fileName, '阿雪.png');
    expect(isPngBytes(export.bytes), isTrue);

    final draft = const SillyTavernImporter().parse(export.bytes);
    expect(draft.name, '阿雪');
    expect(draft.format, 'v3');
    expect(draft.profile.appearance.hair, '银白长发');
    expect(draft.pngBytes, export.bytes);
  });

  test('非 PNG 立绘自动转 PNG', () {
    final jpg = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 2, height: 2)),
    );
    final png = ensurePngBytes(jpg);
    expect(isPngBytes(png), isTrue);
  });

  test('文件名清洗', () {
    final export = exporter.exportV2(
      character: character.copyWith(name: ' 阿/雪:*? '),
      lore: const [],
    );
    expect(export.fileName, '阿_雪_v2.json');
  });
}
