/// Agent 对话控制器：单轮内循环「模型 → 工具 → 模型」，最多 N 步。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/token_estimate.dart';
import '../../chat/data/chat_api_client.dart';
import '../../settings/data/api_profile_repository.dart';
import '../../settings/data/app_settings_repository.dart';
import '../data/agent_repository.dart';
import '../data/device_gateway.dart';
import '../data/saf_gateway.dart';
import '../domain/agent_approval.dart';
import '../domain/agent_usage.dart';
import 'agent_tools.dart';

/// 等待用户确认的工具调用。
class AgentPendingAction {
  const AgentPendingAction({
    required this.call,
    required this.title,
    required this.detail,
    required this.risk,
  });

  final ApiToolCall call;
  final String title;
  final String detail;
  final AgentToolRisk risk;
}

/// 兼容旧 UI 的写入确认对象。
class AgentPendingWrite {
  final String path;
  final String content;

  const AgentPendingWrite({required this.path, required this.content});

  int get chars => content.runes.length;
}

/// 页面级 Agent 控制器（每个会话页一个，随页面 dispose）。
class AgentController extends ChangeNotifier {
  AgentController({
    required this.repo,
    required this.api,
    required this.profiles,
    required this.settings,
    required this.workspace,
    SafGateway? saf,
    DeviceGateway? device,
  }) {
    tools = AgentToolExecutor(
      workspace: workspace,
      saf: saf,
      device: device,
      grantedFolders: () async => effectiveGrantedFolders,
      httpDomains: settings.agentHttpDomains,
    );
  }

  final AgentSessionRepository repo;
  final ChatApiClient api;
  final ApiProfileRepository profiles;
  final AppSettingsRepository settings;
  final AgentWorkspace workspace;
  late final AgentToolExecutor tools;

  String? _sessionId;
  bool _sending = false;
  String? _errorText;
  AgentPendingAction? _pendingAction;
  Completer<bool>? _actionCompleter;
  AgentApprovalMode _approvalMode = AgentApprovalMode.ask;
  AgentApprovalMode _globalApprovalMode = AgentApprovalMode.ask;
  AgentApprovalMode? _sessionApprovalMode;
  List<AgentGrantedFolder> _globalGrantedFolders = const [];
  List<AgentGrantedFolder>? _sessionGrantedFolders;
  AgentUsage? _contextUsage;
  CancelToken? _cancelToken;
  StringBuffer? _streamBuf;
  String? _streamAssistantId;
  int _step = 0;
  int _maxSteps = kAgentMaxStepsDefault;
  bool _supportWarningShown = false;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String? get sessionId => _sessionId;
  bool get sending => _sending;
  String? get errorText => _errorText;
  AgentPendingAction? get pendingAction => _pendingAction;
  AgentPendingWrite? get pendingWrite {
    final action = _pendingAction;
    if (action == null || action.call.name != 'write_file') return null;
    final args = _decodeArgs(action.call.arguments);
    return AgentPendingWrite(
      path: args['path']?.toString() ?? '',
      content: args['content']?.toString() ?? '',
    );
  }

  AgentApprovalMode get approvalMode => _approvalMode;

  /// 设置页里的默认审批模式（会话未覆盖时生效）。
  AgentApprovalMode get defaultApprovalMode => _globalApprovalMode;

  /// 会话级覆盖；null 表示跟随默认。
  AgentApprovalMode? get sessionApprovalMode => _sessionApprovalMode;

  /// 当前会话实际可用的授权文件夹。
  List<AgentGrantedFolder> get effectiveGrantedFolders =>
      _sessionGrantedFolders ?? _globalGrantedFolders;

  /// 会话级授权文件夹；null 表示跟随默认。
  List<AgentGrantedFolder>? get sessionGrantedFolders => _sessionGrantedFolders;

  AgentUsage? get contextUsage => _contextUsage;
  int get step => _step;
  int get maxSteps => _maxSteps;

  void attach(String sessionId) {
    _sessionId = sessionId;
    _errorText = null;
    _step = 0;
    _notify();
    unawaited(_loadSessionContext());
  }

  Future<void> _loadSessionContext() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final session = await repo.getSession(sessionId);
    _sessionApprovalMode = session?.approvalMode;
    _sessionGrantedFolders = session?.grantedFolders;
    _globalApprovalMode = await settings.agentApprovalMode();
    _globalGrantedFolders = await settings.agentGrantedFolders();
    _approvalMode = _sessionApprovalMode ?? _globalApprovalMode;
    _maxSteps = await settings.agentMaxSteps();
    _notify();
    await _refreshUsage();
  }

  /// 会话内修改审批模式；null = 恢复跟随设置页默认。
  Future<void> setSessionApprovalMode(AgentApprovalMode? mode) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    await repo.setSessionApprovalMode(sessionId, mode);
    _sessionApprovalMode = mode;
    _approvalMode = mode ?? _globalApprovalMode;
    _notify();
    await _refreshUsage();
  }

  /// 会话内修改授权文件夹；null = 恢复跟随设置页默认。
  Future<void> setSessionGrantedFolders(
    List<AgentGrantedFolder>? folders,
  ) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    await repo.setSessionGrantedFolders(sessionId, folders);
    _sessionGrantedFolders = folders;
    _notify();
  }

  void clearError() {
    if (_errorText == null) return;
    _errorText = null;
    _notify();
  }

  /// 发送一条用户消息；内部完成整个工具循环。
  Future<void> send(String raw) async {
    if (_sending) return;
    final sessionId = _sessionId;
    final text = raw.trim();
    if (sessionId == null || text.isEmpty) return;

    _sending = true;
    _errorText = null;
    _step = 0;
    _notify();

    final token = CancelToken();
    _cancelToken = token;
    try {
      final session = await repo.getSession(sessionId);
      await repo.insertMessage(
        sessionId: sessionId,
        role: 'user',
        content: text,
      );
      if (session != null && session.title == '新 Agent 会话') {
        await repo.renameSession(sessionId, _titleFrom(text));
      }

      final profile = await profiles.getDefault();
      if (profile == null) {
        _errorText = '请先在设置中配置 API 供应商';
        return;
      }
      final autoWrite = await settings.agentAutoWrite();
      _sessionApprovalMode = session?.approvalMode;
      _sessionGrantedFolders = session?.grantedFolders;
      _globalApprovalMode = await settings.agentApprovalMode();
      _globalGrantedFolders = await settings.agentGrantedFolders();
      _approvalMode = _sessionApprovalMode ?? _globalApprovalMode;
      _maxSteps = await settings.agentMaxSteps();
      final window = await settings.agentContextWindowTokens();
      final baseSystem = _systemPrompt();
      final built = await _buildHistory(
        sessionId,
        system: baseSystem,
        windowTokens: window,
      );
      var system = baseSystem;
      final history = built.messages;
      if (built.summary.isNotEmpty) {
        system = '$baseSystem\n\n${built.summary}';
        _trimToBudget(history, _historyLimit(window, system));
      }
      _contextUsage = _usageFor(system, history, window);
      _notify();

      for (var step = 0; step < _maxSteps; step++) {
        _step = step + 1;
        _notify();
        if (token.isCancelled) throw const CancelledException();

        // 工具结果会持续追加，每一步都按“系统提示 + 工具定义 + 历史”的
        // 剩余预算重新裁剪，避免多步调用把窗口挤爆。
        _trimToBudget(history, _historyLimit(window, system));

        final assistant = await repo.insertMessage(
          sessionId: sessionId,
          role: 'assistant',
          status: 'streaming',
        );
        final buf = StringBuffer();
        _streamBuf = buf;
        _streamAssistantId = assistant.id;
        var calls = const <ApiToolCall>[];
        var lastFlush = DateTime.now();

        final stream = api.streamChat(
          profile: profile,
          messages: [
            ApiMessage(role: 'system', content: system),
            ...history,
          ],
          tools: kAgentTools,
          cancelToken: token,
        );
        await for (final delta in stream) {
          if (token.isCancelled) throw const CancelledException();
          if (delta.content != null && delta.content!.isNotEmpty) {
            buf.write(delta.content);
          }
          if (delta.toolCalls != null && delta.toolCalls!.isNotEmpty) {
            calls = delta.toolCalls!;
          }
          if (DateTime.now().difference(lastFlush) >=
              const Duration(milliseconds: 250)) {
            lastFlush = DateTime.now();
            await repo.updateMessage(assistant.id, content: buf.toString());
          }
        }

        final out = buf.toString().trim();
        if (calls.isEmpty) {
          if (out.isEmpty) {
            await repo.deleteMessage(assistant.id);
            _errorText = '模型没有返回内容，请重试';
          } else {
            await repo.updateMessage(
              assistant.id,
              content: out,
              status: 'done',
            );
          }
          _streamBuf = null;
          _streamAssistantId = null;
          break;
        }

        await repo.updateMessage(
          assistant.id,
          content: out,
          toolCalls: calls,
          status: 'done',
        );
        history.add(
          ApiMessage(role: 'assistant', content: out, toolCalls: calls),
        );
        _streamBuf = null;
        _streamAssistantId = null;

        for (final call in calls) {
          if (token.isCancelled) throw const CancelledException();
          final result = await _runTool(
            call,
            autoWrite: autoWrite,
            token: token,
          );
          await repo.insertMessage(
            sessionId: sessionId,
            role: 'tool',
            content: result,
            toolCallId: call.id,
            toolName: call.name,
          );
          history.add(
            ApiMessage(
              role: 'tool',
              content: result,
              toolCallId: call.id,
              name: call.name,
            ),
          );
        }

        if (step == _maxSteps - 1) {
          _errorText = '已达到最大工具步数（$_maxSteps），请继续追问或调大上限';
        }
      }
    } on CancelledException {
      await _finalizePartial('done');
    } on AgentToolsUnsupportedException catch (e) {
      _errorText = e.message;
      _supportWarningShown = true;
      await _finalizePartial('error');
    } on AppException catch (e) {
      _errorText = e.message;
      await _finalizePartial('error');
    } catch (e) {
      _errorText = 'Agent 请求失败：$e';
      await _finalizePartial('error');
    } finally {
      _sending = false;
      _cancelToken = null;
      _streamBuf = null;
      _streamAssistantId = null;
      _pendingAction = null;
      _actionCompleter = null;
      _notify();
    }
  }

  /// 用户确认待执行动作。
  void confirmAction() {
    final completer = _actionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(true);
    }
  }

  void rejectAction() {
    final completer = _actionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }
  }

  /// 兼容旧调用。
  void confirmWrite() => confirmAction();
  void rejectWrite() => rejectAction();

  /// 停止生成（流中断；已执行的写入不回滚）。
  void stop() {
    _cancelToken?.cancel('用户停止');
  }

  bool get toolsUnsupported => _supportWarningShown;

  bool _shouldAsk(AgentToolRisk risk, {required bool autoWrite}) {
    switch (_approvalMode) {
      case AgentApprovalMode.full:
        return false;
      case AgentApprovalMode.auto:
        return risk == AgentToolRisk.destructive ||
            risk == AgentToolRisk.shell ||
            risk == AgentToolRisk.network;
      case AgentApprovalMode.ask:
        if (risk == AgentToolRisk.write && autoWrite) return false;
        return true;
    }
  }

  Future<String> _runTool(
    ApiToolCall call, {
    required bool autoWrite,
    required CancelToken token,
  }) async {
    final risk = tools.riskFor(call.name);
    if (_shouldAsk(risk, autoWrite: autoWrite)) {
      final ok = await _askAction(call, risk, token);
      if (!ok) {
        return jsonEncode({'ok': false, 'error': '用户拒绝执行'});
      }
    }
    return tools.execute(call);
  }

  String _actionTitle(AgentToolRisk risk) {
    switch (risk) {
      case AgentToolRisk.read:
        return '读取确认';
      case AgentToolRisk.write:
        return '写入文件确认';
      case AgentToolRisk.destructive:
        return '文件变更确认';
      case AgentToolRisk.shell:
        return '执行命令确认';
      case AgentToolRisk.network:
        return '网络请求确认';
    }
  }

  Future<bool> _askAction(
    ApiToolCall call,
    AgentToolRisk risk,
    CancelToken token,
  ) {
    _pendingAction = AgentPendingAction(
      call: call,
      title: _actionTitle(risk),
      detail: tools.describe(call),
      risk: risk,
    );
    _notify();
    final completer = Completer<bool>();
    _actionCompleter = completer;
    token.whenCancel.then((_) {
      if (!completer.isCompleted) completer.complete(false);
    });
    return completer.future.whenComplete(() {
      _pendingAction = null;
      _actionCompleter = null;
      _notify();
    });
  }

  Future<({List<ApiMessage> messages, String summary})> _buildHistory(
    String sessionId, {
    required String system,
    required int windowTokens,
  }) async {
    final rows = await repo.getMessages(sessionId);
    final out = <ApiMessage>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.role == 'user') {
        out.add(ApiMessage(role: 'user', content: row.content));
      } else if (row.role == 'assistant') {
        if (row.status == 'error') continue;
        var calls = row.toolCalls;
        if (calls.isNotEmpty) {
          final following = <String?>{};
          for (var j = i + 1;
              j < rows.length && rows[j].role == 'tool';
              j++) {
            following.add(rows[j].toolCallId);
          }
          final complete = calls.every((c) => following.contains(c.id));
          if (!complete) calls = const [];
        }
        out.add(
          ApiMessage(
            role: 'assistant',
            content: row.content,
            toolCalls: calls,
          ),
        );
      } else if (row.role == 'tool') {
        out.add(
          ApiMessage(
            role: 'tool',
            content: _clip(row.content, 4000),
            toolCallId: row.toolCallId,
            name: row.toolName,
          ),
        );
      }
    }

    final dropped = _trimToBudget(out, _historyLimit(windowTokens, system));
    return (messages: out, summary: _summarizeDropped(dropped));
  }

  /// 历史可用预算：窗口的 90% 扣除系统提示与工具定义，至少留 160 token。
  int _historyLimit(int windowTokens, String system) {
    final toolsJson = jsonEncode([
      for (final tool in kAgentTools) tool.toJson(),
    ]);
    final budget = (windowTokens * 0.9).floor();
    final reserved = estimateTokens(system) + estimateTokens(toolsJson);
    return math.max(160, budget - reserved);
  }

  /// 从最旧消息开始丢弃，保留至少 2 条；丢弃带 toolCalls 的 assistant 时
  /// 一并丢弃紧随其后的 tool 结果，保证工具协议配对。返回被丢弃的消息。
  List<ApiMessage> _trimToBudget(List<ApiMessage> out, int limit) {
    final dropped = <ApiMessage>[];
    while (out.length > 2 && _estimate(out) > limit) {
      final removed = out.removeAt(0);
      dropped.add(removed);
      if (removed.role == 'assistant' && removed.toolCalls.isNotEmpty) {
        while (out.isNotEmpty && out.first.role == 'tool') {
          dropped.add(out.removeAt(0));
        }
      }
    }
    return dropped;
  }

  /// 把被裁掉的旧消息压成一段纯文本摘要（不额外调用模型），
  /// 只保留最近的条目与要点，避免摘要本身撑爆窗口。
  String _summarizeDropped(List<ApiMessage> dropped) {
    if (dropped.isEmpty) return '';
    final lines = <String>[];
    final recent = dropped.skip(math.max(0, dropped.length - 24));
    for (final message in recent) {
      final text = message.content.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (text.isEmpty && message.toolCalls.isEmpty) continue;
      switch (message.role) {
        case 'user':
          lines.add('用户：${_clip(text, 120)}');
        case 'assistant':
          final names = message.toolCalls.map((c) => c.name).join('、');
          final suffix = names.isEmpty ? '' : '（调用 $names）';
          lines.add('助手：${_clip(text, 100)}$suffix');
        case 'tool':
          lines.add('工具 ${message.name ?? ''}：${_clip(text, 80)}');
      }
    }
    if (lines.isEmpty) return '';
    final body = _clip(lines.join('\n'), 800);
    return '【更早对话摘要（自动压缩，仅保留要点）】\n$body';
  }

  int _estimate(List<ApiMessage> messages) {
    var total = 0;
    for (final message in messages) {
      total += 4 + estimateTokens(message.content);
      for (final call in message.toolCalls) {
        total += estimateTokens(call.name) + estimateTokens(call.arguments);
      }
    }
    return total;
  }

  AgentUsage _usageFor(
    String system,
    List<ApiMessage> history,
    int windowTokens,
  ) {
    final toolsJson = jsonEncode([
      for (final tool in kAgentTools) tool.toJson(),
    ]);
    return AgentUsage(
      systemTokens: estimateTokens(system),
      toolsTokens: estimateTokens(toolsJson),
      historyTokens: _estimate(history),
      windowTokens: windowTokens,
    );
  }

  Future<void> _refreshUsage() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final baseSystem = _systemPrompt();
    final window = await settings.agentContextWindowTokens();
    final built = await _buildHistory(
      sessionId,
      system: baseSystem,
      windowTokens: window,
    );
    final system = built.summary.isEmpty
        ? baseSystem
        : '$baseSystem\n\n${built.summary}';
    if (built.summary.isNotEmpty) {
      _trimToBudget(built.messages, _historyLimit(window, system));
    }
    _contextUsage = _usageFor(system, built.messages, window);
    _notify();
  }

  Future<void> _finalizePartial(String status) async {
    final id = _streamAssistantId;
    final buf = _streamBuf;
    if (id == null) return;
    if (buf != null && buf.toString().trim().isNotEmpty) {
      await repo.updateMessage(
        id,
        content: buf.toString().trim(),
        status: status,
      );
    } else {
      await repo.deleteMessage(id);
    }
  }

  String _systemPrompt() {
    final mode = _approvalMode.label;
    final roots = [
      '工作区',
      for (final folder in effectiveGrantedFolders) folder.name,
    ].join('、');
    return '你是「心语」的本地 Agent，可以读写用户授权的文件、执行 shell 命令、联网搜索与发起 HTTP 请求。\n'
        '工作区根目录：${workspace.rootPath}\n'
        '当前可用根：$roots\n'
        '审批模式：$mode。高风险动作（删除/移动/命名/命令/联网）可能需要用户确认；被拒绝时不要重试同一动作。\n'
        '规则：\n'
        '1. 文件操作先用 list_roots 查看可用根，再用相对路径；禁止绝对路径与 ..。\n'
        '2. 写文件前先用 read_file 确认现有内容，不要覆盖不想改的文件。\n'
        '3. 删除/移动/重命名前先确认目标存在，宁可多问一句。\n'
        '4. shell 命令只做必要操作，不要执行 su、reboot、抹机等危险命令。\n'
        '5. 需要查资料/新闻/实时信息时用 web_search，不要凭记忆编造；搜索结果要注明来源链接。\n'
        '6. HTTP 只访问公网地址，不要访问内网/本机；请求失败如实说明。\n'
        '7. 操作手机时：先用 device_status 查看 Shizuku/无障碍是否可用；device_shell 可执行 input tap/swipe、am start、screencap 等；device_click_text 可按屏幕文字点击；device_ui_text 可读取当前界面文字。\n'
        '8. 不要用 device_shell 做 su、reboot、清数据等危险操作；点击/输入前先确认当前界面。\n'
        '9. 工具失败时如实告知，不要假装成功；不要编造文件内容。\n'
        '10. 最终回答用中文，简洁扼要。';
  }

  String _titleFrom(String text) {
    final oneLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final runes = oneLine.runes.toList();
    if (runes.length <= 20) return oneLine;
    return '${String.fromCharCodes(runes.take(20))}…';
  }

  Map<String, dynamic> _decodeArgs(String raw) {
    try {
      final decoded = jsonDecode(raw.isEmpty ? '{}' : raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }

  String _clip(String value, int max) {
    if (value.length <= max) return value;
    final head = (max * 0.6).floor();
    final tail = max - head - 1;
    return '${value.substring(0, head)}…'
        '${value.substring(value.length - tail)}';
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelToken?.cancel('页面关闭');
    super.dispose();
  }
}
