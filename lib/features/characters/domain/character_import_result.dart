/// 角色卡导入结果：供 UI 展示映射数量、保留字段与警告。
library;

import 'character.dart';

class CharacterImportResult {
  final Character character;

  /// v1 | v2 | v3
  final String format;
  final int loreCount;
  final int preservedKeyCount;
  final List<String> warnings;

  const CharacterImportResult({
    required this.character,
    required this.format,
    required this.loreCount,
    required this.preservedKeyCount,
    this.warnings = const [],
  });

  String get formatLabel => switch (format) {
    'v3' => 'V3',
    'v2' => 'V2',
    'v1' => 'V1',
    _ => format.toUpperCase(),
  };
}
