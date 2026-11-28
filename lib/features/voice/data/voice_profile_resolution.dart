/// 语音供应商解析：TTS/ASR 与聊天模型解耦，默认优先 MiMo。
///
/// 语音请求绝不能回落到文本聊天供应商（例如 DeepSeek 不支持 TTS/ASR）。
/// 解析顺序：用户显式选择且仍可用 → 自动挑一个可用的 MiMo → 无可用供应商。
library;

import '../../settings/data/api_profile_repository.dart';
import '../../settings/domain/api_profile.dart';

/// 供应商是否像 MiMo 语音供应商（名称/地址/模型任一含 mimo）。
bool isMiMoProfile(ApiProfile profile) {
  final haystack = '${profile.name} ${profile.baseUrl} ${profile.model}'
      .toLowerCase();
  return haystack.contains('mimo');
}

/// 在全部供应商里挑第一个可用的 MiMo（Key 非空），没有则 null。
String? autoVoiceProfileId(List<ApiProfile> profiles) {
  for (final profile in profiles) {
    if (profile.apiKey.trim().isNotEmpty && isMiMoProfile(profile)) {
      return profile.id;
    }
  }
  return null;
}

/// 解析某次语音请求使用的供应商。
///
/// [selectedId] 是用户在语音设置里的显式选择；失效或 Key 为空时自动挑
/// MiMo。两者都没有时返回 null，由调用方降级到 Edge/系统，而不是拿文本
/// 聊天供应商去请求语音接口。
Future<ApiProfile?> resolveVoiceApiProfile({
  required ApiProfileRepository repo,
  required String selectedId,
}) async {
  final id = selectedId.trim();
  if (id.isNotEmpty) {
    final selected = await repo.getById(id);
    if (selected != null && selected.apiKey.trim().isNotEmpty) return selected;
  }
  final autoId = autoVoiceProfileId(await repo.getAll());
  if (autoId == null) return null;
  return repo.getById(autoId);
}
