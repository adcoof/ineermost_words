/// ASR 实现：speech_to_text（Android SpeechRecognizer）。
library;

import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/asr_provider.dart';

class SpeechToTextAsrProvider implements AsrProvider {
  final SpeechToText _stt = SpeechToText();
  final Future<String> Function() localeGet;
  bool _listening = false;

  SpeechToTextAsrProvider({required this.localeGet});

  @override
  Future<void> start(AsrCallbacks callbacks) async {
    if (_listening) return;
    final locale = await localeGet();
    final ok = await _stt.initialize(
      onError: (e) {
        _listening = false;
        callbacks.onError(UnknownException('识别失败：${e.errorMsg}'));
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') _listening = false;
      },
    );
    if (!ok) {
      callbacks.onError(const UnknownException('语音识别不可用（设备缺少识别服务）'));
      return;
    }
    _listening = true;
    _stt.listen(
      onResult: (r) {
        if (r.finalResult) {
          _listening = false;
          callbacks.onFinal(r.recognizedWords);
        } else {
          callbacks.onPartial(r.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: locale,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (!_listening) return;
    _listening = false;
    await _stt.stop();
  }

  @override
  Future<void> cancel() async {
    if (!_listening) return;
    _listening = false;
    await _stt.cancel();
  }
}
