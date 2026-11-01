/// 角色记忆文档 + 「TA眼中的用户」查看/导出页（v8）。
///
/// 入口：聊天页标题头像点击 / 角色编辑页入口。
/// 文档按「# 小标题」分节渲染成卡片；支持导出 PNG 与 Word（.docx）分享。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/utils/docx.dart';
import '../../../core/utils/export_utils.dart';

/// 一节文档：可选小标题 + 正文。
typedef DocSection = ({String? heading, String body});

/// 把「# 小标题」分节的文档文本解析成节列表；无 # 时整篇归入无标题首节。
List<DocSection> parseDocSections(String doc) {
  final lines = doc.split('\n');
  final sections = <DocSection>[];
  String? heading;
  final body = StringBuffer();
  void flush() {
    final text = body.toString().trimRight();
    if (heading == null && text.isEmpty) return;
    sections.add((heading: heading, body: text));
    body.clear();
  }

  for (final line in lines) {
    if (line.trim().startsWith('#')) {
      flush();
      heading = line.trim().replaceFirst(RegExp(r'^#+\s*'), '');
    } else {
      if (body.isNotEmpty) body.write('\n');
      body.write(line);
    }
  }
  flush();
  return sections;
}

String _fmtShort(DateTime t) {
  final l = t.toLocal();
  return '${l.month}月${l.day}日 ${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}

String _fmtDate(DateTime t) {
  final l = t.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')}';
}

class CharacterMemoryPage extends ConsumerStatefulWidget {
  final String characterId;
  final String characterName;

  const CharacterMemoryPage({
    super.key,
    required this.characterId,
    required this.characterName,
  });

  @override
  ConsumerState<CharacterMemoryPage> createState() =>
      _CharacterMemoryPageState();
}

class _CharacterMemoryPageState extends ConsumerState<CharacterMemoryPage> {
  final _boundaryKey = GlobalKey();
  var _showUserDoc = false;
  String _memoryDoc = '';
  String _userDoc = '';
  DateTime? _updatedAt;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final memory = await ref
        .read(characterRepositoryProvider)
        .getMemory(widget.characterId);
    if (!mounted) return;
    setState(() {
      _memoryDoc = memory.summary;
      _userDoc = memory.userSummary;
      _updatedAt = memory.updatedAt;
      _loaded = true;
    });
  }

  String get _currentDoc => _showUserDoc ? _userDoc : _memoryDoc;

  String get _currentDocTitle => _showUserDoc
      ? '${widget.characterName}眼中的你'
      : '${widget.characterName}的记忆';

  Future<void> _exportPng() async {
    if (_currentDoc.trim().isEmpty) return;
    final bytes = await capturePng(_boundaryKey);
    if (bytes == null) return;
    await sharePngBytes(bytes, '$_currentDocTitle.png');
  }

  Future<void> _exportDocx() async {
    if (_currentDoc.trim().isEmpty) return;
    final sections = parseDocSections(_currentDoc);
    final dir = await getTemporaryDirectory();
    final file = p.join(
      dir.path,
      'mem_${widget.characterId}_${_showUserDoc ? 1 : 0}.docx',
    );
    await writeSimpleDocx(
      File(file),
      title: _currentDocTitle,
      sections: [
        for (final s in sections) DocxSection(heading: s.heading, body: s.body),
      ],
    );
    await shareFilePath(file, '$_currentDocTitle.docx');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final doc = _currentDoc;
    final sections = parseDocSections(doc);
    return Scaffold(
      appBar: AppBar(
        title: Text(_showUserDoc ? 'TA眼中的你' : '角色记忆'),
        actions: [
          IconButton(
            tooltip: '导出图片',
            icon: const Icon(Icons.image_outlined),
            onPressed: doc.trim().isEmpty ? null : _exportPng,
          ),
          IconButton(
            tooltip: '导出 Word',
            icon: const Icon(Icons.description_outlined),
            onPressed: doc.trim().isEmpty ? null : _exportDocx,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('角色记忆')),
                      ButtonSegment(value: true, label: Text('TA眼中的你')),
                    ],
                    selected: {_showUserDoc},
                    onSelectionChanged: (s) =>
                        setState(() => _showUserDoc = s.first),
                  ),
                ),
                if (_updatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '更新于 ${_fmtShort(_updatedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                Expanded(
                  child: doc.trim().isEmpty
                      ? _EmptyHint(isUserDoc: _showUserDoc)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: RepaintBoundary(
                            key: _boundaryKey,
                            child: _DocCard(
                              title: _currentDocTitle,
                              sections: sections,
                              updatedAt: _updatedAt,
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final bool isUserDoc;

  const _EmptyHint({required this.isUserDoc});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUserDoc ? Icons.person_outline : Icons.psychology_outlined,
              size: 48,
              color: scheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              isUserDoc ? '还没有对你的了解' : '还没有记忆',
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '和 TA 聊上几轮后，这里会自动整理出'
              '${isUserDoc ? 'TA 对你的认识' : '跨会话的记忆文档'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 展示/导出共用的文档卡片：白底黑字（分享出去更清晰）。
class _DocCard extends StatelessWidget {
  final String title;
  final List<DocSection> sections;
  final DateTime? updatedAt;

  const _DocCard({
    required this.title,
    required this.sections,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1730),
            ),
          ),
          if (updatedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '更新于 ${_fmtDate(updatedAt!)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A86A6)),
            ),
          ],
          const SizedBox(height: 12),
          for (final s in sections) ...[
            if (s.heading != null && s.heading!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  s.heading!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3D3670),
                  ),
                ),
              ),
            Text(
              s.body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF2A2640),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
