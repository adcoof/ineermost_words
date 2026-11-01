/// StickerRepository：添加/删除/心情挑选与兜底链。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/data/local/app_database.dart';
import 'package:ai_roleplay_chat/features/chat/data/sticker_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StickerRepository repo;
  late Directory tmp;

  /// 1x1 纯色 PNG 字节（最小可解码图）。
  final png = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
    0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
    0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB4, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = StickerRepository(db);
    tmp = await Directory.systemTemp.createTemp('sticker_test');
  });

  tearDown(() async {
    await db.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('addStickers：落盘 + 行入库 + pickForMood 命中', () async {
    final paths = await repo.addStickers('ch1', 'happy', [png, png], root: tmp);
    expect(paths, hasLength(2));
    for (final p in paths) {
      expect(File(p).existsSync(), isTrue);
    }
    final picked = await repo.pickForMood('ch1', 'happy');
    expect(picked, isNotNull);
    expect(paths, contains(picked));
  });

  test('兜底链：crying → sad；无任何贴纸 → null', () async {
    await repo.addStickers('ch1', 'sad', [png], root: tmp);
    expect(await repo.pickForMood('ch1', 'crying'), isNotNull);

    expect(await repo.pickForMood('ch2', 'happy'), isNull);
    // 无兜底的心情（speechless）精确匹配不到就是 null。
    expect(await repo.pickForMood('ch1', 'speechless'), isNull);
  });

  test('delete：行与文件一起清', () async {
    final paths = await repo.addStickers('ch1', 'angry', [png], root: tmp);
    final rows = await repo.watchByCharacter('ch1').first;
    expect(rows, hasLength(1));
    await repo.delete(rows.single.id);
    expect(await repo.watchByCharacter('ch1').first, isEmpty);
    expect(File(paths.single).existsSync(), isFalse);
  });

  test('心情清单固定 14 项', () {
    expect(kStickerMoods, hasLength(14));
    expect(kStickerMoods['happy'], '喜');
    expect(kStickerMoods['sleepy'], '困倦');
  });
}
