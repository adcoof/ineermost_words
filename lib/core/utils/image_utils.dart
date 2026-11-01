/// 附图降采样：发图前等比缩到长边上限并转 JPEG，控制 base64 载荷体积。
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 附图降采样上限（长边像素）。
const int kMaxImageDim = 1280;

/// 解码图片、等比缩到长边 <= [maxDim]、重编码 JPEG。
///
/// 解码失败原样返回（保底不丢图）；小图不放大。
Uint8List downscaleToJpeg(
  Uint8List bytes, {
  int maxDim = kMaxImageDim,
  int quality = 85,
}) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    var image = decoded;
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > maxDim) {
      // copyResize 单维入参按比例缩放。
      image = image.width >= image.height
          ? img.copyResize(image, width: maxDim)
          : img.copyResize(image, height: maxDim);
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  } catch (_) {
    return bytes;
  }
}
