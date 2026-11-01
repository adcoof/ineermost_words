/// 图片消息概括：用一次视觉调用把消息附图概括成一句话，
/// 供后续历史提示词以文本备注形式携带（历史不重发原图）。
///
/// 由 ChatController 在带图消息入库后 fire-and-forget 触发（与回复
/// 生成并行）。失败保留空摘要（历史降级 [图片] 占位），绝不向 UI 抛错。
library;

import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../core/utils/text.dart';
import '../../settings/data/api_profile_repository.dart';
import '../data/chat_api_client.dart';
import '../data/chat_repository.dart';

/// 图片概括字数上限。
const int kImageSummaryMaxChars = 60;

class ImageCaptionService {
  final ChatRepository chatRepo;
  final ApiProfileRepository profileRepo;
  final ChatApiClient api;

  /// 进行中的 messageId：并发触发直接跳过后者。
  final Set<String> _inFlight = {};

  /// 流式输出兜底超时：SSE 挂起时不让 _inFlight 永久卡死。
  final Duration streamTimeout;

  ImageCaptionService({
    required this.chatRepo,
    required this.profileRepo,
    required this.api,
    this.streamTimeout = const Duration(seconds: 90),
  });

  /// 后台为消息附图生成一句话概括；永不抛出、不阻塞调用方。
  Future<void> maybeCaption({required String messageId}) async {
    if (!_inFlight.add(messageId)) return;
    try {
      await _run(messageId);
    } catch (e) {
      // 失败零副作用：imageSummary 保持空，历史走 [图片] 占位。
      debugPrint('image caption: $e');
    } finally {
      _inFlight.remove(messageId);
    }
  }

  Future<void> _run(String messageId) async {
    final msg = await chatRepo.getMessage(messageId);
    if (msg == null) return;
    final paths = msg.imageFilePaths;
    if (paths.isEmpty) return;
    if (msg.imageSummary.trim().isNotEmpty) return; // 已有概括，幂等跳过。

    final conv = await chatRepo.getConversation(msg.conversationId);
    if (conv == null) return;
    final profile =
        await profileRepo.getById(conv.apiProfileId) ??
        await profileRepo.getDefault();
    if (profile == null) return;

    final images = <ApiImage>[];
    for (final path in paths) {
      final file = File(path);
      if (!await file.exists()) continue;
      images.add(ApiImage(bytes: await file.readAsBytes()));
    }
    if (images.isEmpty) return;

    final stream = api
        .streamChat(
          profile: profile,
          // 推理模型的 reasoning_tokens 计入 max_tokens 预算，且推理长度随机
          //（实测 28~130+，enable_thinking:false 无效），多图逐张简述的正文
          // 也要几十 token：512 = 推理余量 + 9 图概括余量（超出
          // kImageSummaryMaxChars 会再截）。
          maxTokens: 512,
          messages: [
            const ApiMessage(
              role: 'system',
              content:
                  '你是图片内容描述器。用一句简短的中文概括图片内容（不超过30字），'
                  '只输出描述本身，不要解释、不要引号。多张图片时用「；」分隔逐张简述。',
            ),
            ApiMessage(role: 'user', content: '请描述这些图片。', images: images),
          ],
        )
        .timeout(streamTimeout);
    final output = StringBuffer();
    await for (final delta in stream) {
      if (delta.content != null) output.write(delta.content);
    }

    var summary = cleanLlmLine(output.toString());
    if (summary.isEmpty) {
      // 空输出保留空摘要（历史走 [图片] 占位），但留下可诊断痕迹。
      debugPrint('image caption: empty output, keep empty summary');
      return;
    }
    if (summary.length > kImageSummaryMaxChars) {
      summary = summary.substring(0, kImageSummaryMaxChars);
    }
    await chatRepo.updateMessage(messageId, imageSummary: summary);
  }
}
