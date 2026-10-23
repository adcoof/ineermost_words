/// 统一错误模型。
///
/// 网络层（dio / SSE / TTS / ASR）把各自的原始错误归一化成这里的类型，
/// UI 只依赖 [AppException.message]（面向用户的中文文案）。
library;

/// 应用内所有可预期失败的基类。
sealed class AppException implements Exception {
  /// 面向用户的错误描述（中文）。
  final String message;

  /// 原始错误（dio 错误、解析异常等），仅用于日志/调试。
  final Object? cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message${cause == null ? '' : ' ($cause)'}';
}

/// 网络不可达：超时、DNS 失败、连接被拒。
class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

/// 鉴权失败：401 / 403，通常是 API Key 错误或无权限。
class AuthException extends AppException {
  const AuthException(super.message, [super.cause]);
}

/// 触发限流：429。
class RateLimitException extends AppException {
  const RateLimitException(super.message, [super.cause]);
}

/// 服务端错误：5xx。
class ServerException extends AppException {
  /// HTTP 状态码（若可得）。
  final int? statusCode;

  const ServerException(super.message, [super.cause, this.statusCode]);
}

/// 响应格式不符合预期：JSON 解析失败、SSE 帧损坏等。
class ParseException extends AppException {
  const ParseException(super.message, [super.cause]);
}

/// 客户端主动取消（用户点了停止）。
class CancelledException extends AppException {
  const CancelledException([super.message = '已取消', super.cause]);
}

/// 未分类失败。
class UnknownException extends AppException {
  const UnknownException(super.message, [super.cause]);
}
