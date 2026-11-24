/// 角色记忆 / 长期记忆 / 「TA眼中的用户」查看与导出页（v1.4 M3）。
///
/// - 角色记忆：最近 3 天细节（自动整理，可按节渲染）；
/// - 长期记忆：事实 + 发生日期时间线，长按可删；
/// - TA眼中的你：用户画像。
/// 入口：聊天页标题头像点击 / 角色编辑页入口。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/utils/docx.dart';
import '../../../core/utils/export_utils.dart';
import '../domain/memory_fact.dart';

/// 一节文档：可选小标题 + 正文。
typedef DocSection = ({String? heading, String body});

/// 把「# 小标题」或独占一行的「**小标题**」解析成节列表。
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
    final trimmed = line.trim();
    final bold = RegExp(r'^\*\*(.+)\*\*$').firstMatch(trimmed);
    if (trimmed.startsWith('#')) {
      flush();
      heading = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
    } else if (bold != null && bold.group(1)!.trim().length <= 24) {
      flush();
      heading = bold.group(1)!.trim();
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
  var _tab = 0; // 0=近期记忆 1=长期记忆 2=TA眼中的你
  String _memoryDoc = '';
  String _userDoc = '';
  DateTime? _updatedAt;
  List<MemoryFact> _facts = const [];
  var _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final repo = ref.read(characterRepositoryProvider);
      final memory = await repo.getMemory(widget.characterId);
      final facts = await repo.getMemoryFacts(widget.characterId);
      if (!mounted) return;
      setState(() {
        _memoryDoc = memory.summary;
        _userDoc = memory.userSummary;
        _updatedAt = memory.updatedAt;
        _facts = facts;
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请下拉重试';
        _loaded = true;
      });
      debugPrint('memory page load: $e');
    }
  }

  String get _currentDocTitle => switch (_tab) {
    1 => '${widget.characterName}的长期记忆',
    2 => '${widget.characterName}眼中的你',
    _ => '${widget.characterName}的记忆',
  };

  String get _currentDoc => switch (_tab) {
    1 => _factsDoc,
    2 => _userDoc,
    _ => _memoryDoc,
  };

  String get _factsDoc => _facts
      .map((f) => '${_fmtDate(f.occurredAt)} · ${f.fact}')
      .join('\n');

  Future<void> _exportPng() async {
    if (_currentDoc.trim().isEmpty) return;
    final bytes = await capturePng(_boundaryKey);
    if (bytes == null) return;
    await sharePngBytes(bytes, '$_currentDocTitle.png');
  }

  Future<void> _exportDocx() async {
    if (_currentDoc.trim().isEmpty) return;
    final sections = _tab == 1
        ? <DocSection>[
            (
              heading: '长期记忆',
              body: _facts
                  .map((f) => '${_fmtDate(f.occurredAt)} · ${f.fact}')
                  .join('\n'),
            ),
          ]
        : parseDocSections(_currentDoc);
    final dir = await getTemporaryDirectory();
    final file = p.join(
      dir.path,
      'mem_${widget.characterId}_$_tab.docx',
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

  Future<void> _deleteFact(MemoryFact fact) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条长期记忆？'),
        content: Text('${_fmtDate(fact.occurredAt)} · ${fact.fact}\n\n删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(characterRepositoryProvider).deleteMemoryFact(fact.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('角色记忆'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            tooltip: '导出图片',
            icon: const Icon(Icons.image_outlined),
            onPressed: _currentDoc.trim().isEmpty ? null : _exportPng,
          ),
          IconButton(
            tooltip: '导出 Word',
            icon: const Icon(Icons.description_outlined),
            onPressed: _currentDoc.trim().isEmpty ? null : _exportDocx,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('角色记忆')),
                      ButtonSegment(value: 1, label: Text('长期记忆')),
                      ButtonSegment(value: 2, label: Text('TA眼中的你')),
                    ],
                    selected: {_tab},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _tab = s.first),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _error!,
                      style: TextStyle(fontSize: 12, color: scheme.error),
                    ),
                  )
                else if (_tab == 0 && _updatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '上次整理 ${_fmtShort(_updatedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  )
                else if (_tab == 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '共 ${_facts.length} 条 · 长按可删除',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _tab == 1
                        ? _buildFacts()
                        : _memoryDocView(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFacts() {
    if (_facts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 360,
            child: _EmptyHint(isUserDoc: false, customText: '还没有长期记忆'),
          ),
        ],
      );
    }
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: RepaintBoundary(
        key: _boundaryKey,
        child: _FactsCard(
          title: _currentDocTitle,
          facts: _facts,
          onLongPress: _deleteFact,
        ),
      ),
    );
  }

  Widget _memoryDocView() {
    final doc = _tab == 2 ? _userDoc : _memoryDoc;
    if (doc.trim().isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 360,
            child: _EmptyHint(
              isUserDoc: _tab == 2,
              customText: _tab == 2 ? '还没有对你的了解' : '还没有记忆',
            ),
          ),
        ],
      );
    }
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: RepaintBoundary(
        key: _boundaryKey,
        child: _DocCard(
          title: _currentDocTitle,
          sections: parseDocSections(doc),
          updatedAt: _tab == 0 ? _updatedAt : null,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final bool isUserDoc;
  final String? customText;

  const _EmptyHint({required this.isUserDoc, this.customText});

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
              customText ?? (isUserDoc ? '还没有对你的了解' : '还没有记忆'),
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '和 TA 聊上几轮后，这里会自动整理出'
              '${isUserDoc ? 'TA 对你的认识' : '跨会话的记忆'}',
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

/// 长期事实时间线（白底黑字，导出与展示共用）。
class _FactsCard extends StatelessWidget {
  final String title;
  final List<MemoryFact> facts;
  final Future<void> Function(MemoryFact) onLongPress;

  const _FactsCard({
    required this.title,
    required this.facts,
    required this.onLongPress,
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
          const SizedBox(height: 4),
          Text(
            '只保留事实与发生日期，细节会随时间淡忘',
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A86A6)),
          ),
          const SizedBox(height: 12),
          for (final fact in facts)
            InkWell(
              onLongPress: () => onLongPress(fact),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 78,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EFFA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _fmtDate(fact.occurredAt),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6A5FA8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fact.fact,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF2A2640),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
