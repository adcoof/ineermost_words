/// 桌宠模型导入：zip 解压到应用文档目录并解析 model3.json。
///
/// 只支持 Cubism 3/4（.moc3 + model3.json）；Cubism 2（.moc）明确拒绝。
/// 解压带 zip-slip 防护：拒绝越界路径与符号链接语义的条目。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/id.dart';
import '../domain/pet_model.dart';

class PetModelImporter {
  /// 解压并解析模型 zip，返回入库用的 [PetModel]（文件已落盘）。
  ///
  /// [baseDir] 仅供测试注入根目录；缺省用应用文档目录。
  /// [idOverride] 指定固定 id（内置默认桌宠种子用 'haru'，幂等判定）。
  Future<PetModel> importZip(
    Uint8List zipBytes, {
    String? nameOverride,
    String? baseDir,
    String? idOverride,
  }) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final id = idOverride ?? newId();
    final base = baseDir ?? (await getApplicationDocumentsDirectory()).path;
    final root = Directory(p.join(base, 'pets', id));
    await root.create(recursive: true);

    // 解压（zip-slip 防护：路径必须落在 root 内）。
    final rootPrefix = p.normalize(root.path) + p.separator;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final destPath = p.normalize(
        p.join(root.path, entry.name.replaceAll('\\', '/')),
      );
      if (!destPath.startsWith(rootPrefix)) {
        throw const ParseException('模型包内含非法路径，已拒绝导入');
      }
      final dest = File(destPath);
      await dest.parent.create(recursive: true);
      final content = entry.content as List<int>;
      await dest.writeAsBytes(content, flush: true);
    }

    // 找 model3.json（最浅路径优先，跳过 __MACOSX 等）。
    final modelFiles =
        archive
            .where(
              (e) =>
                  e.isFile &&
                  e.name.toLowerCase().endsWith('.model3.json') &&
                  !e.name.contains('__MACOSX'),
            )
            .toList()
          ..sort(
            (a, b) =>
                a.name.split('/').length.compareTo(b.name.split('/').length),
          );
    if (modelFiles.isEmpty) {
      throw const ParseException('未找到 model3.json（仅支持 Cubism 3/4 的 .moc3 模型包）');
    }
    final entryRel = modelFiles.first.name.replaceAll('\\', '/');
    final entryAbs = p.join(root.path, entryRel);

    // 剥离动作的 Sound 引用：模型包常缺音效文件，且缺失会让播放库
    // 报错中断动作；应用的声音域由 TTS 负责。
    _stripMotionSounds(File(entryAbs));

    final spec = _parseModel3(File(entryAbs));

    return PetModel(
      id: id,
      name: (nameOverride?.trim().isNotEmpty ?? false)
          ? nameOverride!.trim()
          : p.basenameWithoutExtension(p.basenameWithoutExtension(entryRel)),
      dirPath: root.path,
      entryJsonPath: entryAbs,
      expressions: spec.expressions,
      motionGroups: spec.motionGroups,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 移除 model3.json 中所有动作条目的 Sound 键并写回。
  void _stripMotionSounds(File file) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(file.readAsBytesSync()));
    } catch (_) {
      return; // 解析失败留给 _parseModel3 报错。
    }
    if (json is! Map<String, dynamic>) return;
    final refs = json['FileReferences'];
    if (refs is! Map) return;
    final motions = refs['Motions'];
    if (motions is! Map) return;
    var changed = false;
    motions.forEach((_, value) {
      if (value is! List) return;
      for (final m in value) {
        if (m is Map && m.containsKey('Sound')) {
          m.remove('Sound');
          changed = true;
        }
      }
    });
    if (changed) {
      file.writeAsStringSync(jsonEncode(json));
    }
  }

  _Model3Spec _parseModel3(File file) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(file.readAsBytesSync()));
    } catch (e) {
      throw ParseException('model3.json 解析失败', e);
    }
    if (json is! Map<String, dynamic>) {
      throw const ParseException('model3.json 顶层必须是对象');
    }
    final refs = json['FileReferences'];
    if (refs is! Map || refs['Moc'] is! String) {
      throw const ParseException('model3.json 缺少 FileReferences.Moc');
    }

    // Expressions / Motions 均在 FileReferences 下（Cubism 规范）。
    final expressions = <String>[];
    final rawExpressions = refs['Expressions'];
    if (rawExpressions is List) {
      for (final e in rawExpressions) {
        if (e is! Map) continue;
        final name = e['Name'] is String
            ? e['Name'] as String
            : e['File'] is String
            ? p.basenameWithoutExtension(e['File'] as String)
            : null;
        if (name != null && name.isNotEmpty && !expressions.contains(name)) {
          expressions.add(name);
        }
      }
    }

    final motionGroups = <String, int>{};
    final motions = (refs['Motions'] is Map)
        ? refs['Motions'] as Map
        : const {};
    motions.forEach((key, value) {
      if (value is List) motionGroups[key.toString()] = value.length;
    });

    return _Model3Spec(expressions, motionGroups);
  }
}

class _Model3Spec {
  final List<String> expressions;
  final Map<String, int> motionGroups;

  const _Model3Spec(this.expressions, this.motionGroups);
}
