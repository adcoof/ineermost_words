/// 导出工具：RepaintBoundary 截图转 PNG + 分享面板。
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 截图像素密度。
const double kExportPixelRatio = 2;

/// 截图总像素高度守卫（逻辑高 × 像素密度的上限，防超长纹理）。
const double kExportMaxCapturePx = 4000;

/// 把挂载着 [RepaintBoundary] 的子树渲染成 PNG 字节。
///
/// 超长子树（>4000px@2x）自动降 pixelRatio 缩放整图（宁可小不可炸纹理）。
Future<Uint8List?> capturePng(GlobalKey boundaryKey) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return null;
  var ratio = kExportPixelRatio;
  final projected = boundary.size.height * ratio;
  if (projected > kExportMaxCapturePx) {
    ratio = kExportMaxCapturePx / projected;
  }
  final image = await boundary.toImage(pixelRatio: ratio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}

/// PNG 字节写入临时文件并拉起系统分享面板。
Future<void> sharePngBytes(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], title: fileName),
  );
}

/// 已落盘文件分享（如 .docx）。
Future<void> shareFilePath(String path, String fileName) async {
  await SharePlus.instance.share(
    ShareParams(files: [XFile(path)], title: fileName),
  );
}
