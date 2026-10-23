/// 桌宠 WebView 控制器：Dart ⇄ pet_host.js 桥。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 桌宠回报的用户/生命周期事件。
class PetUserEvent {
  /// ready | loaded | error | tap
  final String type;
  final String? message;

  const PetUserEvent(this.type, {this.message});
}

/// 抽象桌宠控制器（WebView 实现；测试可替换为假实现）。
abstract class PetController {
  Stream<PetUserEvent> get events;

  Future<void> loadModel(String entryJsonPath);

  Future<void> setExpression(String expressionId);

  Future<void> startMotion(String group, {int index = 0, int priority = 1});

  Future<void> setLipSync(double value);

  Future<void> setPointer(double x, double y);
}

/// flutter_inappwebview 实现。WebView 挂载后调用 [attach]。
class PetControllerWebview implements PetController {
  InAppWebViewController? _web;
  final _events = StreamController<PetUserEvent>.broadcast();

  /// WebView 尚未就绪时暂存的指令（如模型加载早于页面 ready）。
  final List<Future<void> Function(InAppWebViewController)> _pending = [];

  @override
  Stream<PetUserEvent> get events => _events.stream;

  /// 由 WebView 的 onWebViewCreated 调用，并注册 JS handler。
  void attach(InAppWebViewController controller) {
    _web = controller;
    controller.addJavaScriptHandler(
      handlerName: 'petBridge',
      callback: (args) {
        if (args.isEmpty) return null;
        try {
          final json = args.first;
          final map = json is String
              ? jsonDecode(json) as Map<String, dynamic>
              : Map<String, dynamic>.from(json as Map);
          _events.add(PetUserEvent(
            map['event']?.toString() ?? 'unknown',
            message: map['message']?.toString(),
          ));
        } catch (_) {
          // 忽略无法解析的回报。
        }
        return null;
      },
    );
    final pending = [..._pending];
    _pending.clear();
    for (final action in pending) {
      action(controller);
    }
  }

  void _eval(String script) {
    final web = _web;
    if (web == null) {
      _pending.add((c) async {
        await c.evaluateJavascript(source: script);
      });
      return;
    }
    // ignore: discarded_futures
    web.evaluateJavascript(source: script);
  }

  static String _q(String s) => jsonEncode(s);

  @override
  Future<void> loadModel(String entryJsonPath) async {
    _eval('window.petHost && petHost.loadModel(${_q('file://$entryJsonPath')});');
  }

  @override
  Future<void> setExpression(String expressionId) async {
    _eval('window.petHost && petHost.setExpression(${_q(expressionId)});');
  }

  @override
  Future<void> startMotion(String group, {int index = 0, int priority = 1}) async {
    _eval('window.petHost && petHost.startMotion(${_q(group)}, $index, $priority);');
  }

  @override
  Future<void> setLipSync(double value) async {
    _eval('window.petHost && petHost.setLipSync($value);');
  }

  @override
  Future<void> setPointer(double x, double y) async {
    _eval('window.petHost && petHost.setPointer($x, $y);');
  }

  void dispose() {
    _events.close();
  }
}
