/// 透明 Live2D WebView 组件（聊天悬浮层与试衣间共用）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../data/pet_controller_webview.dart';

class PetWebView extends StatefulWidget {
  final PetControllerWebview controller;
  final String entryJsonPath;

  const PetWebView({
    super.key,
    required this.controller,
    required this.entryJsonPath,
  });

  @override
  State<PetWebView> createState() => _PetWebViewState();
}

class _PetWebViewState extends State<PetWebView> {
  bool _pageReady = false;

  @override
  void initState() {
    super.initState();
    // 页面 ready 后加载模型；后续事件由上层编排器消费。
    widget.controller.events.listen((e) {
      if (e.type == 'ready' && mounted && !_pageReady) {
        _pageReady = true;
        widget.controller.loadModel(widget.entryJsonPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      // 从 assets 加载宿主页；模型文件在应用文档目录，放开文件访问。
      initialFile: 'assets/pet/pet.html',
      initialSettings: InAppWebViewSettings(
        transparentBackground: true,
        allowFileAccess: true,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        mediaPlaybackRequiresUserGesture: false,
        supportZoom: false,
        disableContextMenu: true,
      ),
      onWebViewCreated: (controller) {
        widget.controller.attach(controller);
      },
    );
  }
}
