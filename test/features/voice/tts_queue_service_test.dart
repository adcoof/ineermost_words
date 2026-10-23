import 'dart:async';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/core/errors/app_exception.dart';
import 'package:dio/dio.dart';
import 'package:ai_roleplay_chat/features/voice/application/tts_queue_service.dart';
import 'package:ai_roleplay_chat/features/voice/domain/tts_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTtsProvider implements TtsProvider {
  final List<String> synthesized = [];
  final bool failFor;

  /// true 时抛非 AppException 的底层异常（模拟 edge_tts WS/socket 错误）。
  final bool rawFail;

  _FakeTtsProvider({this.failFor = false, this.rawFail = false});

  @override
  String get providerId => 'fake';

  @override
  Future<TtsAudio> synthesize(TtsRequest req, {CancelToken? cancel}) async {
    if (failFor && req.text.contains('坏')) {
      if (rawFail) {
        throw Exception('底层 WebSocket 断开');
      }
      throw const NetworkException('合成失败');
    }
    synthesized.add(req.text);
    return TtsAudio(mimeType: 'mp3', bytes: Uint8List.fromList([1, 2, 3]));
  }

  @override
  Future<List<TtsVoice>> listVoices() async => const [];
}

/// 手动控制完成时机的假合成器：每次 synthesize 记录请求并挂起，
/// 由测试决定何时解决——用于证明预合成与播放的重叠时序。
class _ManualProvider implements TtsProvider {
  final List<({TtsRequest req, Completer<TtsAudio> completer})> calls = [];

  @override
  String get providerId => 'manual';

  @override
  Future<TtsAudio> synthesize(TtsRequest req, {CancelToken? cancel}) {
    final completer = Completer<TtsAudio>();
    calls.add((req: req, completer: completer));
    return completer.future;
  }

  @override
  Future<List<TtsVoice>> listVoices() async => const [];
}

class _FakePlayer implements AudioPlayerBackend {
  final List<String> played = [];
  Completer<void>? current;

  @override
  Future<void> playAudio(Uint8List bytes, String mimeType) async {
    played.add(mimeType);
    current = Completer<void>();
    await current!.future;
  }

  @override
  Future<void> stop() async {
    final c = current;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  void dispose() {}
}

void main() {
  test('顺序合成播放，失败句跳过不中断', () async {
    final provider = _FakeTtsProvider(failFor: true);
    final player = _FakePlayer();
    final queue = TtsQueueService(provider: provider, player: player);

    queue.enqueue('第一句。');
    queue.enqueue('坏句子。');
    queue.enqueue('第三句。');
    await pumpEventQueue();
    // 第一句在播（阻塞中），释放它让队列继续。
    player.current!.complete();
    await pumpEventQueue();
    player.current!.complete();
    await pumpEventQueue(times: 3);

    expect(provider.synthesized, ['第一句。', '第三句。']); // 坏句被跳过
    expect(player.played.length, 2);
    await queue.dispose();
  });

  test('clear 打断：清队列并停止当前播放', () async {
    final provider = _FakeTtsProvider();
    final player = _FakePlayer();
    final queue = TtsQueueService(provider: provider, player: player);

    queue.enqueue('第一句。');
    queue.enqueue('第二句。');
    await pumpEventQueue();
    expect(queue.isBusy, isTrue);

    queue.clear();
    await pumpEventQueue(times: 3);

    expect(queue.isBusy, isFalse);
    // 流水线语义：第二句可能已被预合成（流水线的预取代价），
    // 但 clear 后绝不能播放——只有第一句发起过 playAudio。
    expect(player.played.length, 1);
    await queue.dispose();
  });

  test('流水线预合成：播第一句时第二句已在合成，播完即接续', () async {
    final provider = _ManualProvider();
    final player = _FakePlayer();
    final queue = TtsQueueService(provider: provider, player: player);

    queue.enqueue('第一句。');
    queue.enqueue('第二句。');
    await pumpEventQueue();
    // 首句合成已发出并解决 → 播放开始。
    expect(provider.calls.length, 1);
    provider.calls[0].completer
        .complete(TtsAudio(mimeType: 'mp3', bytes: Uint8List.fromList([1])));
    await pumpEventQueue();
    expect(player.played.length, 1); // 第一句在播（阻塞中）

    // 关键断言：第一句还在播，第二句的合成请求已经发出（重叠）。
    expect(provider.calls.length, 2);
    expect(provider.calls[1].req.text, '第二句。');

    // 第二句合成解决；第一句播完 → 第二句立即接上播放，无需再等合成。
    provider.calls[1].completer
        .complete(TtsAudio(mimeType: 'mp3', bytes: Uint8List.fromList([2])));
    await pumpEventQueue();
    player.current!.complete(); // 第一句播完
    await pumpEventQueue(times: 3);
    expect(player.played.length, 2); // 第二句已接上播放
    player.current!.complete(); // 第二句播完
    await pumpEventQueue(times: 3);

    expect(queue.isBusy, isFalse);
    await queue.dispose();
  });

  test('非 AppException 底层异常也跳过不卡队列，errors 有上报', () async {
    final provider = _FakeTtsProvider(failFor: true, rawFail: true);
    final player = _FakePlayer();
    final queue = TtsQueueService(provider: provider, player: player);
    final errors = <String>[];
    final sub = queue.errors.listen(errors.add);

    queue.enqueue('第一句。');
    queue.enqueue('坏句子。'); // 抛裸 Exception
    queue.enqueue('第三句。');
    await pumpEventQueue();
    player.current!.complete();
    await pumpEventQueue();
    player.current!.complete();
    await pumpEventQueue(times: 3);

    expect(provider.synthesized, ['第一句。', '第三句。']);
    expect(player.played.length, 2);
    expect(errors, isNotEmpty);
    expect(errors.first, contains('语音合成失败'));
    expect(queue.isBusy, isFalse); // 队列没有卡死
    await sub.cancel();
    await queue.dispose();
  });

  test('失败后队列恢复：下一批仍能正常合成播放', () async {
    final provider = _FakeTtsProvider(failFor: true);
    final player = _FakePlayer();
    final queue = TtsQueueService(provider: provider, player: player);

    queue.enqueue('坏句子。');
    await pumpEventQueue();
    expect(queue.isBusy, isFalse); // 句子被跳过后 drain 收尾

    queue.enqueue('恢复句。');
    await pumpEventQueue();
    player.current!.complete();
    await pumpEventQueue(times: 3);

    expect(provider.synthesized, ['恢复句。']);
    expect(player.played.length, 1);
    await queue.dispose();
  });

  test('clear 时预合成仍在飞：迟到结果不播也不卡状态', () async {
    final provider = _ManualProvider();
    final player = _FakePlayer();
    final queue = TtsQueueService(provider: provider, player: player);

    queue.enqueue('第一句。');
    queue.enqueue('第二句。');
    await pumpEventQueue();
    provider.calls[0].completer
        .complete(TtsAudio(mimeType: 'mp3', bytes: Uint8List.fromList([1])));
    await pumpEventQueue();
    // 第一句在播、第二句预合成仍在飞。
    expect(provider.calls.length, 2);
    expect(player.played.length, 1);

    queue.clear();
    await pumpEventQueue(times: 3);
    expect(player.played.length, 1);
    expect(queue.isBusy, isFalse);

    // 迟到的成功结果：被 generation 检查丢弃，绝不播放。
    provider.calls[1].completer
        .complete(TtsAudio(mimeType: 'mp3', bytes: Uint8List.fromList([2])));
    await pumpEventQueue(times: 3);
    expect(player.played.length, 1);
    expect(queue.isBusy, isFalse);
    await queue.dispose();
  });

  test('clear 时预合成在飞且报错：错误被吞，不进 zone 也不播', () async {
    final provider = _ManualProvider();
    final player = _FakePlayer();
    final queue = TtsQueueService(provider: provider, player: player);

    queue.enqueue('第一句。');
    queue.enqueue('第二句。');
    await pumpEventQueue();
    provider.calls[0].completer
        .complete(TtsAudio(mimeType: 'mp3', bytes: Uint8List.fromList([1])));
    await pumpEventQueue();
    queue.clear();
    await pumpEventQueue(times: 3);

    // 迟到的错误：lookahead 已无人 await，吞错句柄必须兜住
    //（flutter_test 里未处理异步错误会使本用例直接失败）。
    provider.calls[1].completer.completeError(const NetworkException('断网'));
    await pumpEventQueue(times: 3);
    expect(player.played.length, 1);
    expect(queue.isBusy, isFalse);
    await queue.dispose();
  });

  test('dispose 后 enqueue/clear 不抛错、不把队列闩成僵尸', () async {
    final provider = _FakeTtsProvider();
    final player = _FakePlayer();
    final queue = TtsQueueService(provider: provider, player: player);

    queue.enqueue('第一句。');
    await pumpEventQueue();
    await queue.dispose();

    // 评审钉住的既有缺陷：dispose 后残留 enqueue 曾因未守卫的
    // _busy.add 抛 StateError 且落在 try 外，_draining 永久闩死。
    expect(() => queue.enqueue('死后句。'), returnsNormally);
    expect(() => queue.clear(), returnsNormally);
    await pumpEventQueue(times: 3);
    expect(queue.isBusy, isFalse);
  });

  test('口型流：播放期有值，停播归零', () async {
    final provider = _FakeTtsProvider();
    final player = _FakePlayer();
    final queue = TtsQueueService(provider: provider, player: player);

    final lipValues = <double>[];
    final sub = queue.lipValues.listen(lipValues.add);

    queue.enqueue('测试口型。');
    await pumpEventQueue();
    // 等 80ms 的口型定时器至少跳一次。
    await Future<void>.delayed(const Duration(milliseconds: 250));
    queue.clear();
    await pumpEventQueue(times: 3);

    expect(lipValues.any((v) => v > 0), isTrue);
    expect(lipValues.last, 0);
    await sub.cancel();
    await queue.dispose();
  });
}
