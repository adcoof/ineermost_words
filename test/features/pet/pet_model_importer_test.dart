import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/core/errors/app_exception.dart';
import 'package:ai_roleplay_chat/features/pet/data/pet_model_importer.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

const _model3Json = '''
{
  "Version": 3,
  "FileReferences": {
    "Moc": "Test.moc3",
    "Physics": "Test.physics3.json",
    "Motions": {
      "Idle": [{"File": "motions/idle_0.motion3.json"}, {"File": "motions/idle_1.motion3.json"}],
      "TapBody": [{"File": "motions/tap_0.motion3.json"}]
    },
    "Expressions": [
      {"Name": "f01", "File": "expressions/f01.exp3.json"},
      {"Name": "f02", "File": "expressions/f02.exp3.json"}
    ],
    "DisplayInfo": "Test.displayinfo3.json"
  }
}
''';

Uint8List _buildZip(Map<String, String> files) {
  final archive = Archive();
  files.forEach((path, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pet_import_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('PetModelImporter', () {
    test('正常 zip：解压落盘 + 解析表情/动作组', () async {
      final zip = _buildZip({
        'Test.model3.json': _model3Json,
        'Test.moc3': 'fake-moc-binary',
        'expressions/f01.exp3.json': '{}',
        'motions/idle_0.motion3.json': '{}',
      });

      final model = await PetModelImporter()
          .importZip(zip, baseDir: tempDir.path);

      expect(model.name, 'Test');
      expect(model.expressions, ['f01', 'f02']);
      expect(model.motionGroups, {'Idle': 2, 'TapBody': 1});
      expect(File(model.entryJsonPath).existsSync(), isTrue);
      expect(
          File('${model.dirPath}/motions/idle_0.motion3.json').existsSync(),
          isTrue);
    });

    test('子目录里的 model3.json 也能找到（取最浅路径）', () async {
      final zip = _buildZip({
        'Pack/Hero.model3.json': _model3Json,
        'Pack/Hero.moc3': 'x',
        '__MACOSX/junk': 'ignore',
      });
      final model =
          await PetModelImporter().importZip(zip, baseDir: tempDir.path);
      expect(model.entryJsonPath, endsWith('Pack/Hero.model3.json'));
      expect(model.name, 'Hero');
    });

    test('zip-slip 路径逃逸被拒绝', () async {
      final zip = _buildZip({
        '../evil.model3.json': _model3Json,
      });
      expect(
        () => PetModelImporter().importZip(zip, baseDir: tempDir.path),
        throwsA(isA<ParseException>()),
      );
    });

    test('没有 model3.json 报 Parse 错（并提示仅支持 moc3）', () async {
      final zip = _buildZip({'readme.txt': 'not a model'});
      expect(
        () => PetModelImporter().importZip(zip, baseDir: tempDir.path),
        throwsA(isA<ParseException>()),
      );
    });

    test('model3.json 缺 Moc 报 Parse 错', () async {
      final zip = _buildZip({
        'Bad.model3.json': '{"FileReferences": {}}',
      });
      expect(
        () => PetModelImporter().importZip(zip, baseDir: tempDir.path),
        throwsA(isA<ParseException>()),
      );
    });

    test('导入时剥离动作的 Sound 引用', () async {
      final withSound = _model3Json.replaceFirst(
        '"File": "motions/idle_0.motion3.json"',
        '"File": "motions/idle_0.motion3.json", "Sound": "../missing/x.mp3"',
      );
      final zip = _buildZip({'Test.model3.json': withSound, 'Test.moc3': 'x'});
      final model =
          await PetModelImporter().importZip(zip, baseDir: tempDir.path);
      final rewritten = File(model.entryJsonPath).readAsStringSync();
      expect(rewritten.contains('Sound'), isFalse);
      expect(rewritten.contains('idle_0'), isTrue); // 其他键不受影响
    });
  });
}
