import 'package:ai_roleplay_chat/core/errors/app_exception.dart';
import 'package:ai_roleplay_chat/features/voice/data/mimo_asr_provider.dart';
import 'package:ai_roleplay_chat/features/voice/data/resolving_asr_provider.dart';
import 'package:ai_roleplay_chat/features/voice/data/speech_to_text_asr_provider.dart';
import 'package:ai_roleplay_chat/features/voice/domain/asr_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可控的假引擎：implements + noSuchMethod，不触碰平台通道/网络。
class _FakeMimo implements MimoAsrProvider {
  bool started = false;
  AsrCallbacks? held;
  bool canUseResult = true;

  /// start 中以 onError 上报的错误（模拟录音启动失败）。
  AppException? startError;

  /// start 直接抛异常。
  bool throwOnStart = false;

  /// stop 中以 onError 上报的错误（模拟转写失败）。
  AppException? stopError;

  /// 非空时 stop 回调该最终结果（模拟转写成功）。
  String? finalOnStop;

  @override
  Future<bool> canUse() async => canUseResult;

  @override
  Future<void> start(AsrCallbacks callbacks) async {
    started = true;
    held = callbacks;
    if (throwOnStart) throw startError ?? const UnknownException('启动失败');
    final e = startError;
    if (e != null) callbacks.onError(e);
  }

  @override
  Future<void> stop() async {
    final t = finalOnStop;
    if (t != null) held?.onFinal(t);
    final e = stopError;
    if (e != null) held?.onError(e);
  }

  @override
  Future<void> cancel() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeSystem implements SpeechToTextAsrProvider {
  bool started = false;
  AsrCallbacks? held;
  AppException? startError;
  AppException? stopError;

  @override
  Future<void> start(AsrCallbacks callbacks) async {
    started = true;
    held = callbacks;
    final e = startError;
    if (e != null) callbacks.onError(e);
  }

  @override
  Future<void> stop() async {
    final e = stopError;
    if (e != null) held?.onError(e);
  }

  @override
  Future<void> cancel() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  late _FakeMimo mimo;
  late _FakeSystem system;
  late List<String> partials;
  late List<String> finals;
  late List<AppException> errors;
  late AsrCallbacks cbs;

  ResolvingAsrProvider makeResolver({String engine = 'mimo'}) =>
      ResolvingAsrProvider(
        engineGet: () async => engine,
        mimo: mimo,
        system: system,
      );

  setUp(() {
    mimo = _FakeMimo();
    system = _FakeSystem();
    partials = [];
    finals = [];
    errors = [];
    cbs = AsrCallbacks(
      onPartial: partials.add,
      onFinal: finals.add,
      onError: errors.add,
    );
  });

  test('start 阶段主引擎初始化失败（onError）：吞错误并回退备引擎', () async {
    mimo.startError = const AuthException('识别鉴权失败：bad key');
    await makeResolver().start(cbs);
    expect(mimo.started, isTrue);
    expect(system.started, isTrue); // 回退发生了
    expect(errors, isEmpty); // 初始化错误被吞
  });

  test('start 阶段主引擎抛异常：同样回退备引擎', () async {
    mimo
      ..throwOnStart = true
      ..startError = const UnknownException('录音不可用');
    await makeResolver().start(cbs);
    expect(system.started, isTrue);
    expect(errors, isEmpty);
  });

  test('stop 期间主引擎报错：直接上报真实错误，不得再开备引擎（僵尸会话回归）',
      () async {
    final r = makeResolver();
    await r.start(cbs);
    expect(system.started, isFalse);

    mimo.stopError = const ServerException('识别请求失败：audio too short', null, 400);
    await r.stop();

    expect(system.started, isFalse,
        reason: '松手/stop 之后不得再启动备引擎（僵尸识别会话）');
    expect(errors, hasLength(1), reason: '真实错误必须可见，不得被吞');
    expect(errors.single.message, contains('识别请求失败'));
  });

  test('start 完成后识别中途报错：直接上报，不回退', () async {
    final r = makeResolver();
    await r.start(cbs);
    mimo.held!.onError(const NetworkException('识别中途失败'));
    expect(system.started, isFalse);
    expect(errors.map((e) => e.message), ['识别中途失败']);
  });

  test('system 主引擎在 stop 期间报错：不得启动 mimo 录音', () async {
    final r = makeResolver(engine: 'system');
    await r.start(cbs);
    expect(mimo.started, isFalse);

    system.stopError = const UnknownException('识别失败：x');
    await r.stop();

    expect(mimo.started, isFalse, reason: '不得在松手后开启云端录音');
    expect(errors, hasLength(1));
  });

  test('成功路径：stop 期间 onFinal 照常透传（chat_input_bar 无需改动的前提）',
      () async {
    final r = makeResolver();
    await r.start(cbs);
    mimo.finalOnStop = '你好';
    await r.stop();
    expect(finals, ['你好']);
    expect(system.started, isFalse);
    expect(errors, isEmpty);
  });

  test('stop 之后迟到的 onError 不触发回退', () async {
    final r = makeResolver();
    await r.start(cbs);
    await r.stop();
    mimo.held?.onError(const AuthException('迟到的鉴权错误'));
    expect(system.started, isFalse);
    expect(errors, hasLength(1));
  });
}
