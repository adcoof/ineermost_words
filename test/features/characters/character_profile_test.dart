import 'dart:convert';

import 'package:ai_roleplay_chat/features/characters/domain/character_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CharacterProfile 编解码', () {
    test('空档案编码为 {}，解码为空，提示词为空', () {
      const profile = CharacterProfile.empty;
      expect(profile.isEmpty, isTrue);
      expect(profile.encode(), '{}');
      expect(profile.promptText, '');
      expect(CharacterProfile.decode('{}').isEmpty, isTrue);
      expect(CharacterProfile.decode('').isEmpty, isTrue);
    });

    test('完整档案 JSON 往返', () {
      const profile = CharacterProfile(
        basic: BasicProfile(
          nickname: '阿雪',
          age: '17',
          gender: '女',
          race: '人类',
          identity: '学生',
        ),
        appearance: AppearanceProfile(
          summary: '银白长发',
          hair: '及腰直发',
          eyes: '红瞳',
          outfit: '黑色校服',
          height: '165cm',
          body: '纤细',
          features: '左耳有耳钉',
        ),
        background: BackgroundProfile(
          origin: '北境',
          experiences: '独自来到城市',
          keyEvents: '三年前的火灾',
          secrets: '害怕火焰',
          goals: '找到家人',
        ),
        relationships: RelationshipProfile(
          userRelation: '同桌',
          initialCloseness: '点头之交',
          direction: '逐渐信任',
          others: '与班长不和',
        ),
        language: LanguageProfile(
          tone: '冷淡',
          habits: '句子很短',
          verbalTics: '哼',
          commonPhrases: '随便你',
          taboos: '不提家人',
        ),
        interaction: InteractionProfile(
          replyLength: '1-2 句',
          initiative: '被动',
          emotionExpression: '克制',
          behaviorTendency: '嘴硬心软',
        ),
        creator: CreatorProfile(
          author: '测试作者',
          version: '1.2',
          tags: ['校园', '傲娇'],
          notes: '测试备注',
          copyright: 'CC-BY',
        ),
        runConfig: RunConfigProfile(
          systemPrompt: '保持冷淡',
          postHistoryInstructions: '不要总结',
        ),
      );

      final decoded = CharacterProfile.decode(profile.encode());
      expect(decoded.basic.nickname, '阿雪');
      expect(decoded.basic.identity, '学生');
      expect(decoded.appearance.hair, '及腰直发');
      expect(decoded.appearance.features, '左耳有耳钉');
      expect(decoded.background.secrets, '害怕火焰');
      expect(decoded.relationships.userRelation, '同桌');
      expect(decoded.language.verbalTics, '哼');
      expect(decoded.interaction.behaviorTendency, '嘴硬心软');
      expect(decoded.creator.author, '测试作者');
      expect(decoded.creator.tags, ['校园', '傲娇']);
      expect(decoded.runConfig.systemPrompt, '保持冷淡');
      expect(decoded.runConfig.postHistoryInstructions, '不要总结');
      expect(decoded.isEmpty, isFalse);
    });

    test('未知顶层键保留，重新编码不丢', () {
      final raw = jsonEncode({
        'v': 1,
        'basic': {'nickname': '阿雪'},
        'futureSection': {'foo': 'bar'},
      });
      final profile = CharacterProfile.decode(raw);
      expect(profile.basic.nickname, '阿雪');
      final encoded = profile.toJson();
      expect(encoded['futureSection'], {'foo': 'bar'});
      expect(profile.extra['futureSection'], {'foo': 'bar'});
    });

    test('坏 JSON / 非对象 / 字段类型不符按空值容错', () {
      expect(CharacterProfile.decode('not json').isEmpty, isTrue);
      expect(CharacterProfile.decode('[]').isEmpty, isTrue);

      final profile = CharacterProfile.decode(
        jsonEncode({
          'basic': 'not a map',
          'appearance': {'hair': 123, 'eyes': null},
          'creator': {'tags': ['  ', '校园', 3]},
        }),
      );
      expect(profile.basic.isEmpty, isTrue);
      expect(profile.appearance.hair, '123');
      expect(profile.appearance.eyes, '');
      expect(profile.creator.tags, ['校园']);
    });

    test('提示词只包含运行分区，按固定顺序拼接', () {
      const profile = CharacterProfile(
        basic: BasicProfile(nickname: '阿雪', age: '17'),
        appearance: AppearanceProfile(hair: '银白长发', eyes: '红瞳'),
        background: BackgroundProfile(origin: '北境'),
        relationships: RelationshipProfile(userRelation: '同桌'),
        language: LanguageProfile(tone: '冷淡'),
        interaction: InteractionProfile(replyLength: '1-2 句'),
        creator: CreatorProfile(author: '作者', notes: '不该出现'),
        runConfig: RunConfigProfile(
          systemPrompt: '不该出现在档案块',
          postHistoryInstructions: '也不该',
        ),
      );

      expect(
        profile.promptText,
        '身份：昵称 阿雪；年龄 17\n'
        '外貌：发型 银白长发；瞳色 红瞳\n'
        '背景：出身 北境\n'
        '与用户的关系：关系 同桌\n'
        '语言风格：语气 冷淡\n'
        '互动方式：回复长度 1-2 句',
      );
      expect(profile.promptText, isNot(contains('不该出现')));
      expect(profile.promptText, isNot(contains('也不该')));
    });

    test('空白字段不进入提示词', () {
      const profile = CharacterProfile(
        basic: BasicProfile(nickname: '   ', age: '17'),
        appearance: AppearanceProfile(summary: ''),
      );
      expect(profile.promptText, '身份：年龄 17');
    });
  });
}
