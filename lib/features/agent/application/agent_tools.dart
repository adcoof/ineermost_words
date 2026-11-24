/// Agent 工具：文件根（工作区 + SAF 授权文件夹）、shell、HTTP。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../chat/data/chat_api_client.dart';
import '../data/device_gateway.dart';
import '../data/saf_gateway.dart';
import '../domain/agent_approval.dart';

/// 工具执行的可预期失败（路径越界、文件不存在等）。
class AgentToolException implements Exception {
  final String message;
  const AgentToolException(this.message);
  @override
  String toString() => message;
}

/// 提供给模型的工具定义。
const List<ApiTool> kAgentTools = [
  ApiTool(
    name: 'list_roots',
    description: '列出可访问的文件根：工作区与用户授权的文件夹。',
    parameters: {'type': 'object', 'properties': {}},
  ),
  ApiTool(
    name: 'list_files',
    description: '列出某个根下目录中的文件与子目录（不递归）。',
    parameters: {
      'type': 'object',
      'properties': {
        'root': {'type': 'string', 'description': '根名，默认「工作区」'},
        'path': {'type': 'string', 'description': '相对路径，默认 .'},
      },
    },
  ),
  ApiTool(
    name: 'read_file',
    description: '读取某个根内的 UTF-8 文本文件；大文件用 offset/limit 分页。',
    parameters: {
      'type': 'object',
      'properties': {
        'root': {'type': 'string', 'description': '根名，默认「工作区」'},
        'path': {'type': 'string', 'description': '相对路径'},
        'offset': {'type': 'integer', 'description': '起始字符偏移，默认 0'},
        'limit': {
          'type': 'integer',
          'description': '本次最多读取字符数，默认 2000，上限 4000',
        },
      },
      'required': ['path'],
    },
  ),
  ApiTool(
    name: 'write_file',
    description: '覆盖写入某个根内的 UTF-8 文本文件；会自动建父目录。',
    parameters: {
      'type': 'object',
      'properties': {
        'root': {'type': 'string', 'description': '根名，默认「工作区」'},
        'path': {'type': 'string', 'description': '相对路径'},
        'content': {'type': 'string', 'description': '完整文件内容'},
      },
      'required': ['path', 'content'],
    },
  ),
  ApiTool(
    name: 'delete_file',
    description: '删除某个根内的文件或空目录；不可恢复。',
    parameters: {
      'type': 'object',
      'properties': {
        'root': {'type': 'string', 'description': '根名，默认「工作区」'},
        'path': {'type': 'string', 'description': '相对路径'},
      },
      'required': ['path'],
    },
  ),
  ApiTool(
    name: 'move_file',
    description: '在同一个根内移动/重命名文件或目录。',
    parameters: {
      'type': 'object',
      'properties': {
        'root': {'type': 'string', 'description': '根名，默认「工作区」'},
        'from': {'type': 'string', 'description': '源相对路径'},
        'to': {'type': 'string', 'description': '目标相对路径'},
      },
      'required': ['from', 'to'],
    },
  ),
  ApiTool(
    name: 'rename',
    description: '重命名同一个根内的文件或目录（不改变所在目录）。',
    parameters: {
      'type': 'object',
      'properties': {
        'root': {'type': 'string', 'description': '根名，默认「工作区」'},
        'path': {'type': 'string', 'description': '相对路径'},
        'new_name': {'type': 'string', 'description': '新文件名'},
      },
      'required': ['path', 'new_name'],
    },
  ),
  ApiTool(
    name: 'run_command',
    description: '在 Android shell 中执行一条命令（工作目录为 Agent 工作区）。',
    parameters: {
      'type': 'object',
      'properties': {
        'command': {'type': 'string', 'description': '要执行的 shell 命令'},
        'timeout_ms': {'type': 'integer', 'description': '超时毫秒，默认 15000'},
      },
      'required': ['command'],
    },
  ),
  ApiTool(
    name: 'http_request',
    description: '发起 HTTP/HTTPS 请求并返回状态码、响应头与正文（正文截断）。',
    parameters: {
      'type': 'object',
      'properties': {
        'url': {'type': 'string', 'description': '完整 URL'},
        'method': {'type': 'string', 'description': 'GET/POST/PUT/DELETE，默认 GET'},
        'headers': {
          'type': 'object',
          'description': '请求头键值对',
          'additionalProperties': {'type': 'string'},
        },
        'body': {'type': 'string', 'description': '请求体文本'},
      },
      'required': ['url'],
    },
  ),
  ApiTool(
    name: 'web_search',
    description: '联网搜索网页，返回标题、链接与摘要（优先 360，失败回退百度/Bing/DuckDuckGo）。',
    parameters: {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'description': '搜索关键词'},
        'max_results': {
          'type': 'integer',
          'description': '结果数量，默认 5，上限 8',
        },
      },
      'required': ['query'],
    },
  ),
  ApiTool(
    name: 'convert_file',
    description:
        '把文件转换成另一种格式：md→html、csv→json、json→csv、html→txt，'
        '或把 jpg/webp/gif/bmp 图片转成 png。输出写到同目录下的新文件，不覆盖原文件。',
    parameters: {
      'type': 'object',
      'properties': {
        'path': {'type': 'string', 'description': '源文件相对路径'},
        'format': {
          'type': 'string',
          'description': '目标格式：html/json/csv/txt/png',
        },
        'root': {'type': 'string', 'description': '文件根，默认「工作区」'},
      },
      'required': ['path', 'format'],
    },
  ),
  ApiTool(
    name: 'device_status',
    description: '查看手机控制权限：Shizuku 是否可用/已授权、无障碍服务是否开启。',
    parameters: {'type': 'object', 'properties': {}},
  ),
  ApiTool(
    name: 'device_shell',
    description: '通过 Shizuku 的 ADB shell 身份执行命令，可做 input tap/swipe、am start、screencap 等。',
    parameters: {
      'type': 'object',
      'properties': {
        'command': {'type': 'string', 'description': '要执行的 shell 命令'},
      },
      'required': ['command'],
    },
  ),
  ApiTool(
    name: 'device_click_text',
    description: '通过无障碍服务按屏幕上的文字/描述查找控件并点击。',
    parameters: {
      'type': 'object',
      'properties': {
        'text': {'type': 'string', 'description': '要点击的文字或无障碍描述'},
      },
      'required': ['text'],
    },
  ),
  ApiTool(
    name: 'device_ui_text',
    description: '通过无障碍服务读取当前屏幕上的文字，用于判断界面状态。',
    parameters: {'type': 'object', 'properties': {}},
  ),
];

/// 文件根中的一项。
class AgentEntry {
  const AgentEntry({
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'type': isDir ? 'dir' : 'file',
        'size': size,
        'modified': modified?.toIso8601String(),
      };
}

class AgentReadResult {
  const AgentReadResult({
    required this.content,
    required this.total,
    required this.nextOffset,
  });

  final String content;
  final int total;
  final int? nextOffset;
}

/// 一个可访问的文件根（工作区或 SAF 授权文件夹）。
abstract class AgentFileRoot {
  String get name;
  String get kind;
  String? get uri;

  Future<List<AgentEntry>> list(String path);
  Future<AgentReadResult> read(String path, {int offset = 0, int limit = 2000});
  Future<void> write(String path, String content);
  Future<Uint8List> readBytes(String path);
  Future<void> writeBytes(String path, Uint8List bytes);
  Future<void> delete(String path);
  Future<void> rename(String path, String newName);
  Future<void> move(String from, String to);
  Future<bool> exists(String path);
}

/// 工作区根目录：`getApplicationSupportDirectory()/agent_workspace/`。
class AgentWorkspace {
  final Directory root;

  AgentWorkspace(this.root);

  late final Future<String> _rootReal = root.resolveSymbolicLinks();

  static Future<AgentWorkspace> open() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'agent_workspace'));
    await dir.create(recursive: true);
    // Android 的 app support 目录是 /data/user/0/...，真实路径是 /data/data/...；
    // 先 canonicalize 根目录，后续 p.isWithin / p.relative 才不会把合法路径判成越界。
    final real = await dir.resolveSymbolicLinks();
    return AgentWorkspace(Directory(real));
  }

  String get rootPath => root.path;

  /// 结构化列出目录（供 AgentFileRoot 使用）。
  Future<List<AgentEntry>> listEntries(String rawPath) async {
    final dirPath = await _resolveDirectory(rawPath);
    final dir = Directory(dirPath);
    final entries = await dir.list(followLinks: false).toList();
    entries.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      return p.basename(a.path).compareTo(p.basename(b.path));
    });
    final items = <AgentEntry>[];
    for (final entry in entries.take(200)) {
      final stat = await entry.stat();
      items.add(AgentEntry(
        name: p.basename(entry.path),
        path: p.relative(entry.path, from: root.path),
        isDir: entry is Directory,
        size: entry is File ? stat.size : 0,
        modified: stat.modified,
      ));
    }
    return items;
  }

  Future<String> listFiles(String rawPath) async {
    final dirPath = await _resolveDirectory(rawPath);
    final entries = await listEntries(rawPath);
    final all = await Directory(dirPath).list(followLinks: false).length;
    return jsonEncode({
      'ok': true,
      'path': p.relative(dirPath, from: root.path),
      'items': entries.map((e) => e.toJson()).toList(),
      'truncated': all > 200,
    });
  }

  Future<AgentReadResult> readEntry(
    String rawPath, {
    int offset = 0,
    int limit = 2000,
  }) async {
    final filePath = await _resolveFile(rawPath);
    final bytes = await File(filePath).readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      throw const AgentToolException('文件超过 2MB，暂不支持读取');
    }
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const AgentToolException('文件不是 UTF-8 文本，暂不支持读取');
    }
    return _sliceText(text, offset, limit);
  }

  Future<String> readFile(
    String rawPath, {
    int offset = 0,
    int limit = 2000,
  }) async {
    final filePath = await _resolveFile(rawPath);
    final result = await readEntry(rawPath, offset: offset, limit: limit);
    return jsonEncode({
      'ok': true,
      'path': p.relative(filePath, from: root.path),
      'content': result.content,
      'total': result.total,
      'nextOffset': result.nextOffset,
    });
  }

  /// 写入前由 UI 展示路径/大小/预览；这里只做实际落盘。
  Future<void> writeEntry(String rawPath, String content) async {
    final runes = content.runes.length;
    if (runes > 64000) {
      throw AgentToolException('内容过长（$runes 字符），单次最多 64,000 字符');
    }
    final filePath = await _resolveForWrite(rawPath);
    await File(filePath).writeAsString(content, flush: true);
  }

  Future<String> writeFile(String rawPath, String content) async {
    final runes = content.runes.length;
    await writeEntry(rawPath, content);
    return jsonEncode({
      'ok': true,
      'path': p.relative(await _resolveForWrite(rawPath), from: root.path),
      'chars': runes,
    });
  }

  Future<Uint8List> readEntryBytes(
    String rawPath, {
    int maxBytes = 10 * 1024 * 1024,
  }) async {
    final filePath = await _resolveFile(rawPath);
    final file = File(filePath);
    final size = await file.length();
    if (size > maxBytes) {
      throw AgentToolException('文件超过 ${maxBytes ~/ (1024 * 1024)}MB，暂不支持');
    }
    return file.readAsBytes();
  }

  Future<void> writeEntryBytes(String rawPath, Uint8List bytes) async {
    if (bytes.length > 10 * 1024 * 1024) {
      throw const AgentToolException('内容超过 10MB，暂不支持写入');
    }
    final filePath = await _resolveForWrite(rawPath);
    await File(filePath).writeAsBytes(bytes, flush: true);
  }

  Future<void> deleteEntry(String rawPath) async {
    final target = await _resolveExisting(rawPath);
    final type = await FileSystemEntity.type(target, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      final dir = Directory(target);
      if (!await dir.list().isEmpty) {
        throw const AgentToolException('目录不为空，暂不递归删除');
      }
      await dir.delete();
    } else if (type == FileSystemEntityType.file) {
      await File(target).delete();
    } else {
      throw const AgentToolException('目标不是普通文件或目录');
    }
  }

  Future<void> renameEntry(String rawPath, String newName) async {
    final target = await _resolveExisting(rawPath);
    final clean = newName.trim();
    if (clean.isEmpty || clean.contains('/') || clean.contains('\\') ||
        clean == '.' || clean == '..' || clean.contains('\u0000')) {
      throw const AgentToolException('新名称不合法');
    }
    final dest = p.join(p.dirname(target), clean);
    await _ensureWithin(dest);
    if (await FileSystemEntity.type(dest, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw AgentToolException('目标已存在：$clean');
    }
    final parentReal = await Directory(p.dirname(target)).resolveSymbolicLinks();
    final finalDest = p.join(parentReal, clean);
    if (await File(target).exists()) {
      await File(target).rename(finalDest);
    } else {
      await Directory(target).rename(finalDest);
    }
  }

  Future<void> moveEntry(String from, String to) async {
    final source = await _resolveExisting(from);
    final dest = await _resolveForWrite(to);
    if (await FileSystemEntity.type(dest, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw AgentToolException('目标已存在：$to');
    }
    if (await File(source).exists()) {
      await File(source).rename(dest);
    } else {
      await Directory(source).rename(dest);
    }
  }

  Future<bool> existsEntry(String rawPath) async {
    try {
      await _resolveExisting(rawPath);
      return true;
    } on AgentToolException {
      return false;
    }
  }

  /// 清空工作区（UI 二次确认后调用）。
  Future<void> clear() async {
    await root.delete(recursive: true);
    await root.create(recursive: true);
  }

  AgentReadResult _sliceText(String text, int offset, int limit) {
    final runes = text.runes.toList();
    final start = offset.clamp(0, runes.length);
    final take = limit.clamp(1, 4000);
    final end = math.min(start + take, runes.length);
    return AgentReadResult(
      content: String.fromCharCodes(runes.sublist(start, end)),
      total: runes.length,
      nextOffset: end < runes.length ? end : null,
    );
  }

  Future<String> _resolveExisting(String rawPath) async {
    final normalized = _normalize(rawPath);
    final candidate = p.join(root.path, normalized);
    final type = await FileSystemEntity.type(candidate, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      throw AgentToolException('不存在：$normalized');
    }
    if (type == FileSystemEntityType.link) {
      throw const AgentToolException('目标是符号链接，拒绝操作');
    }
    final real = type == FileSystemEntityType.directory
        ? await Directory(candidate).resolveSymbolicLinks()
        : await File(candidate).resolveSymbolicLinks();
    await _ensureWithin(real);
    return real;
  }

  Future<String> _resolveDirectory(String rawPath) async {
    final normalized = _normalize(rawPath, allowRoot: true);
    if (normalized.isEmpty) return root.path;
    final candidate = p.join(root.path, normalized);
    if (!p.isWithin(root.path, candidate) && !p.equals(root.path, candidate)) {
      throw const AgentToolException('路径越出工作区');
    }
    if (!await Directory(candidate).exists()) {
      throw AgentToolException('目录不存在：$normalized');
    }
    final real = await Directory(candidate).resolveSymbolicLinks();
    await _ensureWithin(real);
    return real;
  }

  Future<String> _resolveFile(String rawPath) async {
    final normalized = _normalize(rawPath);
    if (normalized.isEmpty) throw const AgentToolException('路径不能为空');
    final candidate = p.join(root.path, normalized);
    final file = File(candidate);
    if (!await file.exists()) {
      throw AgentToolException('文件不存在：$normalized');
    }
    final real = await file.resolveSymbolicLinks();
    await _ensureWithin(real);
    return real;
  }

  Future<String> _resolveForWrite(String rawPath) async {
    final normalized = _normalize(rawPath);
    if (normalized.isEmpty) throw const AgentToolException('路径不能为空');
    final candidate = p.join(root.path, normalized);
    await _ensureWithin(candidate);

    final link = Link(candidate);
    if (await link.exists()) {
      throw const AgentToolException('目标路径是符号链接，拒绝写入');
    }
    final file = File(candidate);
    if (await file.exists()) {
      final real = await file.resolveSymbolicLinks();
      await _ensureWithin(real);
      return real;
    }
    final parent = Directory(p.dirname(candidate));
    await parent.create(recursive: true);
    final parentReal = await parent.resolveSymbolicLinks();
    await _ensureWithin(parentReal);
    return p.join(parentReal, p.basename(candidate));
  }

  /// 拒绝绝对路径、盘符、`..` 与空路径；返回规范化后的相对路径。
  String _normalize(String rawPath, {bool allowRoot = false}) {
    final input = rawPath.trim();
    if (input.isEmpty) {
      if (allowRoot) return '';
      throw const AgentToolException('路径不能为空');
    }
    if (input.contains('\u0000')) {
      throw const AgentToolException('路径包含非法字符');
    }
    if (p.isAbsolute(input) ||
        input.startsWith('/') ||
        input.startsWith(r'\') ||
        RegExp(r'^[a-zA-Z]:').hasMatch(input)) {
      throw const AgentToolException('只允许工作区内的相对路径');
    }
    final normalized = p.normalize(input);
    final parts = p.split(normalized);
    if (parts.contains('..')) {
      throw const AgentToolException('路径不允许包含 ..');
    }
    if (normalized == '.') {
      if (allowRoot) return '';
      throw const AgentToolException('路径不能是工作区根目录');
    }
    return normalized;
  }

  Future<void> _ensureWithin(String path) async {
    final rootReal = await _rootReal;
    if (!p.equals(rootReal, path) && !p.isWithin(rootReal, path)) {
      throw const AgentToolException('路径越出工作区');
    }
  }
}

/// 工作区文件根。
class WorkspaceRoot implements AgentFileRoot {
  WorkspaceRoot(this.workspace);
  final AgentWorkspace workspace;

  @override
  String get name => '工作区';
  @override
  String get kind => 'workspace';
  @override
  String? get uri => null;

  @override
  Future<List<AgentEntry>> list(String path) => workspace.listEntries(path);
  @override
  Future<AgentReadResult> read(String path, {int offset = 0, int limit = 2000}) =>
      workspace.readEntry(path, offset: offset, limit: limit);
  @override
  Future<void> write(String path, String content) =>
      workspace.writeEntry(path, content);
  @override
  Future<Uint8List> readBytes(String path) => workspace.readEntryBytes(path);
  @override
  Future<void> writeBytes(String path, Uint8List bytes) =>
      workspace.writeEntryBytes(path, bytes);
  @override
  Future<void> delete(String path) => workspace.deleteEntry(path);
  @override
  Future<void> rename(String path, String newName) =>
      workspace.renameEntry(path, newName);
  @override
  Future<void> move(String from, String to) => workspace.moveEntry(from, to);
  @override
  Future<bool> exists(String path) => workspace.existsEntry(path);
}

/// SAF 授权文件夹根。
class SafRoot implements AgentFileRoot {
  SafRoot(this.gateway, this.folder);
  final SafGateway gateway;
  final AgentGrantedFolder folder;

  @override
  String get name => folder.name;
  @override
  String get kind => 'saf';
  @override
  String? get uri => folder.uri;

  @override
  Future<List<AgentEntry>> list(String path) async {
    final entries = await gateway.list(folder.uri, path);
    return entries
        .map((e) => AgentEntry(
              name: e.name,
              path: e.path,
              isDir: e.isDir,
              size: e.size,
              modified: e.modified,
            ))
        .toList();
  }

  @override
  Future<AgentReadResult> read(String path, {int offset = 0, int limit = 2000}) async {
    final bytes = await gateway.read(folder.uri, path);
    if (bytes.length > 2 * 1024 * 1024) {
      throw const AgentToolException('文件超过 2MB，暂不支持读取');
    }
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const AgentToolException('文件不是 UTF-8 文本，暂不支持读取');
    }
    final runes = text.runes.toList();
    final start = offset.clamp(0, runes.length);
    final take = limit.clamp(1, 4000);
    final end = math.min(start + take, runes.length);
    return AgentReadResult(
      content: String.fromCharCodes(runes.sublist(start, end)),
      total: runes.length,
      nextOffset: end < runes.length ? end : null,
    );
  }

  @override
  Future<void> write(String path, String content) async {
    final runes = content.runes.length;
    if (runes > 64000) {
      throw AgentToolException('内容过长（$runes 字符），单次最多 64,000 字符');
    }
    await gateway.write(folder.uri, path, content);
  }

  @override
  Future<Uint8List> readBytes(String path) => gateway.read(folder.uri, path);
  @override
  Future<void> writeBytes(String path, Uint8List bytes) =>
      gateway.writeBytes(folder.uri, path, bytes);

  @override
  Future<void> delete(String path) => gateway.delete(folder.uri, path);
  @override
  Future<void> rename(String path, String newName) =>
      gateway.rename(folder.uri, path, newName);
  @override
  Future<void> move(String from, String to) =>
      gateway.move(folder.uri, from, to);
  @override
  Future<bool> exists(String path) => gateway.exists(folder.uri, path);
}

/// 工具调用执行器：把 [ApiToolCall] 变成 JSON 字符串结果。
class AgentToolExecutor {
  AgentToolExecutor({
    required this.workspace,
    this.saf,
    this.grantedFolders,
    this.httpDomains,
    this.webSearchHtml,
    this.device,
  });

  final AgentWorkspace workspace;
  final SafGateway? saf;
  final Future<List<AgentGrantedFolder>> Function()? grantedFolders;
  final Future<List<String>> Function()? httpDomains;

  /// 手机控制通道（Shizuku + 无障碍）；未注入时相关工具返回业务错误。
  final DeviceGateway? device;

  /// 测试注入：给定搜索 URL 返回 HTML；空则走真实 DuckDuckGo。
  final Future<String> Function(Uri uri)? webSearchHtml;

  static const maxCommandOutput = 8000;
  static const maxHttpBody = 256 * 1024;

  AgentToolRisk riskFor(String tool) {
    switch (tool) {
      case 'list_roots':
      case 'list_files':
      case 'read_file':
        return AgentToolRisk.read;
      case 'write_file':
        return AgentToolRisk.write;
      case 'convert_file':
        return AgentToolRisk.write;
      case 'delete_file':
      case 'move_file':
      case 'rename':
        return AgentToolRisk.destructive;
      case 'run_command':
        return AgentToolRisk.shell;
      case 'http_request':
      case 'web_search':
        return AgentToolRisk.network;
      case 'device_status':
      case 'device_ui_text':
        return AgentToolRisk.read;
      case 'device_shell':
        return AgentToolRisk.shell;
      case 'device_click_text':
        return AgentToolRisk.destructive;
      default:
        return AgentToolRisk.destructive;
    }
  }

  /// 给确认卡用的标题与详情（不执行 I/O）。
  String describe(ApiToolCall call) {
    final args = _args(call);
    final root = args['root']?.toString() ?? '工作区';
    switch (call.name) {
      case 'write_file':
        final content = args['content']?.toString() ?? '';
        final preview = content.length > 160 ? '${content.substring(0, 160)}…' : content;
        return '写入 $root/${args['path'] ?? ''}（${content.runes.length} 字符）\n预览：$preview';
      case 'convert_file':
        return '转换 $root/${args['path'] ?? ''} → ${args['format'] ?? ''}';
      case 'delete_file':
        return '删除 $root/${args['path'] ?? ''}（不可恢复）';
      case 'move_file':
        return '移动 $root/${args['from'] ?? ''} → ${args['to'] ?? ''}';
      case 'rename':
        return '重命名 $root/${args['path'] ?? ''} → ${args['new_name'] ?? ''}';
      case 'run_command':
        return '执行命令：${args['command'] ?? ''}';
      case 'http_request':
        return '请求 ${(args['method'] ?? 'GET')} ${args['url'] ?? ''}';
      case 'web_search':
        return '联网搜索：${args['query'] ?? ''}';
      case 'device_shell':
        return '设备命令：${args['command'] ?? ''}';
      case 'device_click_text':
        return '点击屏幕文字：${args['text'] ?? ''}';
      case 'device_ui_text':
        return '读取当前屏幕文字';
      case 'device_status':
        return '查看设备控制权限';
      default:
        return '${call.name} ${jsonEncode(args)}';
    }
  }

  /// 执行一个工具；永远返回 JSON（失败也是业务结果，不抛给循环）。
  Future<String> execute(ApiToolCall call) async {
    final args = _args(call);
    try {
      switch (call.name) {
        case 'list_roots':
          return await _listRoots();
        case 'list_files':
          final root = await _root(args['root']?.toString());
          final entries = await root.list(args['path']?.toString() ?? '.');
          return _ok({
            'root': root.name,
            'path': args['path']?.toString() ?? '.',
            'items': entries.map((e) => e.toJson()).toList(),
            'truncated': entries.length >= 200,
          });
        case 'read_file':
          final root = await _root(args['root']?.toString());
          final result = await root.read(
            args['path']?.toString() ?? '',
            offset: _intArg(args['offset']) ?? 0,
            limit: _intArg(args['limit']) ?? 2000,
          );
          return _ok({
            'root': root.name,
            'path': args['path']?.toString() ?? '',
            'content': result.content,
            'total': result.total,
            'nextOffset': result.nextOffset,
          });
        case 'write_file':
          final root = await _root(args['root']?.toString());
          final path = args['path']?.toString() ?? '';
          final content = args['content']?.toString() ?? '';
          await root.write(path, content);
          return _ok({
            'root': root.name,
            'path': path,
            'chars': content.runes.length,
          });
        case 'convert_file':
          return await _convertFile(args);
        case 'delete_file':
          final root = await _root(args['root']?.toString());
          final path = args['path']?.toString() ?? '';
          await root.delete(path);
          return _ok({'root': root.name, 'path': path, 'deleted': true});
        case 'move_file':
          final root = await _root(args['root']?.toString());
          final from = args['from']?.toString() ?? '';
          final to = args['to']?.toString() ?? '';
          await root.move(from, to);
          return _ok({'root': root.name, 'from': from, 'to': to});
        case 'rename':
          final root = await _root(args['root']?.toString());
          final path = args['path']?.toString() ?? '';
          final newName = args['new_name']?.toString() ?? '';
          await root.rename(path, newName);
          return _ok({'root': root.name, 'path': path, 'newName': newName});
        case 'run_command':
          return await _runCommand(
            args['command']?.toString() ?? '',
            timeoutMs: _intArg(args['timeout_ms']) ?? 15000,
          );
        case 'http_request':
          return await _httpRequest(args);
        case 'web_search':
          return await _webSearch(args);
        case 'device_status':
          return await _deviceStatus();
        case 'device_shell':
          return await _deviceShell(args['command']?.toString() ?? '');
        case 'device_click_text':
          return await _deviceClick(args['text']?.toString() ?? '');
        case 'device_ui_text':
          return await _deviceUiText();
        default:
          return _error('未知工具：${call.name}');
      }
    } on AgentToolException catch (e) {
      return _error(e.message);
    } catch (e) {
      return _error('工具执行失败：$e');
    }
  }

  Future<String> _listRoots() async {
    final roots = <Map<String, dynamic>>[
      {'name': '工作区', 'kind': 'workspace'},
    ];
    if (saf != null && grantedFolders != null) {
      for (final folder in await grantedFolders!()) {
        roots.add({'name': folder.name, 'kind': 'saf', 'uri': folder.uri});
      }
    }
    return _ok({'roots': roots});
  }

  Future<AgentFileRoot> _root(String? rawName) async {
    final wanted = (rawName ?? '').trim();
    final roots = <AgentFileRoot>[WorkspaceRoot(workspace)];
    if (saf != null && grantedFolders != null) {
      for (final folder in await grantedFolders!()) {
        roots.add(SafRoot(saf!, folder));
      }
    }
    if (wanted.isEmpty || wanted == '工作区') return roots.first;
    for (final root in roots) {
      if (root.name == wanted) return root;
    }
    throw AgentToolException('未知根：$wanted；可先用 list_roots 查看');
  }

  Future<DeviceGateway> _deviceGateway() async {
    final gateway = device;
    if (gateway == null) {
      throw const AgentToolException('设备控制通道未初始化');
    }
    return gateway;
  }

  Future<String> _deviceStatus() async {
    final status = await (await _deviceGateway()).status();
    return _ok({
      'shizukuAvailable': status.shizukuAvailable,
      'shizukuGranted': status.shizukuGranted,
      'accessibilityEnabled': status.accessibilityEnabled,
    });
  }

  Future<String> _deviceShell(String rawCommand) async {
    final command = rawCommand.trim();
    if (command.isEmpty) throw const AgentToolException('命令不能为空');
    final gateway = await _deviceGateway();
    final status = await gateway.status();
    if (!status.shizukuGranted) {
      throw const AgentToolException('Shizuku 未授权：请在设置 → Agent 默认权限里请求授权');
    }
    final result = await gateway.shell(command);
    return _ok({
      'command': command,
      'code': result.code,
      'stdout': _truncate(result.stdout, maxCommandOutput),
      'stderr': _truncate(result.stderr, maxCommandOutput),
    });
  }

  Future<String> _deviceClick(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) throw const AgentToolException('文字不能为空');
    final gateway = await _deviceGateway();
    final status = await gateway.status();
    if (!status.accessibilityEnabled) {
      throw const AgentToolException('无障碍服务未开启：请在系统设置 → 无障碍中启用「心语 Agent 操作」');
    }
    final clicked = await gateway.clickText(text);
    return _ok({'text': text, 'clicked': clicked});
  }

  Future<String> _deviceUiText() async {
    final gateway = await _deviceGateway();
    final status = await gateway.status();
    if (!status.accessibilityEnabled) {
      throw const AgentToolException('无障碍服务未开启：请在系统设置 → 无障碍中启用「心语 Agent 操作」');
    }
    final text = await gateway.uiText();
    return _ok({'text': _truncate(text, 12000)});
  }

  String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…[已截断]';
  }

  Future<String> _runCommand(String rawCommand, {required int timeoutMs}) async {
    final command = rawCommand.trim();
    if (command.isEmpty) throw const AgentToolException('命令不能为空');
    if (RegExp(r'(^|[;&|]\s*)su(\s|$)', caseSensitive: false).hasMatch(command)) {
      throw const AgentToolException('不允许执行 su');
    }
    final timeout = timeoutMs.clamp(1000, 60000);
    // 真机 Android 用 /system/bin/sh；桌面/测试环境用系统 shell。
    final shell = Platform.isAndroid
        ? '/system/bin/sh'
        : (Platform.isWindows ? 'cmd.exe' : '/bin/sh');
    final shellArgs = Platform.isWindows ? ['/c', command] : ['-c', command];
    final process = await Process.start(
      shell,
      shellArgs,
      workingDirectory: workspace.root.path,
      runInShell: false,
    );
    final out = StringBuffer();
    final err = StringBuffer();
    var timedOut = false;
    final outSub = process.stdout.transform(utf8.decoder).listen((chunk) {
      if (out.length < maxCommandOutput) out.write(chunk);
    });
    final errSub = process.stderr.transform(utf8.decoder).listen((chunk) {
      if (err.length < maxCommandOutput) err.write(chunk);
    });
    int exitCode;
    try {
      exitCode = await process.exitCode.timeout(Duration(milliseconds: timeout));
    } on TimeoutException {
      timedOut = true;
      if (Platform.isWindows) {
        // 杀掉 cmd.exe 及其子进程，避免子进程继续占用工作目录。
        try {
          await Process.run(
            'taskkill',
            ['/F', '/T', '/PID', '${process.pid}'],
            runInShell: true,
          );
        } catch (_) {
          process.kill(ProcessSignal.sigkill);
        }
      } else {
        process.kill(ProcessSignal.sigkill);
      }
      exitCode = -1;
    } finally {
      await outSub.cancel();
      await errSub.cancel();
    }
    return _ok({
      'command': command,
      'exitCode': exitCode,
      'stdout': _clip(out.toString()),
      'stderr': _clip(err.toString()),
      'timedOut': timedOut,
    });
  }

  Future<String> _httpRequest(Map<String, dynamic> args) async {
    final rawUrl = args['url']?.toString().trim() ?? '';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const AgentToolException('只支持 http/https URL');
    }
    _checkHttpHost(uri.host);
    if (httpDomains != null) {
      final allowed = await httpDomains!();
      if (allowed.isNotEmpty &&
          !allowed.any((d) => uri.host == d || uri.host.endsWith('.$d'))) {
        throw AgentToolException('域名不在允许列表：${uri.host}');
      }
    }
    final method = (args['method']?.toString() ?? 'GET').toUpperCase();
    if (!const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD'].contains(method)) {
      throw AgentToolException('不支持的 HTTP 方法：$method');
    }
    final headers = <String, String>{};
    final rawHeaders = args['headers'];
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        headers[key.toString()] = value.toString();
      });
    }
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: false,
      validateStatus: (_) => true,
    ));
    final response = await dio.request<String>(
      uri.toString(),
      data: args['body']?.toString(),
      options: Options(
        method: method,
        headers: headers,
        responseType: ResponseType.plain,
      ),
    );
    final body = response.data ?? '';
    return _ok({
      'url': uri.toString(),
      'status': response.statusCode,
      'headers': response.headers.map.map((k, v) => MapEntry(k, v.join(', '))),
      'body': body.length > maxHttpBody ? body.substring(0, maxHttpBody) : body,
      'truncated': body.length > maxHttpBody,
    });
  }

  /// 文本文件格式转换：md→html、csv→json、json→csv、html→txt。
  Future<String> _convertFile(Map<String, dynamic> args) async {
    final root = await _root(args['root']?.toString());
    final path = (args['path']?.toString() ?? '').trim();
    final format = (args['format']?.toString() ?? '')
        .toLowerCase()
        .replaceAll('.', '');
    if (path.isEmpty) throw const AgentToolException('源文件路径不能为空');
    final ext = p.extension(path).toLowerCase();
    if (format == 'png') {
      return _convertImageToPng(root, path, ext);
    }
    final source = await _readAll(root, path);

    final String output;
    switch (format) {
      case 'html':
        if (ext != '.md' && ext != '.markdown') {
          throw const AgentToolException('只有 Markdown 文件能转 HTML');
        }
        output = md.markdownToHtml(source);
      case 'json':
        if (ext != '.csv') {
          throw const AgentToolException('只有 CSV 文件能转 JSON');
        }
        output = const JsonEncoder.withIndent('  ').convert(_csvToJson(source));
      case 'csv':
        if (ext != '.json') {
          throw const AgentToolException('只有 JSON 文件能转 CSV');
        }
        output = _jsonToCsv(source);
      case 'txt':
        if (ext != '.html' && ext != '.htm') {
          throw const AgentToolException('只有 HTML 文件能转纯文本');
        }
        output = _cleanHtml(source);
      default:
        throw AgentToolException('不支持的目标格式：$format');
    }

    final chars = output.runes.length;
    if (chars > 60000) {
      throw AgentToolException('转换结果过长（$chars 字符），请先拆分文件');
    }
    final outPath = '${p.withoutExtension(path)}.$format';
    await root.write(outPath, output);
    return _ok({
      'root': root.name,
      'source': path,
      'path': outPath,
      'chars': chars,
    });
  }

  Future<String> _convertImageToPng(
    AgentFileRoot root,
    String path,
    String ext,
  ) async {
    const imageExts = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};
    if (!imageExts.contains(ext)) {
      throw AgentToolException('只有图片能转 PNG（当前是 $ext）');
    }
    if (ext == '.png') {
      throw const AgentToolException('源文件已经是 PNG');
    }
    final bytes = await root.readBytes(path);
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const AgentToolException('无法解码图片，文件可能已损坏');
    }
    final png = Uint8List.fromList(img.encodePng(decoded));
    final outPath = '${p.withoutExtension(path)}.png';
    await root.writeBytes(outPath, png);
    return _ok({
      'root': root.name,
      'source': path,
      'path': outPath,
      'bytes': png.length,
    });
  }

  Future<String> _readAll(AgentFileRoot root, String path) async {
    final buffer = StringBuffer();
    var offset = 0;
    while (true) {
      final part = await root.read(path, offset: offset, limit: 4000);
      buffer.write(part.content);
      if (part.nextOffset == null || buffer.length > 64000) break;
      offset = part.nextOffset!;
    }
    final text = buffer.toString();
    if (text.length > 64000) {
      throw const AgentToolException('文件超过 64,000 字符，请先拆分');
    }
    return text;
  }

  List<List<String>> _parseCsv(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          field.write(ch);
        }
      } else if (ch == '"') {
        quoted = true;
      } else if (ch == ',') {
        row.add(field.toString());
        field.clear();
      } else if (ch == '\n') {
        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = <String>[];
      } else if (ch != '\r') {
        field.write(ch);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  List<Map<String, String>> _csvToJson(String text) {
    final rows = _parseCsv(text)
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .toList();
    if (rows.isEmpty) return <Map<String, String>>[];
    final header = rows.first.map((h) => h.trim()).toList();
    return [
      for (final row in rows.skip(1))
        {
          for (var i = 0; i < header.length; i++)
            header[i]: i < row.length ? row[i] : '',
        },
    ];
  }

  String _jsonToCsv(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! List) {
      throw const AgentToolException('JSON 顶层需要是数组');
    }
    final keys = <String>[];
    final rows = <Map<String, String>>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final map = <String, String>{};
      item.forEach((key, value) {
        final name = key.toString();
        if (!keys.contains(name)) keys.add(name);
        map[name] = value?.toString() ?? '';
      });
      rows.add(map);
    }
    if (keys.isEmpty) return '';
    String escape(String value) =>
        value.contains(RegExp(r'[,"\n]')) ? '"${value.replaceAll('"', '""')}"' : value;
    return [
      keys.map(escape).join(','),
      for (final row in rows) keys.map((key) => escape(row[key] ?? '')).join(','),
    ].join('\n');
  }

  /// 联网搜索：优先 360/百度等国内可直连结果页，再回退 Bing/DuckDuckGo。
  Future<String> _webSearch(Map<String, dynamic> args) async {
    final query = (args['query']?.toString() ?? '').trim();
    if (query.isEmpty) throw const AgentToolException('搜索词不能为空');
    final max = ((_intArg(args['max_results']) ?? 5).clamp(1, 8)).toInt();
    final failures = <String>[];

    Future<String?> tryProvider(
      String name,
      Uri uri,
      List<Map<String, String>> Function(String html, int max) parse,
    ) async {
      try {
        final body = await _fetchWeb(uri);
        final results = parse(body, max);
        debugPrint('agent_web_search $name results=${results.length}');
        if (results.isEmpty) {
          failures.add('$name 无结果');
          return null;
        }
        return _ok({
          'query': query,
          'count': results.length,
          'results': results,
          'source': name,
        });
      } catch (e) {
        failures.add('$name $e');
        return null;
      }
    }

    // 360 搜索：国内可直连，结果链接是 m.so.com/jump?u=<encoded target>。
    final so = await tryProvider(
      '360',
      Uri.https('m.so.com', '/s', {'q': query}),
      _parseSoResults,
    );
    if (so != null) return so;

    // 百度移动页：结果链接是 m.baidu.com 的跳转链接，标题可解析。
    final baidu = await tryProvider(
      'baidu',
      Uri.https('m.baidu.com', '/s', {'word': query}),
      _parseBaiduResults,
    );
    if (baidu != null) return baidu;

    final bingRss = await tryProvider(
      'bing',
      Uri.https('cn.bing.com', '/search', {
        'q': query,
        'format': 'rss',
        'count': '$max',
      }),
      _parseBingRss,
    );
    if (bingRss != null) return bingRss;

    final bingHtml = await tryProvider(
      'bing',
      Uri.https('cn.bing.com', '/search', {
        'q': query,
        'setlang': 'zh-Hans',
        'count': '$max',
      }),
      _parseBingResults,
    );
    if (bingHtml != null) return bingHtml;

    final ddg = await tryProvider(
      'duckduckgo',
      Uri.https('html.duckduckgo.com', '/html/', {'q': query}),
      _parseWebResults,
    );
    if (ddg != null) return ddg;

    throw AgentToolException('联网搜索失败：${failures.join('；')}');
  }

  Future<String> _fetchWeb(Uri uri) async {
    if (webSearchHtml != null) return webSearchHtml!(uri);
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      validateStatus: (status) => status != null && status < 400,
    ));
    late final Response<String> response;
    try {
      response = await dio.get<String>(
        uri.toString(),
        options: Options(
          responseType: ResponseType.plain,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Mobile Safari/537.36',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            // 避免服务端返回 Dart HttpClient 不支持的 Brotli。
            'Accept-Encoding': 'identity',
          },
        ),
      );
    } on DioException catch (e) {
      final body = e.response?.data?.toString() ?? '';
      final brief = body.length > 200 ? body.substring(0, 200) : body;
      throw AgentToolException(
        'HTTP ${e.response?.statusCode ?? '-'}: ${e.message ?? e.type.name}'
        '${brief.isEmpty ? '' : ' body=$brief'}',
      );
    }
    final body = response.data ?? '';
    debugPrint(
      'agent_web_fetch ${uri.host} status=${response.statusCode} '
      'bytes=${body.length} b_algo=${body.contains('b_algo')} '
      'result__a=${body.contains('result__a')}',
    );
    final limit = 1024 * 1024;
    return body.length > limit ? body.substring(0, limit) : body;
  }

  List<Map<String, String>> _parseWebResults(String html, int max) {
    final out = <Map<String, String>>[];
    final linkRe = RegExp(
      r'class="result__a"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
      dotAll: true,
    );
    final altLinkRe = RegExp(
      r'class="result-link"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
      dotAll: true,
    );
    final snippetRe = RegExp(
      r'class="result__snippet"[^>]*>(.*?)</(?:a|div)>',
      dotAll: true,
    );
    final links = [
      ...linkRe.allMatches(html),
      ...altLinkRe.allMatches(html),
    ];
    final snippets = snippetRe.allMatches(html).toList();
    for (var i = 0; i < links.length && out.length < max; i++) {
      final url = _decodeDdgHref(links[i].group(1) ?? '');
      if (url.isEmpty) continue;
      final title = _cleanHtml(links[i].group(2) ?? '');
      if (title.isEmpty) continue;
      final rawSnippet = i < snippets.length
          ? _cleanHtml(snippets[i].group(1) ?? '')
          : '';
      final snippet = rawSnippet.length > 300
          ? '${rawSnippet.substring(0, 300)}…'
          : rawSnippet;
      out.add({'title': title, 'url': url, 'snippet': snippet});
    }
    return out;
  }

  /// 解析 360 搜索结果：结果链接是 `m.so.com/jump?u=<encoded target>`，
  /// 标题在紧随其后的 h3 中；同一条目也可能直接带 data-mdurl。
  List<Map<String, String>> _parseSoResults(String html, int max) {
    final out = <Map<String, String>>[];
    final seen = <String>{};
    final anchors = RegExp(r'<a\b([^>]*)>(.*?)</a>', dotAll: true)
        .allMatches(html);
    for (final anchor in anchors) {
      if (out.length >= max) break;
      final attrs = anchor.group(1) ?? '';
      final body = anchor.group(2) ?? '';
      if (!body.contains('<h3') && !attrs.contains('data-mdurl')) continue;

      var url = '';
      final direct = RegExp(r'data-mdurl="([^"]+)"').firstMatch(attrs);
      if (direct != null) {
        url = _cleanHtml(direct.group(1) ?? '');
      } else {
        final jump = RegExp(r'[?&]u=([^&"\s]+)').firstMatch(attrs);
        if (jump != null) {
          url = Uri.decodeComponent(_cleanHtml(jump.group(1) ?? ''));
        }
      }
      if (!url.startsWith('http')) continue;
      if (url.contains('fanyi.so.com') || url.contains('m.so.com')) continue;
      final h3 = RegExp(r'<h3[^>]*>(.*?)</h3>', dotAll: true).firstMatch(body);
      final title = _cleanHtml(h3?.group(1) ?? '');
      if (title.isEmpty || title.length > 120) continue;
      if (!seen.add(url)) continue;
      out.add({'title': title, 'url': url, 'snippet': ''});
    }
    return out;
  }

  /// 解析百度移动页：结果标题在 h3 内，链接是 m.baidu.com 跳转地址。
  List<Map<String, String>> _parseBaiduResults(String html, int max) {
    final out = <Map<String, String>>[];
    final seen = <String>{};
    final anchors = RegExp(r'<a\b([^>]*)>(.*?)</a>', dotAll: true)
        .allMatches(html);
    for (final anchor in anchors) {
      if (out.length >= max) break;
      final attrs = anchor.group(1) ?? '';
      final body = anchor.group(2) ?? '';
      if (!body.contains('<h3')) continue;
      final href = RegExp(r'href="([^"]+)"').firstMatch(attrs);
      if (href == null) continue;
      final url = _cleanHtml(href.group(1) ?? '');
      if (!url.startsWith('http')) continue;
      final h3 = RegExp(r'<h3[^>]*>(.*?)</h3>', dotAll: true).firstMatch(body);
      final title = _cleanHtml(h3?.group(1) ?? '');
      if (title.isEmpty || title.length > 120) continue;
      if (!seen.add(url)) continue;
      out.add({'title': title, 'url': url, 'snippet': ''});
    }
    return out;
  }

  List<Map<String, String>> _parseBingRss(String xml, int max) {
    final out = <Map<String, String>>[];
    final items = RegExp(r'<item>(.*?)</item>', dotAll: true).allMatches(xml);
    for (final item in items) {
      if (out.length >= max) break;
      final chunk = item.group(1) ?? '';
      final title = _cleanHtml(_rssTag(chunk, 'title'));
      var link = _cleanHtml(_rssTag(chunk, 'link'));
      if (link.isNotEmpty && !link.startsWith('http')) {
        link = link.startsWith('//') ? 'https:$link' : '';
      }
      final snippet = _cleanHtml(_rssTag(chunk, 'description'));
      if (title.isEmpty || link.isEmpty) continue;
      out.add({
        'title': title,
        'url': link,
        'snippet': snippet.length > 300
            ? '${snippet.substring(0, 300)}…'
            : snippet,
      });
    }
    return out;
  }

  String _rssTag(String chunk, String tag) {
    final match = RegExp(
      '<$tag>(?:<!\\[CDATA\\[)?(.*?)(?:\\]\\]>)?</$tag>',
      dotAll: true,
    ).firstMatch(chunk);
    return (match?.group(1) ?? '').trim();
  }

  List<Map<String, String>> _parseBingResults(String html, int max) {
    final out = <Map<String, String>>[];
    final blocks = RegExp(
      r'<li class="b_algo".*?</li>',
      dotAll: true,
    ).allMatches(html);
    for (final block in blocks) {
      if (out.length >= max) break;
      final chunk = block.group(0) ?? '';
      final link = RegExp(
        r'<h2[^>]*>\s*<a[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
        dotAll: true,
      ).firstMatch(chunk);
      if (link == null) continue;
      final url = _decodeBingHref(link.group(1) ?? '');
      if (url.isEmpty) continue;
      final title = _cleanHtml(link.group(2) ?? '');
      if (title.isEmpty) continue;
      final paragraph = RegExp(
        r'<p[^>]*>(.*?)</p>',
        dotAll: true,
      ).firstMatch(chunk);
      var snippet = paragraph == null
          ? ''
          : _cleanHtml(paragraph.group(1) ?? '')
              .replaceAll(RegExp(r'\s*阅读更多$'), '')
              .trim();
      if (snippet.length > 300) snippet = '${snippet.substring(0, 300)}…';
      out.add({'title': title, 'url': url, 'snippet': snippet});
    }
    return out;
  }

  String _decodeBingHref(String raw) {
    var href = raw.trim().replaceAll('&amp;', '&');
    if (href.startsWith('//')) href = 'https:$href';
    if (!href.startsWith('http://') && !href.startsWith('https://')) {
      return '';
    }
    return href;
  }

  String _decodeDdgHref(String raw) {
    var href = raw.trim().replaceAll('&amp;', '&');
    if (href.startsWith('//')) href = 'https:$href';
    final parsed = Uri.tryParse(href);
    if (parsed != null && parsed.host.endsWith('duckduckgo.com')) {
      final target = parsed.queryParameters['uddg'];
      if (target != null && target.isNotEmpty) {
        href = Uri.decodeComponent(target);
      }
    }
    if (!href.startsWith('http://') && !href.startsWith('https://')) return '';
    return href;
  }

  String _cleanHtml(String raw) {
    var text = raw.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    text = text.replaceAllMapped(RegExp(r'&#(x?[0-9a-fA-F]+);'), (match) {
      final value = match.group(1)!;
      final code = value.startsWith('x')
          ? int.tryParse(value.substring(1), radix: 16)
          : int.tryParse(value);
      if (code == null || code <= 0 || code > 0x10FFFF) return '';
      return String.fromCharCode(code);
    });
    const entities = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&nbsp;': ' ',
      '&ensp;': ' ',
      '&emsp;': ' ',
      '&hellip;': '…',
      '&mdash;': '—',
    };
    entities.forEach((key, value) => text = text.replaceAll(key, value));
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _checkHttpHost(String host) {
    final lower = host.toLowerCase();
    if (lower.isEmpty) throw const AgentToolException('URL 缺少主机名');
    if (lower == 'localhost' ||
        lower.endsWith('.localhost') ||
        lower == '0.0.0.0' ||
        lower == '::1' ||
        lower == '[::1]') {
      throw const AgentToolException('禁止访问本机地址');
    }
    final v4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$').firstMatch(lower);
    if (v4 != null) {
      final a = int.parse(v4.group(1)!);
      final b = int.parse(v4.group(2)!);
      if (a == 10 ||
          a == 127 ||
          (a == 192 && b == 168) ||
          (a == 172 && b >= 16 && b <= 31) ||
          (a == 169 && b == 254) ||
          a == 0) {
        throw const AgentToolException('禁止访问内网地址');
      }
    }
    final isIpv6 = lower.contains(':');
    if (isIpv6 &&
        (lower.startsWith('fc') ||
            lower.startsWith('fd') ||
            lower.startsWith('fe80'))) {
      throw const AgentToolException('禁止访问内网 IPv6 地址');
    }
  }

  Map<String, dynamic> _args(ApiToolCall call) {
    try {
      final decoded = jsonDecode(call.arguments.isEmpty ? '{}' : call.arguments);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  int? _intArg(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _clip(String text) =>
      text.length > maxCommandOutput ? '${text.substring(0, maxCommandOutput)}…' : text;

  String _ok(Map<String, dynamic> data) => jsonEncode({'ok': true, ...data});
  String _error(String message) => jsonEncode({'ok': false, 'error': message});
}
