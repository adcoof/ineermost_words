/// 液态玻璃组件（v8）：BackdropFilter 真模糊 + 半透明填充 + 渐变高光描边。
///
/// 铁律：
/// - 每个玻璃元素一层模糊，必须 ClipRect 显式裁剪，尺寸固定，不嵌套；
/// - 只用于固定位置的栏/卡（AppBar、导航栏、输入栏、弹层）；
/// - **滚动中的消息气泡/卡片绝不逐个模糊**——只用半透明填充 + 渐变描边
///   （见 [glassBubbleDecoration]），模糊开销由背景层/固定栏承担。
library;

import 'dart:ui';

import 'package:flutter/material.dart';

/// 玻璃面板：裁剪 → 背景模糊 → 半透明填充 + 1px 渐变高光描边 + 柔和阴影。
class GlassPanel extends StatelessWidget {
  final Widget? child;

  /// 模糊标准差（越大越朦胧）。
  final double blur;

  final BorderRadius radius;

  /// 填充不透明度（白 0.06~0.10 = 轻玻璃；深色底可略高）。
  final double fillOpacity;

  final EdgeInsetsGeometry? padding;

  final List<BoxShadow>? boxShadow;

  const GlassPanel({
    super.key,
    this.child,
    this.blur = 16,
    this.radius = const BorderRadius.all(Radius.circular(16)),
    this.fillOpacity = 0.08,
    this.padding,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          // 填充用柔和渐变模拟玻璃受光；描边用 CustomPaint 画渐变高光
          //（Flutter 无内置 GradientBorder）。
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: fillOpacity + 0.04),
                Colors.white.withValues(alpha: fillOpacity),
              ],
            ),
            boxShadow:
                boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
          ),
          child: CustomPaint(
            foregroundPainter: GradientBorderPainter(radius: radius),
            child: padding == null
                ? child
                : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}

/// 1px 线性渐变描边（左上高光 → 右下隐没），模拟玻璃折射边缘。
class GradientBorderPainter extends CustomPainter {
  final BorderRadius radius;

  const GradientBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(Offset.zero & size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.42),
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.04),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect.deflate(0.5), paint);
  }

  @override
  bool shouldRepaint(GradientBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

/// 气泡/滚动卡片级「伪玻璃」装饰：半透明填充 + 渐变描边，**无模糊**。
///
/// 滚动列表里每个元素做 BackdropFilter 会在低端机掉帧，
/// 这里只做视觉上的玻璃质感，模糊交给背景板与固定栏。
Decoration glassBubbleDecoration({
  required Color base,
  double fillOpacity = 0.82,
  BorderRadius radius = const BorderRadius.all(Radius.circular(12)),
}) {
  return BoxDecoration(
    borderRadius: radius,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base.withValues(alpha: fillOpacity),
        base.withValues(alpha: fillOpacity - 0.10),
      ],
    ),
    border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1),
  );
}
