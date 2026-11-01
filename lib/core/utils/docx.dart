/// 手写最小 OOXML（.docx）生成器：标题 + 分节正文，零格式依赖。
///
/// .docx 本质是个 zip：[Content_Types].xml + _rels/.rels + word/document.xml。
/// 用已有的 archive 包打包，不引第三方 docx 库。
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

/// 一节文档内容：可选小标题 + 正文（按行拆段）。
class DocxSection {
  final String? heading;

  final String body;

  const DocxSection({this.heading, required this.body});
}

/// 把标题与分节内容写成 .docx 文件。
Future<void> writeSimpleDocx(
  File file, {
  required String title,
  required List<DocxSection> sections,
}) async {
  final archive = Archive();
  archive.addFile(_entry('[Content_Types].xml', _contentTypesXml));
  archive.addFile(_entry('_rels/.rels', _relsXml));
  archive.addFile(_entry('word/document.xml', _documentXml(title, sections)));
  final bytes = ZipEncoder().encode(archive);
  await file.writeAsBytes(bytes, flush: true);
}

ArchiveFile _entry(String path, String xml) {
  final data = utf8.encode(xml);
  return ArchiveFile(path, data.length, data);
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// 一段落：[bold] 加粗，[size] 半磅（21=10.5pt，28=14pt，36=18pt）。
String _para(String text, {int size = 21, bool bold = false}) =>
    '<w:p><w:pPr><w:spacing w:after="120"/></w:pPr>'
    '<w:r><w:rPr>${bold ? '<w:b/>' : ''}<w:sz w:val="$size"/>'
    '<w:szCs w:val="$size"/></w:rPr>'
    '<w:t xml:space="preserve">${_esc(text)}</w:t></w:r></w:p>';

String _documentXml(String title, List<DocxSection> sections) {
  final b = StringBuffer()
    ..write(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/'
      'wordprocessingml/2006/main"><w:body>',
    )
    ..write(_para(title, size: 36, bold: true));
  for (final s in sections) {
    if (s.heading != null && s.heading!.trim().isNotEmpty) {
      b.write(_para(s.heading!.trim(), size: 28, bold: true));
    }
    for (final line in s.body.split('\n')) {
      if (line.trim().isEmpty) continue;
      b.write(_para(line));
    }
  }
  b.write(
    '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/></w:sectPr>'
    '</w:body></w:document>',
  );
  return b.toString();
}

const String _contentTypesXml =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" '
    'ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/word/document.xml" '
    'ContentType="application/vnd.openxmlformats-officedocument'
    '.wordprocessingml.document.main+xml"/></Types>';

const String _relsXml =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" '
    'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
    'Target="word/document.xml"/></Relationships>';
