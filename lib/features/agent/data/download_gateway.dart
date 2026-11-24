import 'package:flutter/services.dart';

/// 保存到系统「下载」目录的结果。
class DownloadResult {
  const DownloadResult({required this.path, this.uri});

  /// 对人类可读的位置，例如 `Download/心语Agent/todo.txt`。
  final String path;

  /// MediaStore 的 content uri（Android 10+ 才有）。
  final String? uri;
}

class DownloadException implements Exception {
  const DownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 把 Agent 生成的文件导出到手机「下载」目录，方便用文件管理器找到。
abstract class DownloadGateway {
  Future<DownloadResult> saveText({
    required String name,
    required String content,
  });
}

class MethodChannelDownloadGateway implements DownloadGateway {
  const MethodChannelDownloadGateway();

  static const _channel = MethodChannel('xinyu/files');

  @override
  Future<DownloadResult> saveText({
    required String name,
    required String content,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'saveToDownloads',
        {'name': name, 'content': content},
      );
      return DownloadResult(
        path: result?['path']?.toString() ?? '',
        uri: result?['uri']?.toString(),
      );
    } on PlatformException catch (e) {
      throw DownloadException(e.message ?? '保存到下载目录失败');
    }
  }
}
