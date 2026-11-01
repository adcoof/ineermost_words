/// 语音编排器：把助手回复（流式干净文本）切成句子喂 TTS 队列，
/// 并把口型值流转发给桌宠。
///
/// 聊天控制器只依赖 [AssistantSpeechSink] 抽象；本类是真机实现。
/// 开关由全局设置 voice_enabled 控制（默认关，设置页打开）。
library;

import 'dart:async';

import '../../chat/application/speech_sink.dart';
import 'sentence_splitter.dart';
import 'tts_queue_service.dart';

/// 设置键。
const String kVoiceEnabledSetting = 'voice_enabled';

class VoiceOrchestrator implements AssistantSpeechSink {
  final TtsQueueService queue;
  final Future<bool> Function() enabledCheck;
  final Future<double> Function() speedGet;
  final Future<String> Function() voiceGet;

  SentenceSplitter? _splitter;
  bool _speakingThisMessage = false;

  /// 跨句标签状态：上一吐出的句段在未闭合标签内部被截断（带属性的标记含换行
  /// 时会被句切分从中间劈开），下一句开头是标签残段，需先跳到第一个 '>' 再剥。
  bool _inTag = false;

  /// 聊天页在场计数：ChatPage initState +1 / dispose -1（计数而非布尔，
  /// 聊天页叠聊天页时内层 pop 不误停）。>0 才朗读助手流；归零立即
  /// bargeIn（停播 + 清队列）。语音设置/音色工坊预览直调 queue.enqueue，
  /// 不经此门控。
  int _chatPages = 0;

  VoiceOrchestrator({
    required this.queue,
    required this.enabledCheck,
    required this.speedGet,
    required this.voiceGet,
  });

  /// 聊天页进入（initState）。
  void attachChatPage() => _chatPages++;

  /// 聊天页离开（dispose）：归零即按手动打断语义停播清队列。
  void detachChatPage() {
    _chatPages--;
    if (_chatPages <= 0) {
      _chatPages = 0;
      bargeIn();
    }
  }

  bool get _chatSpeechAllowed => _chatPages > 0;

  /// 桌宠口型订阅源。
  Stream<double> get lipValues => queue.lipValues;

  /// 标签标记正则：形如 `<shake_head>`、`<emotion:happy>`、`</emotion>`、`<br/>`；
  /// 也保守剥掉带属性的标记（如 `<a href="x">`）——TTS 读 markup 无意义。
  /// `<` 后必须紧跟字母才匹配，因此 'a < b'、'2<3>4'、'x<3' 不会被误伤。
  static final _tagMarkup =
      RegExp(r'</?[A-Za-z][A-Za-z0-9_:/.-]*(?:\s+[^<>]*)?/?>');

  /// 末尾未闭合的标签残段：流在标签中截断留下的 `<shake_`，或带换行的属性
  /// 标记被句切分劈开的前半截（如 `<a`）。同样要求 `<` 后紧跟字母。
  static final _tagTail =
      RegExp(r'</?[A-Za-z][A-Za-z0-9_:/.-]*(?:\s+[^<>]*)?$');

  /// 可朗读内容判定：含任意文字/数字才算正文。
  /// 剥后仅剩空白与句读的残句（如 `<shake_head>。` → `。`）不值得送 TTS。
  static final _hasReadable = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// 剥掉文本里的标签标记，只留可朗读正文。
  ///
  /// 同时剥掉末尾未闭合的残段：流可能在标签中截断，若正则强制要求闭合 '>'
  /// 会把 `<shake_` 原样漏给 TTS。
  ///
  /// 必须施加在 [SentenceSplitter] 吐出的整句上（enqueue 前），
  /// 绝不在增量输入端做无状态 strip：标签可能被 SSE chunk 切断成半截，
  /// 但 splitter 按句读切句、标签内部无句读，喂 splitter 的原始增量会
  /// 自然拼回完整标签；增量级 strip 会漏切半截标签。
  /// 剥后整句为空的由 TtsQueueService.enqueue 的空串忽略兜底。
  static String stripTagMarkup(String text) =>
      text.replaceAll(_tagMarkup, '').replaceAll(_tagTail, '');

  /// 句级剥标签（含跨句残段续接），返回可朗读正文（可为空）。
  String _scrub(String sentence) {
    var s = sentence;
    if (_inTag) {
      // 上句在标签内部被句读劈开：本句开头是残段，丢弃到第一个 '>'（含）为止。
      final gt = s.indexOf('>');
      if (gt < 0) return ''; // 整句仍落在标签内部
      s = s.substring(gt + 1);
      _inTag = false;
    }
    // 尾部未闭合残段（流截断/被劈开的前半截）剥掉并记状态，交下一句续接。
    _inTag = _tagTail.hasMatch(s.replaceAll(_tagMarkup, ''));
    return stripTagMarkup(s);
  }

  @override
  Future<void> onAssistantDelta(String cleanDelta) async {
    if (!await enabledCheck()) return;
    final splitter = _splitter ??= SentenceSplitter();
    final sentences = splitter.feed(cleanDelta);
    if (sentences.isEmpty) return;
    _speakingThisMessage = true;
    final speed = await speedGet();
    final voice = await voiceGet();
    for (final s in sentences) {
      // 句子级剥标签：裸情绪标签（<shake_head> 等）不进 TTS。
      // splitter 与 _scrub 在丢句时也照常推进，保住句边界与跨句标签状态。
      final text = _scrub(s);
      // 剥后仅剩句读的残句（`<shake_head>。` → `。`）同样丢弃。
      if (!_hasReadable.hasMatch(text)) continue;
      // 离开聊天页期间完成的句子直接丢弃（不续播）。
      if (!_chatSpeechAllowed) continue;
      queue.enqueue(text, speed: speed, voiceId: voice);
    }
  }

  @override
  Future<void> onAssistantDone() async {
    final splitter = _splitter;
    _splitter = null;
    if (splitter == null) return;
    final tail = splitter.flush();
    // 尾段同样句级剥标签（含跨句残段续接），随后清零跨句标签状态。
    final text = tail.isEmpty ? '' : _scrub(tail);
    _inTag = false;
    if (!_hasReadable.hasMatch(text)) return;
    if (!await enabledCheck()) return;
    if (!_chatSpeechAllowed) return;
    _speakingThisMessage = true;
    queue.enqueue(text, speed: await speedGet(), voiceId: await voiceGet());
  }

  @override
  Future<void> onAssistantInterrupted() async {
    _splitter = null;
    _inTag = false;
    if (_speakingThisMessage) {
      _speakingThisMessage = false;
      queue.clear(); // 打断：停播清队列。
    }
  }

  /// 用户 barge-in（按住说话/点停止）：打断播报。
  void bargeIn() {
    _splitter = null;
    _inTag = false;
    _speakingThisMessage = false;
    queue.clear();
  }
}
