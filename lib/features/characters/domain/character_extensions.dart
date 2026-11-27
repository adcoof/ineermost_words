/// 角色卡第三方扩展与未识别字段的只读容器。
///
/// 导入 ST 卡时，已知字段进 [Character] / [CharacterProfile]；其余全部原样
/// 收在这里，导出时再合并回去，避免「导入→导出」丢第三方数据。
library;

import 'dart:convert';

class CharacterExtensions {
  static const empty = CharacterExtensions();

  /// 原 `data.extensions` 对象。
  final Map<String, dynamic> stExtensions;

  /// 未识别的 `data` 字段。
  final Map<String, dynamic> unknownData;

  /// 未识别的根字段。
  final Map<String, dynamic> unknownRoot;

  /// 世界书（character_book）的书籍级元数据，去掉 entries 后的原文。
  /// 条目本身落在 lore_entries，导出时再与这里合并。
  final Map<String, dynamic> bookMeta;

  /// 本格式未来新增的顶层键（降级兼容）。
  final Map<String, dynamic> extra;

  const CharacterExtensions({
    this.stExtensions = const {},
    this.unknownData = const {},
    this.unknownRoot = const {},
    this.bookMeta = const {},
    this.extra = const {},
  });

  factory CharacterExtensions.fromJson(Map<String, dynamic> json) {
    final extra = <String, dynamic>{
      for (final entry in json.entries)
        if (entry.key != 'v' &&
            entry.key != 'st_extensions' &&
            entry.key != 'unknown_data' &&
            entry.key != 'unknown_root' &&
            entry.key != 'st_book_meta')
          entry.key: entry.value,
    };
    return CharacterExtensions(
      stExtensions: _readMap(json['st_extensions']),
      unknownData: _readMap(json['unknown_data']),
      unknownRoot: _readMap(json['unknown_root']),
      bookMeta: _readMap(json['st_book_meta']),
      extra: Map<String, dynamic>.unmodifiable(extra),
    );
  }

  static CharacterExtensions decode(String raw) {
    if (raw.trim().isEmpty) return empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return CharacterExtensions.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {
      // 坏数据按空扩展处理；不阻塞角色读取。
    }
    return empty;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'v': 1};
    map.addAll(extra);
    if (stExtensions.isNotEmpty) map['st_extensions'] = stExtensions;
    if (unknownData.isNotEmpty) map['unknown_data'] = unknownData;
    if (unknownRoot.isNotEmpty) map['unknown_root'] = unknownRoot;
    if (bookMeta.isNotEmpty) map['st_book_meta'] = bookMeta;
    return map;
  }

  String encode() => isEmpty ? '{}' : jsonEncode(toJson());

  bool get isEmpty =>
      stExtensions.isEmpty &&
      unknownData.isEmpty &&
      unknownRoot.isEmpty &&
      bookMeta.isEmpty &&
      extra.isEmpty;

  /// 保留的第三方/未知字段数量（导入结果展示用）。
  /// `xinyu` 是本应用自己的扩展，不计入「未识别」。
  int get preservedKeyCount =>
      stExtensions.keys.where((key) => key != 'xinyu').length +
      unknownData.length +
      unknownRoot.length;

  CharacterExtensions copyWith({
    Map<String, dynamic>? stExtensions,
    Map<String, dynamic>? unknownData,
    Map<String, dynamic>? unknownRoot,
    Map<String, dynamic>? bookMeta,
    Map<String, dynamic>? extra,
  }) => CharacterExtensions(
    stExtensions: stExtensions ?? this.stExtensions,
    unknownData: unknownData ?? this.unknownData,
    unknownRoot: unknownRoot ?? this.unknownRoot,
    bookMeta: bookMeta ?? this.bookMeta,
    extra: extra ?? this.extra,
  );
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable(
      Map<String, dynamic>.from(value),
    );
  }
  return const {};
}
