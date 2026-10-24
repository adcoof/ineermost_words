/// 角色圆形头像：有立绘用立绘，缺失/损坏时退化为 person 占位。
library;

import 'dart:io';

import 'package:flutter/material.dart';

class CharacterAvatar extends StatelessWidget {
  final String? avatarPath;
  final double radius;

  const CharacterAvatar({super.key, this.avatarPath, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final path = avatarPath;
    final hasImage = path != null && path.isNotEmpty && File(path).existsSync();
    // 解码失败（损坏/无 IDAT 的图）时仍保留占位底色，不出现空白。
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: hasImage ? FileImage(File(path)) : null,
      child: hasImage ? null : const Icon(Icons.person_outline),
    );
  }
}
