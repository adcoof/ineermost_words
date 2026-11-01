/// 聊天输入栏：文本框 + 附图 + 发送 + 按住说话（ASR）。
///
/// 按住麦克风：打断 TTS 播报并开始识别；松手：识别结果直接发送。
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/providers.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/glass.dart';
import '../../voice/domain/asr_provider.dart';
import '../domain/models.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({super.key});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// 待发送附图（已降采样 JPEG 字节：缩略图=入库=发送同一份）。
  final List<Uint8List> _images = [];

  bool _listening = false;
  String _partial = '';
  String _finalText = '';
  bool _sent = false;
  Timer? _releaseFallback;

  @override
  void dispose() {
    _releaseFallback?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty || !mounted) return;
    var picked = 0;
    for (final f in files) {
      if (_images.length >= kMaxImagesPerMessage) break;
      final bytes = await f.xFile.readAsBytes();
      _images.add(downscaleToJpeg(bytes));
      picked++;
    }
    if (picked < files.length && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('最多 $kMaxImagesPerMessage 张图片')));
    }
    setState(() {});
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty && _images.isEmpty) return;
    _controller.clear();
    final images = List<Uint8List>.of(_images);
    _images.clear();
    ref.read(chatControllerProvider.notifier).send(text, images: images);
    setState(() {});
    _focusNode.requestFocus();
  }

  Future<void> _startListening() async {
    if (_listening) return;
    // 打断：TTS 播报立即停；流式生成中也停。
    ref.read(voiceOrchestratorProvider).bargeIn();
    if (ref.read(chatControllerProvider).isStreaming) {
      ref.read(chatControllerProvider.notifier).stop();
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('需要麦克风权限才能语音输入')));
      }
      return;
    }
    _partial = '';
    _finalText = '';
    _sent = false;
    setState(() => _listening = true);
    final asr = ref.read(asrProviderProvider);
    await asr.start(
      AsrCallbacks(
        onPartial: (p) {
          if (!mounted || !_listening) return;
          setState(() {
            _partial = p;
            _controller.text = p;
          });
        },
        onFinal: (t) {
          if (!mounted || _sent) return;
          _finalText = t;
          _releaseFallback?.cancel();
          _commitResult();
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _listening = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        },
      ),
    );
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    setState(() => _listening = false); // 图标先复位，结果稍后到。
    await ref.read(asrProviderProvider).stop();
    // 兜底：最终结果回调迟迟不来时，用部分结果或放弃。
    _releaseFallback?.cancel();
    _releaseFallback = Timer(const Duration(milliseconds: 1500), () {
      if (!_sent) _commitResult();
    });
  }

  void _commitResult() {
    if (_sent) return;
    _sent = true;
    final text = (_finalText.isNotEmpty ? _finalText : _partial).trim();
    _partial = '';
    _finalText = '';
    _controller.clear();
    if (text.isNotEmpty) {
      ref.read(chatControllerProvider.notifier).send(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStreaming = ref.watch(chatControllerProvider).isStreaming;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        // 液态玻璃输入栏（v8）：固定栏用真模糊，一层、ClipRect 由组件保证。
        child: GlassPanel(
          blur: 18,
          radius: const BorderRadius.all(Radius.circular(20)),
          fillOpacity: 0.07,
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 待发送附图预览条。
              if (_images.isNotEmpty)
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _images[i],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            tooltip: '移除',
                            iconSize: 16,
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                setState(() => _images.removeAt(i)),
                            icon: const Icon(Icons.cancel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _listening ? '松手发送，识别中…' : '输入消息…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 添加图片。
                  IconButton(
                    tooltip: '添加图片',
                    onPressed: _pickImages,
                    icon: const Icon(Icons.image_outlined),
                  ),
                  const SizedBox(width: 4),
                  // 按住说话。
                  Listener(
                    onPointerDown: (_) => unawaited(_startListening()),
                    onPointerUp: (_) => unawaited(_stopListening()),
                    onPointerCancel: (_) => unawaited(_stopListening()),
                    child: IconButton.filledTonal(
                      tooltip: '按住说话',
                      onPressed: () {}, // 事件走 Listener。
                      icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                      color: _listening
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: isStreaming ? '生成中' : '发送',
                    onPressed: isStreaming ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
