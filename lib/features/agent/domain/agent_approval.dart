import 'dart:convert';

/// Agent 审批模式。
///
/// - [ask]：每个工具调用都确认；
/// - [auto]：只读与普通写入自动放行，删除/移动/shell/HTTP 仍需确认；
/// - [full]：全部自动放行，但仍保留工作区/SAF 根、禁 su、禁私网等硬边界。
enum AgentApprovalMode {
  ask('ask', '每步确认', '每次工具调用都先问你'),
  auto('auto', '自动审查', '读写自动放行，删除/移动/命令/联网仍确认'),
  full('full', '全自动', '全部自动执行，风险自负');

  const AgentApprovalMode(this.storageValue, this.label, this.description);

  final String storageValue;
  final String label;
  final String description;

  static AgentApprovalMode parse(String? raw) {
    for (final mode in values) {
      if (mode.storageValue == raw) return mode;
    }
    return AgentApprovalMode.ask;
  }
}

/// 工具风险级别，用于审批模式判定。
enum AgentToolRisk { read, write, destructive, shell, network }

/// 用户通过 SAF 授权的文件夹。
class AgentGrantedFolder {
  const AgentGrantedFolder({required this.uri, required this.name});

  final String uri;
  final String name;

  Map<String, dynamic> toJson() => {'uri': uri, 'name': name};

  static AgentGrantedFolder? fromJson(Object? value) {
    if (value is! Map) return null;
    final uri = value['uri'];
    final name = value['name'];
    if (uri is! String || uri.isEmpty) return null;
    return AgentGrantedFolder(
      uri: uri,
      name: name is String && name.trim().isNotEmpty ? name.trim() : '已授权文件夹',
    );
  }

  static String encodeList(List<AgentGrantedFolder> folders) =>
      jsonEncode(folders.map((f) => f.toJson()).toList());

  static List<AgentGrantedFolder> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .map(AgentGrantedFolder.fromJson)
          .whereType<AgentGrantedFolder>()
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
