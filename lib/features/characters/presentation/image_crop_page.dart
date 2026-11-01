/// 通用图片裁剪页（v8）：会话背景板（自由比例）与角色头像（1:1）共用。
///
/// 选图字节进、裁剪后 JPEG 字节出；crop_your_image 纯 Flutter 实现。
library;

import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class ImageCropPage extends StatefulWidget {
  final Uint8List imageBytes;

  /// 裁剪框初始宽高比；null=自由比例。
  final double? aspectRatio;

  final String title;

  const ImageCropPage({
    super.key,
    required this.imageBytes,
    this.aspectRatio,
    this.title = '裁剪',
  });

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  final _controller = CropController();
  var _cropping = false;

  /// 图片解析完成才允许裁剪：库在解析完成前调用 crop() 会断言崩溃。
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: (!_ready || _cropping)
                ? null
                : () {
                    setState(() => _cropping = true);
                    _controller.crop();
                  },
            child: const Text('完成'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Crop(
        controller: _controller,
        image: widget.imageBytes,
        aspectRatio: widget.aspectRatio,
        // 允许双指缩放/拖动图片：裁剪背景或立绘时常常要先放大取局部。
        // 库内部保证缩放/拖动后图片仍覆盖裁剪框，裁剪不会越界。
        interactive: true,
        // 固定比例时把初始框铺成**视口内**最大的等比矩形（v8.1）：
        // crop_your_image 的默认初始框按图片自身尺寸推算，横图放在竖屏上
        // 会得到一个小方框，用户很容易以为"只能裁正方形"。
        initialRectBuilder: widget.aspectRatio == null
            ? null
            : InitialRectBuilder.withBuilder(_initialRect),
        maskColor: Colors.black.withValues(alpha: 0.6),
        onStatusChanged: (status) {
          if (!mounted) return;
          final ready = status == CropStatus.ready;
          if (ready != _ready) setState(() => _ready = ready);
        },
        onCropped: (result) {
          if (!mounted) return;
          if (result is CropSuccess) {
            Navigator.pop(context, result.croppedImage);
          } else {
            setState(() => _cropping = false);
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('裁剪失败，请换一张图片')));
          }
        },
      ),
    );
  }

  /// 视口内最大的等比矩形（居中）。
  ///
  /// 必须夹在**视口**里，而不是"图片铺满后的覆盖区域"（v8.1 真机回归）：
  /// [Crop.interactive] 会按 scaleToCover 把图片放大到盖住视口，覆盖区域
  /// 常常比视口大（竖图铺在横屏上，覆盖高 2560px 而视口只有 1144px），
  /// 在覆盖区域里取最大的 1:1 方框会得到 1918px —— 四条边框全在屏幕外，
  /// 页面上看起来就是一整张图没有裁剪框，点「完成」还会裁走屏幕外的部分。
  ///
  /// 覆盖区域按定义一定包含视口，所以以视口为界既保证框可见，也保证框
  /// 落在图片里：库把裁剪框换算成图片坐标时只对 left/top 做 clamp
  /// （crop_editor_view_state.rectToCrop），右/下越界会抛
  /// InvalidRectException、界面报"裁剪失败"。
  Rect _initialRect(Rect viewport, Rect imageRect) {
    if (imageRect.width <= 0 || imageRect.height <= 0) return imageRect;
    return initialCropRect(viewport, widget.aspectRatio!);
  }
}

/// 初始裁剪框与视口边缘的留白。
///
/// 1px 就够避开浮点误差，但裁剪框四角的手柄是画在框角上的：框紧贴视口
/// 边缘时手柄会被 AppBar / 屏幕边切掉一半，看起来像"框没画完"。留 12px
/// 让四角都完整可见，也露出一圈遮罩，一眼能看出哪块是要裁的区域。
const double kInitialCropInset = 12;

/// 视口内最大的、宽高比为 [aspectRatio] 的居中矩形。
///
/// 单独抽出来是为了能直接断言"永不越出视口"——按"图片铺满后的覆盖区域"
/// 算会把头像裁剪框做到屏幕外。
Rect initialCropRect(Rect viewport, double aspectRatio) {
  final bounds = Rect.fromLTWH(
    0,
    0,
    viewport.width,
    viewport.height,
  ).deflate(kInitialCropInset);
  var w = bounds.width;
  var h = w / aspectRatio;
  if (h > bounds.height) {
    h = bounds.height;
    w = h * aspectRatio;
  }
  return Rect.fromLTWH(
    bounds.left + (bounds.width - w) / 2,
    bounds.top + (bounds.height - h) / 2,
    w,
    h,
  );
}
