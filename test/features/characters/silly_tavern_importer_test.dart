import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/core/errors/app_exception.dart';
import 'package:ai_roleplay_chat/features/characters/data/silly_tavern_importer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const importer = SillyTavernImporter();

  final sample = {
    'name': '林小雨',
    'description': '银发红瞳的少女，喜欢淋雨。',
    'personality': '冷淡、毒舌，但内心善良。',
    'scenario': '放学后的旧教学楼天台。',
    'first_mes': '*靠在栏杆上*……你来干什么？',
    'mes_example': '{{user}}：你好\n{{char}}：哼，谁要跟你打招呼。',
  };

  group('SillyTavernImporter', () {
    test('扁平 JSON 字段全部映射', () {
      final draft =
          importer.parse(Uint8List.fromList(utf8.encode(jsonEncode(sample))));
      expect(draft.name, '林小雨');
      expect(draft.description, contains('银发'));
      expect(draft.personality, contains('毒舌'));
      expect(draft.scenario, contains('天台'));
      expect(draft.firstMessage, contains('栏杆'));
      expect(draft.exampleDialogue, contains('{{user}}'));
      expect(draft.pngBytes, isNull);
      expect(draft.format, 'v1');
    });

    test('V2 alternate_greetings 解析为字符串列表', () {
      final card = {
        ...sample,
        'alternate_greetings': ['第一次见面。', '雨天的天台。', 123, ''],
      };
      final draft =
          importer.parse(Uint8List.fromList(utf8.encode(jsonEncode(card))));
      expect(draft.alternateGreetings, ['第一次见面。', '雨天的天台。']);
    });

    test('character_book 世界书解析为草稿（未启用）', () {
      final card = {
        ...sample,
        'character_book': {
          'entries': [
            {
              'keys': ['天台', '屋顶'],
              'content': '天台上的风很大。',
              'position': 0,
              'depth': 2,
              'insertion_order': 5,
            },
            {
              'key': ['教室'],
              'content': '教室里很安静。',
              'position': 1,
              'insertion_order': 1,
            },
            {'keys': <String>[], 'content': '没有关键词，应跳过'},
            {'keys': ['空内容'], 'content': ''},
          ],
        },
      };
      final draft =
          importer.parse(Uint8List.fromList(utf8.encode(jsonEncode(card))));
      expect(draft.loreDrafts, hasLength(2));
      expect(draft.loreDrafts.first.keys, ['天台', '屋顶']);
      expect(draft.loreDrafts.first.content, '天台上的风很大。');
      expect(draft.loreDrafts.first.position, 'before');
      expect(draft.loreDrafts.first.depth, 2);
      expect(draft.loreDrafts.first.priority, 5);
      expect(draft.loreDrafts[1].position, 'after');
    });

    test('V2 包装：正文在 data 下', () {
      final card = {
        'spec': 'chara_card_v2',
        'spec_version': '2.0',
        'data': sample,
      };
      final draft =
          importer.parse(Uint8List.fromList(utf8.encode(jsonEncode(card))));
      expect(draft.name, '林小雨');
      expect(draft.firstMessage, contains('栏杆'));
      expect(draft.format, 'v2');
    });

    test('V2 完整字段映射到档案与扩展，未知字段保留', () {
      final card = {
        'spec': 'chara_card_v2',
        'spec_version': '2.0',
        'data': {
          ...sample,
          'nickname': '小雨',
          'creator': '测试作者',
          'character_version': '1.2',
          'creator_notes': '测试备注',
          'tags': ['校园', '傲娇'],
          'system_prompt': '保持冷淡',
          'post_history_instructions': '不要总结',
          'extensions': {
            'depth_prompt': {'depth': 4},
          },
          'group_only_greetings': ['群聊开场'],
          'future_field': {'x': 1},
        },
      };
      final draft =
          importer.parse(Uint8List.fromList(utf8.encode(jsonEncode(card))));

      expect(draft.format, 'v2');
      expect(draft.profile.basic.nickname, '小雨');
      expect(draft.profile.creator.author, '测试作者');
      expect(draft.profile.creator.version, '1.2');
      expect(draft.profile.creator.notes, '测试备注');
      expect(draft.profile.creator.tags, ['校园', '傲娇']);
      expect(draft.profile.runConfig.systemPrompt, '保持冷淡');
      expect(draft.profile.runConfig.postHistoryInstructions, '不要总结');
      expect(draft.extensions.stExtensions['depth_prompt'], {'depth': 4});
      // assets/group_only_greetings 等未映射字段原样保留。
      expect(draft.extensions.unknownData['group_only_greetings'], ['群聊开场']);
      expect(draft.extensions.unknownData['future_field'], {'x': 1});
      expect(draft.preservedKeyCount, 3);
      expect(
        draft.warnings,
        contains('角色卡自带的系统提示 / 历史后置指令已保存'),
      );
    });

    test('V3 识别 + 未识别根字段保留', () {
      final card = {
        'spec': 'chara_card_v3',
        'spec_version': '3.0',
        'data': {
          ...sample,
          'assets': [
            {'type': 'icon', 'uri': 'ccdefault:'},
          ],
        },
        'x_root': 'keep',
      };
      final draft =
          importer.parse(Uint8List.fromList(utf8.encode(jsonEncode(card))));
      expect(draft.format, 'v3');
      expect(draft.extensions.unknownData['assets'], [
        {'type': 'icon', 'uri': 'ccdefault:'},
      ]);
      expect(draft.extensions.unknownRoot['x_root'], 'keep');
    });

    test('世界书书籍元数据与条目原文保留', () {
      final card = {
        ...sample,
        'character_book': {
          'name': '世界观',
          'scan_depth': 3,
          'entries': [
            {
              'keys': ['天台'],
              'secondary_keys': ['夜'],
              'content': '天台的风很大。',
              'position': 'after_char',
              'insertion_order': 5,
              'extensions': {'x': 1},
            },
          ],
        },
      };
      final draft =
          importer.parse(Uint8List.fromList(utf8.encode(jsonEncode(card))));
      expect(draft.extensions.bookMeta['name'], '世界观');
      expect(draft.extensions.bookMeta['scan_depth'], 3);
      expect(draft.loreDrafts.single.position, 'after');
      expect(draft.loreDrafts.single.priority, 5);

      final source =
          jsonDecode(draft.loreDrafts.single.sourceJson) as Map<String, dynamic>;
      expect(source['secondary_keys'], ['夜']);
      expect(source['extensions'], {'x': 1});
      expect(draft.warnings, contains('世界书 1 条待导入，默认禁用'));
    });

    test('extensions.xinyu.profile 回读扩展档案，ST 字段覆盖非空值', () {
      final card = {
        'spec': 'chara_card_v3',
        'data': {
          'name': '阿雪',
          'nickname': '新昵称',
          'extensions': {
            'xinyu': {
              'profile': {
                'basic': {'nickname': '旧昵称'},
                'appearance': {'hair': '银白长发'},
                'background': {'origin': '北境'},
                'creator': {'author': '旧作者'},
              },
            },
          },
        },
      };
      final draft =
          importer.parse(Uint8List.fromList(utf8.encode(jsonEncode(card))));
      expect(draft.profile.basic.nickname, '新昵称');
      expect(draft.profile.creator.author, '旧作者');
      expect(draft.profile.appearance.hair, '银白长发');
      expect(draft.profile.background.origin, '北境');
      expect(draft.preservedKeyCount, 0); // xinyu 是本应用扩展，不计入
    });

    test('tags 支持逗号分隔字符串', () {
      final draft = importer.parse(
        Uint8List.fromList(
          utf8.encode(
            jsonEncode({'name': '小雨', 'tags': '校园, 傲娇，日常'}),
          ),
        ),
      );
      expect(draft.profile.creator.tags, ['校园', '傲娇', '日常']);
    });

    test('未知 spec 按包装结构解析并给出提示', () {
      final card = {
        'spec': 'chara_card_v9',
        'data': sample,
      };
      final draft =
          importer.parse(Uint8List.fromList(utf8.encode(jsonEncode(card))));
      expect(draft.format, 'v2');
      expect(draft.warnings.first, contains('未知 spec'));
    });

    test('PNG 卡：提取 tEXt chara 并保留整图作立绘', () {
      final b64 = base64Encode(utf8.encode(jsonEncode(sample)));
      final png = _buildPng({'chara': b64, 'other': 'ignore me'});
      final draft = importer.parse(png);
      expect(draft.name, '林小雨');
      expect(draft.pngBytes, isNotNull);
      expect(draft.pngBytes, png);
    });

    test('PNG 无 chara 块报 Parse 错', () {
      final png = _buildPng({'other': 'x'});
      expect(() => importer.parse(png), throwsA(isA<ParseException>()));
    });

    test('非法 JSON 报 Parse 错', () {
      expect(() => importer.parse(Uint8List.fromList(utf8.encode('{oops'))),
          throwsA(isA<ParseException>()));
    });

    test('JSON 顶层非对象报 Parse 错', () {
      expect(() => importer.parse(Uint8List.fromList(utf8.encode('[1,2]'))),
          throwsA(isA<ParseException>()));
    });

    test('缺 name 字段兜底为未命名角色', () {
      final draft = importer.parse(Uint8List.fromList(
          utf8.encode(jsonEncode({'description': '只有描述'}))));
      expect(draft.name, '未命名角色');
    });

    test('字段两端空白被裁剪', () {
      final draft = importer.parse(Uint8List.fromList(
          utf8.encode(jsonEncode({'name': '  小雨  '}))));
      expect(draft.name, '小雨');
    });

    test('仅含 ccv3 块的 PNG 也能导入', () {
      final b64 = base64Encode(utf8.encode(jsonEncode(sample)));
      final png = _buildPng({'ccv3': b64});
      final draft = importer.parse(png);
      expect(draft.name, '林小雨');
      expect(draft.format, 'v3');
    });

    test('chara 损坏时回退 ccv3', () {
      final ccv3 = base64Encode(utf8.encode(jsonEncode(sample)));
      final png = _buildPng({'chara': '!!!not-base64!!!', 'ccv3': ccv3});
      final draft = importer.parse(png);
      expect(draft.name, '林小雨');
    });

    test('first_mes 为数组、别名键、数字 name 等非标形态容错', () {
      final draft = importer.parse(Uint8List.fromList(utf8.encode(jsonEncode({
        'name': 1024,
        'first_message': ['第一句', '第二句'],
        'example_dialogue': ['u: hi', 'c: 哼'],
      }))));
      expect(draft.name, '1024');
      expect(draft.firstMessage, '第一句\n第二句');
      expect(draft.exampleDialogue, 'u: hi\nc: 哼');
    });

    test('PNG 内嵌 JSON 带 UTF-8 BOM 仍可解析', () {
      final b64 =
          base64Encode(utf8.encode('﻿${jsonEncode(sample)}'));
      final png = _buildPng({'chara': b64});
      final draft = importer.parse(png);
      expect(draft.name, '林小雨');
    });
  });
}

/// 构造含指定 tEXt 块的最小合法 PNG（CRC 按规范计算）。
Uint8List _buildPng(Map<String, String> textChunks) {
  final out = BytesBuilder();
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  // 1x1 RGB 假 IHDR（解析器不校验图像内容）。
  out.add(_chunk('IHDR', const [0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0]));
  textChunks.forEach((k, v) {
    out.add(_chunk('tEXt', [...ascii.encode(k), 0, ...latin1.encode(v)]));
  });
  out.add(_chunk('IEND', const []));
  return out.toBytes();
}

Uint8List _chunk(String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  final body = <int>[
    (data.length >> 24) & 0xFF,
    (data.length >> 16) & 0xFF,
    (data.length >> 8) & 0xFF,
    data.length & 0xFF,
    ...typeBytes,
    ...data,
  ];
  final crc = _crc32([...typeBytes, ...data]);
  return Uint8List.fromList([
    ...body,
    (crc >> 24) & 0xFF,
    (crc >> 16) & 0xFF,
    (crc >> 8) & 0xFF,
    crc & 0xFF,
  ]);
}

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
