/// 裁剪页冒烟测试：不同原图比例 + 目标比例下点「完成」都必须裁出字节。
///
/// 回归背景（v8.1 真机）：crop_your_image 把裁剪框换算成图片坐标时只对
/// left/top 做 clamp，右边/下边越界会抛 InvalidRectException，界面表现为
/// "裁剪失败，请换一张图片"。
library;

import 'dart:typed_data';

import 'package:ai_roleplay_chat/features/characters/presentation/image_crop_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// 造一张纯色 PNG（避免依赖测试资源文件）。
Uint8List makePng(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(80, 120, 200));
  return Uint8List.fromList(img.encodePng(image));
}

Future<Uint8List?> runCrop(
  WidgetTester tester, {
  required Uint8List png,
  required double aspectRatio,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  Uint8List? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<Uint8List>(
                  MaterialPageRoute(
                    builder: (_) => ImageCropPage(
                      imageBytes: png,
                      aspectRatio: aspectRatio,
                    ),
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500)); // 路由转场
  // 图片解析跑在 compute（真 isolate）里，必须在 runAsync 中等待；
  // 「完成」在解析完成前是禁用的，轮询到它可用为止。
  for (var i = 0; i < 60; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '完成'),
    );
    if (button.onPressed != null) break;
  }
  await tester.pumpAndSettle();

  await tester.tap(find.text('完成'));
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
  return result;
}

void main() {
  // 回归背景（v8.2 真机）：初始框曾按"图片铺满后的覆盖区域"计算，
  // 竖图放在横屏上时 1:1 方框高达 1918px、视口只有 1144px，四条边框都在
  // 屏幕外 —— 裁剪页看起来就是一整张图没有裁剪框。
  group('initialCropRect 永远落在视口内', () {
    const viewports = [
      Size(1920, 1144), // MuMu 横屏（真机复现现场）
      Size(360, 780), // 普通竖屏
      Size(780, 360),
    ];
    const ratios = [1.0, 0.46, 1.6, 9 / 16, 3 / 4];

    for (final vp in viewports) {
      for (final ratio in ratios) {
        test('视口 ${vp.width}x${vp.height} + 比例 $ratio', () {
          final rect = initialCropRect(
            Rect.fromLTWH(0, 0, vp.width, vp.height),
            ratio,
          );
          expect(rect.width / rect.height, closeTo(ratio, 0.01));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(vp.width));
          expect(rect.bottom, lessThanOrEqualTo(vp.height));
          expect(rect.width, greaterThan(0));
        });
      }
    }

    test('1:1 在横屏上取短边、居中并留出边距', () {
      final rect = initialCropRect(const Rect.fromLTWH(0, 0, 1920, 1144), 1);
      expect(rect.height, closeTo(1144 - kInitialCropInset * 2, 0.01));
      expect(rect.width, closeTo(1144 - kInitialCropInset * 2, 0.01));
      expect(rect.center.dx, closeTo(960, 0.01));
      expect(rect.center.dy, closeTo(572, 0.01));
    });
  });

  testWidgets('横图 + 竖屏比例：裁剪成功并落到图片像素内', (tester) async {
    final png = makePng(1600, 900);
    final result = await runCrop(tester, png: png, aspectRatio: 0.46);
    expect(result, isNotNull);
    final cropped = img.decodeImage(result!);
    expect(cropped, isNotNull);
    expect(cropped!.width, lessThanOrEqualTo(1600));
    expect(cropped.height, lessThanOrEqualTo(900));
    expect(cropped.width, greaterThan(0));
    expect(cropped.height, greaterThan(0));
    // 宽高比应接近目标比例（允许边界内缩导致的 1~2px 误差）。
    expect(cropped.width / cropped.height, closeTo(0.46, 0.03));
  });

  testWidgets('竖图 + 1:1：裁剪成功且结果是正方形', (tester) async {
    final png = makePng(900, 1600);
    final result = await runCrop(tester, png: png, aspectRatio: 1);
    expect(result, isNotNull);
    final cropped = img.decodeImage(result!);
    expect(cropped, isNotNull);
    expect(cropped!.width, closeTo(cropped.height.toDouble(), 2));
  });

  testWidgets('极端竖长图 + 横向比例：不崩、仍能裁剪', (tester) async {
    final png = makePng(400, 2000);
    final result = await runCrop(tester, png: png, aspectRatio: 1.8);
    expect(result, isNotNull);
    final cropped = img.decodeImage(result!);
    expect(cropped, isNotNull);
    expect(cropped!.width, greaterThan(0));
  });
}
