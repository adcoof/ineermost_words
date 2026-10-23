/// OpenAI 兼容 API 供应商配置（BYOK）。
library;

/// 一个 API 供应商配置。
class ApiProfile {
  final String id;
  final String name;

  /// 形如 https://api.deepseek.com/v1 （不含 /chat/completions 后缀）。
  final String baseUrl;
  final String apiKey;
  final String model;
  final double temperature;
  final int? maxTokens;

  /// 额外请求头（JSON 对象原文）。
  final String extraHeaders;
  final bool isDefault;

  const ApiProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.temperature,
    this.maxTokens,
    required this.extraHeaders,
    required this.isDefault,
  });

  ApiProfile copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    String? extraHeaders,
    bool? isDefault,
  }) =>
      ApiProfile(
        id: id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
        temperature: temperature ?? this.temperature,
        maxTokens: maxTokens ?? this.maxTokens,
        extraHeaders: extraHeaders ?? this.extraHeaders,
        isDefault: isDefault ?? this.isDefault,
      );
}