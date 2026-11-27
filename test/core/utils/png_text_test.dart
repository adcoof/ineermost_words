import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_roleplay_chat/core/utils/png_text.dart';
import 'package:ai_roleplay_chat/features/characters/data/silly_tavern_importer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  Uint8List basePng() =>
      Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));

  test('CRC32 标准向量', () {
    expect(pngCrc32(ascii.encode('123456789')), 0xCBF43926);
  });

  test('写入后可按顺序读回', () {
    final out = insertPngTextChunks(basePng(), const [
      PngTextChunk(keyword: 'chara', text: 'abc'),
      PngTextChunk(keyword: 'ccv3', text: 'def'),
    ]);
    final chunks = readPngTextChunks(out);
    expect(chunks.map((c) => c.keyword), ['chara', 'ccv3']);
    expect(chunks.map((c) => c.text), ['abc', 'def']);
    expect(isPngBytes(out), isTrue);
  });

  test('同名 tEXt 被替换而不是重复', () {
    final first = insertPngTextChunks(basePng(), const [
      PngTextChunk(keyword: 'chara', text: 'old'),
    ]);
    final second = insertPngTextChunks(first, const [
      PngTextChunk(keyword: 'chara', text: 'new'),
    ]);
    final chunks =
        readPngTextChunks(second).where((c) => c.keyword == 'chara').toList();
    expect(chunks, hasLength(1));
    expect(chunks.single.text, 'new');
  });

  test('保留原有图块，输出仍是可解码的 PNG', () {
    final out = insertPngTextChunks(basePng(), const [
      PngTextChunk(keyword: 'chara', text: 'x'),
    ]);
    final decoded = img.decodePng(out);
    expect(decoded, isNotNull);
    expect(decoded!.width, 2);
    expect(decoded.height, 2);
  });

  test('非 PNG 或缺少 IEND 报 FormatException', () {
    expect(
      () => insertPngTextChunks(Uint8List.fromList([1, 2, 3]), const []),
      throwsFormatException,
    );
    final broken = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52,
    ]);
    expect(() => insertPngTextChunks(broken, const []), throwsFormatException);
  });

  test('写出的角色卡能被现有导入器解析', () {
    final card = utf8.encode(jsonEncode({'name': '阿雪', 'description': '银发'}));
    final png = insertPngTextChunks(basePng(), [
      PngTextChunk(keyword: 'chara', text: base64Encode(card)),
    ]);
    final draft = const SillyTavernImporter().parse(png);
    expect(draft.name, '阿雪');
    expect(draft.description, '银发');
  });
}
