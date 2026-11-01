/// downscaleToJpeg：等比缩放、JPEG 重编码、坏字节透传。
library;

import 'dart:typed_data';

import 'package:ai_roleplay_chat/core/utils/image_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  Uint8List makePng(int w, int h) =>
      Uint8List.fromList(img.encodePng(img.Image(width: w, height: h)));

  test('大图等比缩到长边 1280 并转 JPEG', () {
    final out = downscaleToJpeg(makePng(2000, 1000));
    expect(out.sublist(0, 2), [0xFF, 0xD8]); // JPEG 魔数
    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, 1280);
    expect(decoded.height, 640);
  });

  test('竖图按高缩放', () {
    final out = downscaleToJpeg(makePng(800, 1600));
    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, 640);
    expect(decoded.height, 1280);
  });

  test('小图不放大，长边不变仍转 JPEG', () {
    final out = downscaleToJpeg(makePng(300, 200));
    expect(out.sublist(0, 2), [0xFF, 0xD8]);
    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, 300);
    expect(decoded.height, 200);
  });

  test('解码失败：原样返回不丢图', () {
    final bad = Uint8List.fromList([1, 2, 3, 4, 5]);
    expect(downscaleToJpeg(bad), same(bad));
  });
}
