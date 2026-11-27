import 'dart:convert';

import 'package:ai_roleplay_chat/features/characters/domain/character_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CharacterExtensions 编解码', () {
    test('空扩展编码为 {}，解码为空', () {
      const ext = CharacterExtensions.empty;
      expect(ext.isEmpty, isTrue);
      expect(ext.encode(), '{}');
      expect(ext.preservedKeyCount, 0);
      expect(CharacterExtensions.decode('').isEmpty, isTrue);
      expect(CharacterExtensions.decode('{}').isEmpty, isTrue);
    });

    test('第三方扩展与未识别字段完整往返', () {
      const ext = CharacterExtensions(
        stExtensions: {
          'depth_prompt': {'depth': 4},
        },
        unknownData: {'nickname': '小雪', 'assets': []},
        unknownRoot: {'extra_root': true},
        bookMeta: {'name': '世界观', 'scan_depth': 3},
      );
      expect(ext.preservedKeyCount, 4);

      final decoded = CharacterExtensions.decode(ext.encode());
      expect(decoded.stExtensions['depth_prompt'], {'depth': 4});
      expect(decoded.unknownData['nickname'], '小雪');
      expect(decoded.unknownRoot['extra_root'], isTrue);
      expect(decoded.bookMeta['name'], '世界观');
      expect(decoded.bookMeta['scan_depth'], 3);
    });

    test('本格式未来顶层键保留', () {
      final raw = jsonEncode({
        'v': 1,
        'st_extensions': {'a': 1},
        'future': {'x': 'y'},
      });
      final ext = CharacterExtensions.decode(raw);
      expect(ext.stExtensions['a'], 1);
      expect(ext.extra['future'], {'x': 'y'});
      expect(ext.toJson()['future'], {'x': 'y'});
    });

    test('坏 JSON / 非对象 / 字段类型不符容错', () {
      expect(CharacterExtensions.decode('not json').isEmpty, isTrue);
      expect(CharacterExtensions.decode('[]').isEmpty, isTrue);

      final ext = CharacterExtensions.decode(
        jsonEncode({
          'st_extensions': 'bad',
          'unknown_data': ['bad'],
          'unknown_root': {'ok': 1},
        }),
      );
      expect(ext.stExtensions, isEmpty);
      expect(ext.unknownData, isEmpty);
      expect(ext.unknownRoot, {'ok': 1});
    });
  });
}
