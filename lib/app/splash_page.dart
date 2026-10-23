/// 启动过渡页：深空渐变底 + 应用图标 + 标语 + 工作室署名。
///
/// 展示约 2 秒后自动进入主界面；任意点按可跳过。
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'theme.dart';

class SplashPage extends StatefulWidget {
  /// 过渡结束后进入的主界面。
  final Widget next;

  /// 自动跳转延时（默认 2.2 秒，测试可调短）。
  final Duration duration;

  const SplashPage({
    super.key,
    required this.next,
    this.duration = const Duration(milliseconds: 2200),
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _timer = Timer(widget.duration, _go);
  }

  void _go() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.next),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _go,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B0A18), Color(0xFF1B1440), Color(0xFF0D0B1E)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  // 应用图标 + 霓虹光晕。
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 168,
                      height: 168,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.violet.withValues(alpha: 0.45),
                            blurRadius: 48,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Image.asset(
                          'assets/branding/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.favorite, size: 96),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '心语',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 10,
                      color: BrandColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '让每一次对话，都怦然心动',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 4,
                      color: BrandColors.cyan.withValues(alpha: 0.9),
                    ),
                  ),
                  const Spacer(flex: 4),
                  // 底部署名：工作室 + logo。
                  Opacity(
                    opacity: 0.85,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/branding/sigborn_logo.png',
                          width: 34,
                          height: 34,
                          errorBuilder: (_, _, _) => const Icon(
                              Icons.bolt,
                              size: 20,
                              color: BrandColors.muted),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '由奇点重现工作室制作',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            color: BrandColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
