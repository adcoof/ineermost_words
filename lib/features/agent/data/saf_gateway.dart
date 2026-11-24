/// SAF（Android Storage Access Framework）目录访问网关。
library;

import 'package:flutter/services.dart';

import '../domain/agent_approval.dart';

class SafException implements Exception {
  final String message;
  const SafException(this.message);
  @override
  String toString() => message;
}

class SafEntry {
  const SafEntry({
    required this.name,
    required this.path,
    required this.isDir,
    required this.size,
    required this.modified,
  });

  final String name;
  final String path;
  final bool isDir;
  final int size;
  final DateTime? modified;
}

/// SAF 操作接口；测试可注入内存实现。
abstract class SafGateway {
  /// 弹出系统目录选择器；用户取消返回 null。
  Future<AgentGrantedFolder?> pickDirectory();

  Future<List<SafEntry>> list(String uri, String path);
  Future<Uint8List> read(String uri, String path);
  Future<void> write(String uri, String path, String content);
  Future<void> writeBytes(String uri, String path, Uint8List bytes);
  Future<void> delete(String uri, String path);
  Future<void> rename(String uri, String path, String newName);
  Future<void> move(String uri, String from, String to);
  Future<bool> exists(String uri, String path);
}

/// 走原生 `xinyu/saf` MethodChannel 的实现。
class MethodChannelSafGateway implements SafGateway {
  const MethodChannelSafGateway();
  static const _channel = MethodChannel('xinyu/saf');

  @override
  Future<AgentGrantedFolder?> pickDirectory() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('pickDirectory');
      if (result == null) return null;
      final uri = result['uri']?.toString() ?? '';
      final name = result['name']?.toString() ?? '';
      if (uri.isEmpty) return null;
      return AgentGrantedFolder(
        uri: uri,
        name: name.isEmpty ? '已授权文件夹' : name,
      );
    } on PlatformException catch (e) {
      throw SafException(e.message ?? '打开目录选择器失败');
    }
  }

  @override
  Future<List<SafEntry>> list(String uri, String path) async {
    final result = await _call('list', {'uri': uri, 'path': path});
    final raw = result['entries'];
    if (raw is! List) return const [];
    return raw.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final rawModified = map['modified'];
      final modified = rawModified is int
          ? DateTime.fromMillisecondsSinceEpoch(rawModified)
          : (rawModified == null
              ? null
              : DateTime.tryParse(rawModified.toString()));
      return SafEntry(
        name: map['name']?.toString() ?? '',
        path: map['path']?.toString() ?? '',
        isDir: map['isDir'] == true,
        size: (map['size'] as num?)?.toInt() ?? 0,
        modified: modified,
      );
    }).toList();
  }

  @override
  Future<Uint8List> read(String uri, String path) async {
    final result = await _call('read', {'uri': uri, 'path': path});
    final raw = result['bytes'];
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    throw const SafException('读取结果格式错误');
  }

  @override
  Future<void> write(String uri, String path, String content) =>
      _call('write', {'uri': uri, 'path': path, 'content': content});

  @override
  Future<void> writeBytes(String uri, String path, Uint8List bytes) =>
      _call('writeBytes', {'uri': uri, 'path': path, 'bytes': bytes});

  @override
  Future<void> delete(String uri, String path) =>
      _call('delete', {'uri': uri, 'path': path});

  @override
  Future<void> rename(String uri, String path, String newName) =>
      _call('rename', {'uri': uri, 'path': path, 'newName': newName});

  @override
  Future<void> move(String uri, String from, String to) =>
      _call('move', {'uri': uri, 'from': from, 'to': to});

  @override
  Future<bool> exists(String uri, String path) async {
    final result = await _call('exists', {'uri': uri, 'path': path});
    return result['exists'] == true;
  }

  Future<Map<String, dynamic>> _call(
    String method,
    Map<String, dynamic> args,
  ) async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>(method, args);
      return result ?? <String, dynamic>{};
    } on PlatformException catch (e) {
      throw SafException(e.message ?? 'SAF 操作失败：$method');
    }
  }
}
