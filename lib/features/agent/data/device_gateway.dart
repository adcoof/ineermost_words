import 'package:flutter/services.dart';

/// 手机控制通道：Shizuku（shell 身份）+ 无障碍（读屏/点击）。
class DeviceStatus {
  const DeviceStatus({
    required this.shizukuAvailable,
    required this.shizukuGranted,
    required this.accessibilityEnabled,
  });

  final bool shizukuAvailable;
  final bool shizukuGranted;
  final bool accessibilityEnabled;

  bool get canShell => shizukuGranted;
  bool get canAccessibility => accessibilityEnabled;

  static const DeviceStatus none = DeviceStatus(
    shizukuAvailable: false,
    shizukuGranted: false,
    accessibilityEnabled: false,
  );
}

class DeviceShellResult {
  const DeviceShellResult({
    required this.code,
    required this.stdout,
    required this.stderr,
  });

  final int code;
  final String stdout;
  final String stderr;
}

class DeviceException implements Exception {
  const DeviceException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class DeviceGateway {
  Future<DeviceStatus> status();

  Future<void> requestShizuku();

  Future<DeviceShellResult> shell(String command);

  Future<String> uiText();

  Future<bool> clickText(String text);

  Future<void> openAccessibilitySettings();
}

class MethodChannelDeviceGateway implements DeviceGateway {
  const MethodChannelDeviceGateway();

  static const MethodChannel _channel = MethodChannel('xinyu/device');

  @override
  Future<DeviceStatus> status() async {
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('status');
      return DeviceStatus(
        shizukuAvailable: map?['shizukuAvailable'] == true,
        shizukuGranted: map?['shizukuGranted'] == true,
        accessibilityEnabled: map?['accessibilityEnabled'] == true,
      );
    } on PlatformException catch (e) {
      throw DeviceException(e.message ?? '无法读取设备权限状态');
    }
  }

  @override
  Future<void> requestShizuku() async {
    try {
      await _channel.invokeMethod<bool>('requestShizuku');
    } on PlatformException catch (e) {
      throw DeviceException(e.message ?? 'Shizuku 授权请求失败');
    }
  }

  @override
  Future<DeviceShellResult> shell(String command) async {
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('shell', {
        'command': command,
      });
      return DeviceShellResult(
        code: (map?['code'] as num?)?.toInt() ?? -1,
        stdout: (map?['stdout'] as String?) ?? '',
        stderr: (map?['stderr'] as String?) ?? '',
      );
    } on PlatformException catch (e) {
      throw DeviceException(e.message ?? '命令执行失败');
    }
  }

  @override
  Future<String> uiText() async {
    try {
      return await _channel.invokeMethod<String>('uiText') ?? '';
    } on PlatformException catch (e) {
      throw DeviceException(e.message ?? '无法读取屏幕文字');
    }
  }

  @override
  Future<bool> clickText(String text) async {
    try {
      return await _channel.invokeMethod<bool>('clickText', {'text': text}) ??
          false;
    } on PlatformException catch (e) {
      throw DeviceException(e.message ?? '点击失败');
    }
  }

  @override
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod<bool>('openAccessibilitySettings');
    } on PlatformException catch (e) {
      throw DeviceException(e.message ?? '无法打开无障碍设置');
    }
  }
}
