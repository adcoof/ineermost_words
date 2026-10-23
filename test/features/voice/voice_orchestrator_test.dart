import 'dart:typed_data';

import 'package:ai_roleplay_chat/features/voice/application/tts_queue_service.dart';
import 'package:ai_roleplay_chat/features/voice/application/voice_orchestrator.dart';
import 'package:ai_roleplay_chat/features/voice/domain/tts_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录合成文本的假 TTS 提供商。
class _RecordingTtsProvider implements TtsProvider {
  final List<String> synthesized = [];

  @override
  String get providerId => 'fake';

  @override
  Future<TtsAudio> synthesize(TtsRequest req, {CancelToken? cancel}) async {
    synthesized.add(req.text);
    return TtsAudio(mimeType: 'mp3', bytes: Uint8List.fromList([1, 2, 3]));
  }

  @override
  Future<List<TtsVoice>> listVoices() async => const [];
}

/// 立即播放完成的假播放后端（本用例只关心合成文本）。
class _NoopPlayer implements AudioPlayerBackend {
  @override
  Future<void> playAudio(Uint8List bytes, String mimeType) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

void main() {
  group('stripTagMarkup 纯函数表驱动', () {
    const cases = <(String, String)>[
      // 必须匹配：裸标签 / 规范标签 / 自闭合 / 带属性标记。
      ('<shake_head>你好', '你好'),
      ('<emotion:happy>开心', '开心'),
      ('</emotion>收尾', '收尾'),
      ('换行<br/>继续', '换行继续'),
      ('<a href="x">链接</a>', '链接'),
      // 标签两侧文本无缝拼接。
      ('他说<shake_head>很好', '他说很好'),
      // 连续多标签。
      ('<shake_head><blush>嗯。', '嗯。'),
      ('<b>加粗</b><i>斜体</i>', '加粗斜体'),
      // 整串纯标签 → 空串。
      ('<shake_head>', ''),
      ('<emotion:angry></emotion>', ''),
      ('<br/>', ''),
      // 流截断的未闭合残段（无 '>'）同样剥掉，不让 TTS 读 'shake_head'。
      ('<shake_', ''),
      ('他说<shake_head', '他说'),
      ('尾部<a href=', '尾部'),
      // 绝不误伤：'<' 后非字母、或无闭合 '>' 的普通文本。
      ('a < b', 'a < b'),
      ('2<3>4', '2<3>4'),
      ('x<3', 'x<3'),
    ];
    for (final (input, expected) in cases) {
      test('"$input" → "$expected"', () {
        expect(VoiceOrchestrator.stripTagMarkup(input), expected);
      });
    }
  });

  group('VoiceOrchestrator 端到端剥标签', () {
    late _RecordingTtsProvider provider;
    late TtsQueueService queue;
    late VoiceOrchestrator orchestrator;

    setUp(() {
      provider = _RecordingTtsProvider();
      queue = TtsQueueService(provider: provider, player: _NoopPlayer());
      orchestrator = VoiceOrchestrator(
        queue: queue,
        enabledCheck: () async => true,
        speedGet: () async => 1.0,
        voiceGet: () async => '',
      );
    });

    tearDown(() async {
      await queue.dispose();
    });

    test('流式增量里的裸标签不进 TTS，句子剥后朗读', () async {
      await orchestrator
          .onAssistantDelta('<shake_head>你好呀。<emotion:angry>你走开。');
      await pumpEventQueue(times: 3);

      expect(provider.synthesized, ['你好呀。', '你走开。']);
      expect(provider.synthesized.any((t) => t.contains('<')), isFalse);
    });

    test('收尾 flush 的尾句同样剥标签', () async {
      await orchestrator.onAssistantDelta('<blush>晚安');
      await pumpEventQueue(times: 3);
      expect(provider.synthesized, isEmpty); // 无句读，尾段未吐

      await orchestrator.onAssistantDone();
      await pumpEventQueue(times: 3);
      expect(provider.synthesized, ['晚安']);
    });

    test('尾段剥后为空则整句忽略，不进 TTS', () async {
      await orchestrator.onAssistantDelta('你好。<shake_head>');
      await pumpEventQueue(times: 3);
      expect(provider.synthesized, ['你好。']);

      await orchestrator.onAssistantDone();
      await pumpEventQueue(times: 3);
      expect(provider.synthesized, ['你好。']); // 尾段纯标签被吞掉
    });

    test('标签被 SSE chunk 切断成半截时句子级拼回后仍剥净', () async {
      // 钉住 strip 的施加位置：若挪到增量输入端做无状态 strip，
      // 半截标签会漏剥，下面会朗读出 '<shake_head>你好。'。
      await orchestrator.onAssistantDelta('<shake_');
      await orchestrator.onAssistantDelta('head>你好。');
      await pumpEventQueue(times: 3);
      expect(provider.synthesized, ['你好。']);
    });

    test('流在标签中截断的尾段不进 TTS（未闭合残段同样剥掉）', () async {
      await orchestrator.onAssistantDelta('你好呀。<shake_');
      await pumpEventQueue(times: 3);
      expect(provider.synthesized, ['你好呀。']);

      await orchestrator.onAssistantDone();
      await pumpEventQueue(times: 3);
      expect(provider.synthesized, ['你好呀。']); // 尾段 '<shake_' 剥成空，不朗读
    });

    test('带换行的属性标记被句切分劈开时两半都不进 TTS', () async {
      // '<a\nhref="x">' 被 SentenceSplitter 的换行终止符劈成两半：
      // 前半 '<a' 无 '>'，后半 'href="x">' 无 '<'，都不得朗读。
      await orchestrator.onAssistantDelta('<a\nhref="x">链接</a>哦。');
      await pumpEventQueue(times: 3);
      expect(provider.synthesized, ['链接哦。']);
    });

    test('剥后仅剩句读的残句丢弃，不进 TTS', () async {
      await orchestrator.onAssistantDelta('<shake_head>。');
      await pumpEventQueue(times: 3);
      expect(provider.synthesized, isEmpty); // 残句 '。' 不值得合成

      await orchestrator.onAssistantDone();
      await pumpEventQueue(times: 3);
      expect(provider.synthesized, isEmpty);
    });
  });
}
