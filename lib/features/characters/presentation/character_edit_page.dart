/// 角色编辑页：基础 / 档案 / 高级三页签，手动编辑完整角色档案与立绘。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/export_utils.dart';
import '../../../core/utils/token_estimate.dart';
import '../application/character_assistant_service.dart';
import '../data/character_card_exporter.dart';
import '../domain/character.dart';
import '../domain/character_profile.dart';
import '../domain/lore_entry.dart';
import 'character_lore_page.dart';
import 'character_memory_page.dart';
import 'character_version_page.dart';
import 'character_workshop_page.dart';
import 'image_crop_page.dart';
import 'sticker_library_page.dart';

class CharacterEditPage extends ConsumerStatefulWidget {
  /// null 表示新建。
  final Character? character;

  const CharacterEditPage({super.key, this.character});

  @override
  ConsumerState<CharacterEditPage> createState() => _CharacterEditPageState();
}

class _CharacterEditPageState extends ConsumerState<CharacterEditPage> {
  late Character _character;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _personality;
  late final TextEditingController _scenario;
  late final TextEditingController _firstMessage;
  late final TextEditingController _exampleDialogue;

  /// 扩展档案的 30+ 个输入框，按 `分区.字段` 索引。
  late final Map<String, TextEditingController> _profileFields;
  late final Listenable _profileListenable;

  /// 备用开场白与标签。
  late List<TextEditingController> _alternates;
  late List<String> _tags;

  Uint8List? _pendingAvatar;
  final List<({TextEditingController controller, String oldValue, String label})>
      _aiUndo = [];

  /// PopScope 需要显式放行才能 pop（保存/删除/确认离开时置 true）。
  bool _allowPop = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(characterRepositoryProvider);
    _character = widget.character ?? repo.blank();
    _name = TextEditingController(text: _character.name);
    _description = TextEditingController(text: _character.description);
    _personality = TextEditingController(text: _character.personality);
    _scenario = TextEditingController(text: _character.scenario);
    _firstMessage = TextEditingController(text: _character.firstMessage);
    _exampleDialogue = TextEditingController(text: _character.exampleDialogue);
    _profileFields = _makeProfileFields(_character.profile);
    _profileListenable = Listenable.merge(_profileFields.values.toList());
    _alternates = [
      for (final text in _character.alternateGreetings)
        TextEditingController(text: text),
    ];
    _tags = [..._character.profile.creator.tags];
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _personality,
      _scenario,
      _firstMessage,
      _exampleDialogue,
    ]) {
      c.dispose();
    }
    for (final c in _profileFields.values) {
      c.dispose();
    }
    for (final c in _alternates) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.character == null ? '新建角色' : '编辑角色'),
            actions: [
              IconButton(
                tooltip: 'AI 角色工坊',
                icon: const Icon(Icons.auto_awesome_outlined),
                onPressed: _openWorkshop,
              ),
              if (_aiUndo.isNotEmpty)
                IconButton(
                  tooltip: '撤销上一次 AI 改写',
                  onPressed: _undoLastAi,
                  icon: const Icon(Icons.undo),
                ),
              PopupMenuButton<CharacterCardFormat>(
                tooltip: '导出角色卡',
                icon: const Icon(Icons.ios_share),
                onSelected: _exportCard,
                itemBuilder: (_) => [
                  for (final format in CharacterCardFormat.values)
                    PopupMenuItem(
                      value: format,
                      child: Text('导出 ${format.label}'),
                    ),
                ],
              ),
              TextButton(onPressed: _save, child: const Text('保存')),
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: '基础'),
                Tab(text: '档案'),
                Tab(text: '高级'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildBasicTab(context),
              _buildProfileTab(context),
              _buildAdvancedTab(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── 基础页签 ──────────────────────────────────────────────────────

  Widget _buildBasicTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickAvatar,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: _avatarProvider(),
              child: _avatarProvider() == null
                  ? const Icon(Icons.add_a_photo_outlined, size: 32)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(child: Text('点击设置立绘')),
        const SizedBox(height: 16),
        if (widget.character != null) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('记忆与用户画像'),
            subtitle: const Text('查看 TA 记住的事，以及 TA 眼中的你'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CharacterMemoryPage(
                  characterId: _character.id,
                  characterName: _character.name,
                ),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('世界书'),
            subtitle: const Text('关键词命中的设定才注入，节省上下文'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CharacterLorePage(
                  characterId: _character.id,
                  characterName: _character.name,
                ),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.emoji_emotions_outlined),
            title: const Text('表情包库'),
            subtitle: const Text('按心情上传贴纸，聊天时自动发送'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StickerLibraryPage(characterId: _character.id),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _buildBasicInfoCard(),
        const SizedBox(height: 12),
        _buildPersonaCard(),
        const SizedBox(height: 12),
        _buildAlternateGreetingsCard(),
        const SizedBox(height: 12),
        _buildTagsCard(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildBasicInfoCard() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('基础信息', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: '名字 *',
                border: const OutlineInputBorder(),
                suffixIcon: _aiSuffix('name', '名字', _name),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _profileField('basic.nickname', '昵称')),
                const SizedBox(width: 12),
                Expanded(child: _profileField('basic.age', '年龄')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _profileField('basic.gender', '性别')),
                const SizedBox(width: 12),
                Expanded(child: _profileField('basic.race', '种族')),
              ],
            ),
            const SizedBox(height: 12),
            _profileField('basic.identity', '身份', hint: '学生 / 侦探 / 精灵……'),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaCard() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('角色人设', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: '描述（外貌、背景等）',
                border: const OutlineInputBorder(),
                suffixIcon: _aiSuffix('description', '描述', _description),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _personality,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: '性格',
                border: const OutlineInputBorder(),
                suffixIcon: _aiSuffix('personality', '性格', _personality),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _scenario,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: '场景背景',
                border: const OutlineInputBorder(),
                suffixIcon: _aiSuffix('scenario', '场景背景', _scenario),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firstMessage,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: '开场白（角色先说的话）',
                border: const OutlineInputBorder(),
                suffixIcon: _aiSuffix('firstMessage', '开场白', _firstMessage),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _exampleDialogue,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: '对话示例（可选）',
                hintText: '例如：\n{{user}}：你好\n{{char}}：哼，谁要跟你打招呼啊。',
                border: const OutlineInputBorder(),
                suffixIcon: _aiSuffix(
                  'exampleDialogue',
                  '对话示例',
                  _exampleDialogue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternateGreetingsCard() {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.forum_outlined),
        title: Text('备用开场白（${_alternates.length}）'),
        subtitle: const Text('聊天页可切换；主开场白在上面'),
        maintainState: true,
        childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          for (var i = 0; i < _alternates.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _alternates[i],
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: '备用开场白 ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '删除备用开场白',
                    onPressed: () => _removeAlternate(i),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addAlternate,
              icon: const Icon(Icons.add),
              label: const Text('添加备用开场白'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('标签', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                ),
              ],
            ),
            if (_tags.isEmpty)
              Text(
                '用于角色库筛选与导出。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final tag in _tags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── 档案页签 ──────────────────────────────────────────────────────

  Widget _buildProfileTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(
          title: '外貌设定',
          icon: Icons.face_outlined,
          initiallyExpanded: true,
          children: [
            _profileField('appearance.summary', '概述', minLines: 2, maxLines: 4),
            _profileField('appearance.hair', '发型'),
            _profileField('appearance.eyes', '瞳色'),
            _profileField('appearance.outfit', '服饰', minLines: 2, maxLines: 3),
            Row(
              children: [
                Expanded(child: _profileField('appearance.height', '身高')),
                const SizedBox(width: 12),
                Expanded(child: _profileField('appearance.body', '体型')),
              ],
            ),
            _profileField('appearance.features', '外貌特征', minLines: 2, maxLines: 4),
          ],
        ),
        _section(
          title: '背景故事',
          icon: Icons.history_edu_outlined,
          children: [
            _profileField('background.origin', '出身'),
            _profileField(
              'background.experiences',
              '成长经历',
              minLines: 3,
              maxLines: 6,
            ),
            _profileField(
              'background.keyEvents',
              '重要事件',
              minLines: 2,
              maxLines: 4,
            ),
            _profileField('background.secrets', '秘密', minLines: 2, maxLines: 4),
            _profileField('background.goals', '目标', minLines: 2, maxLines: 4),
          ],
        ),
        _section(
          title: '关系设定',
          icon: Icons.favorite_outline,
          children: [
            _profileField('relationships.userRelation', '与用户的关系'),
            _profileField('relationships.initialCloseness', '初始亲密度'),
            _profileField('relationships.direction', '关系走向', minLines: 2, maxLines: 4),
            _profileField('relationships.others', '其他关系', minLines: 2, maxLines: 4),
          ],
        ),
        _section(
          title: '语言风格',
          icon: Icons.record_voice_over_outlined,
          children: [
            _profileField('language.tone', '语气'),
            _profileField('language.habits', '说话习惯', minLines: 2, maxLines: 4),
            _profileField('language.verbalTics', '口癖'),
            _profileField('language.commonPhrases', '常用表达', minLines: 2, maxLines: 4),
            _profileField('language.taboos', '表达禁忌', minLines: 2, maxLines: 4),
          ],
        ),
        _section(
          title: '互动方式',
          icon: Icons.chat_outlined,
          children: [
            _profileField('interaction.replyLength', '回复长度'),
            _profileField('interaction.initiative', '主动性'),
            _profileField('interaction.emotionExpression', '情绪表达'),
            _profileField('interaction.behaviorTendency', '行为倾向', minLines: 2, maxLines: 4),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── 高级页签 ──────────────────────────────────────────────────────

  Widget _buildAdvancedTab(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(
          title: '创作者信息',
          icon: Icons.edit_note,
          children: [
            _profileField('creator.author', '作者'),
            _profileField('creator.version', '角色版本'),
            _profileField('creator.notes', '创作者备注', minLines: 2, maxLines: 4),
            _profileField('creator.copyright', '版权声明'),
          ],
        ),
        _section(
          title: '高级提示词',
          icon: Icons.tune,
          children: [
            _profileField(
              'runConfig.systemPrompt',
              '角色卡系统提示',
              minLines: 4,
              maxLines: 8,
              hint: '注入在人设之后；上限 2000 字符',
            ),
            _profileField(
              'runConfig.postHistoryInstructions',
              '历史后置指令',
              minLines: 3,
              maxLines: 6,
              hint: '注入在历史之后；上限 1000 字符',
            ),
          ],
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTokenEstimate(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('第三方 / 未识别扩展'),
                subtitle: const Text('导入时原样保留，导出时合并'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showExtensions,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('版本历史'),
                subtitle: const Text('保存时自动快照，可查看与恢复'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openVersions,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('导出角色卡'),
                subtitle: const Text('ST V2/V3 JSON、PNG'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickExportFormat,
              ),
            ],
          ),
        ),
        if (widget.character != null) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('删除角色'),
            onPressed: _delete,
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTokenEstimate() {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _profileListenable,
      builder: (context, _) {
        final profile = _buildProfile();
        final profileTokens = estimateTokens(profile.promptText);
        final promptChars = profile.runConfig.systemPrompt.length;
        final postChars = profile.runConfig.postHistoryInstructions.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('档案用量', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _usageRow('档案分区块', '约 $profileTokens token'),
            _usageRow('卡内系统提示', '$promptChars / 2000 字符'),
            _usageRow('历史后置指令', '$postChars / 1000 字符'),
            const SizedBox(height: 8),
            Text(
              profileTokens > 1200
                  ? '档案较长，聊天时会按窗口 12%（最多 1200 token）截断。'
                  : '档案块按窗口 12% 注入（最少 300 / 最多 1200 token）。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _usageRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── 通用字段/分组 ──────────────────────────────────────────────────

  Widget _profileField(
    String key,
    String label, {
    int minLines = 1,
    int maxLines = 1,
    String? hint,
  }) {
    final controller = _profileFields[key];
    if (controller == null) {
      throw ArgumentError('未知档案字段：$key');
    }
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        initiallyExpanded: initiallyExpanded,
        maintainState: true,
        childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }

  // ── 档案模型 ──────────────────────────────────────────────────────

  Map<String, String> _profileValues(CharacterProfile profile) => {
    'basic.nickname': profile.basic.nickname,
    'basic.age': profile.basic.age,
    'basic.gender': profile.basic.gender,
    'basic.race': profile.basic.race,
    'basic.identity': profile.basic.identity,
    'appearance.summary': profile.appearance.summary,
    'appearance.hair': profile.appearance.hair,
    'appearance.eyes': profile.appearance.eyes,
    'appearance.outfit': profile.appearance.outfit,
    'appearance.height': profile.appearance.height,
    'appearance.body': profile.appearance.body,
    'appearance.features': profile.appearance.features,
    'background.origin': profile.background.origin,
    'background.experiences': profile.background.experiences,
    'background.keyEvents': profile.background.keyEvents,
    'background.secrets': profile.background.secrets,
    'background.goals': profile.background.goals,
    'relationships.userRelation': profile.relationships.userRelation,
    'relationships.initialCloseness': profile.relationships.initialCloseness,
    'relationships.direction': profile.relationships.direction,
    'relationships.others': profile.relationships.others,
    'language.tone': profile.language.tone,
    'language.habits': profile.language.habits,
    'language.verbalTics': profile.language.verbalTics,
    'language.commonPhrases': profile.language.commonPhrases,
    'language.taboos': profile.language.taboos,
    'interaction.replyLength': profile.interaction.replyLength,
    'interaction.initiative': profile.interaction.initiative,
    'interaction.emotionExpression': profile.interaction.emotionExpression,
    'interaction.behaviorTendency': profile.interaction.behaviorTendency,
    'creator.author': profile.creator.author,
    'creator.version': profile.creator.version,
    'creator.notes': profile.creator.notes,
    'creator.copyright': profile.creator.copyright,
    'runConfig.systemPrompt': profile.runConfig.systemPrompt,
    'runConfig.postHistoryInstructions':
        profile.runConfig.postHistoryInstructions,
  };

  Map<String, TextEditingController> _makeProfileFields(
    CharacterProfile profile,
  ) => {
    for (final entry in _profileValues(profile).entries)
      entry.key: TextEditingController(text: entry.value),
  };

  CharacterProfile _buildProfile() {
    String v(String key) => _profileFields[key]!.text.trim();
    return CharacterProfile(
      basic: BasicProfile(
        nickname: v('basic.nickname'),
        age: v('basic.age'),
        gender: v('basic.gender'),
        race: v('basic.race'),
        identity: v('basic.identity'),
      ),
      appearance: AppearanceProfile(
        summary: v('appearance.summary'),
        hair: v('appearance.hair'),
        eyes: v('appearance.eyes'),
        outfit: v('appearance.outfit'),
        height: v('appearance.height'),
        body: v('appearance.body'),
        features: v('appearance.features'),
      ),
      background: BackgroundProfile(
        origin: v('background.origin'),
        experiences: v('background.experiences'),
        keyEvents: v('background.keyEvents'),
        secrets: v('background.secrets'),
        goals: v('background.goals'),
      ),
      relationships: RelationshipProfile(
        userRelation: v('relationships.userRelation'),
        initialCloseness: v('relationships.initialCloseness'),
        direction: v('relationships.direction'),
        others: v('relationships.others'),
      ),
      language: LanguageProfile(
        tone: v('language.tone'),
        habits: v('language.habits'),
        verbalTics: v('language.verbalTics'),
        commonPhrases: v('language.commonPhrases'),
        taboos: v('language.taboos'),
      ),
      interaction: InteractionProfile(
        replyLength: v('interaction.replyLength'),
        initiative: v('interaction.initiative'),
        emotionExpression: v('interaction.emotionExpression'),
        behaviorTendency: v('interaction.behaviorTendency'),
      ),
      creator: CreatorProfile(
        author: v('creator.author'),
        version: v('creator.version'),
        tags: List.unmodifiable(_tags),
        notes: v('creator.notes'),
        copyright: v('creator.copyright'),
      ),
      runConfig: RunConfigProfile(
        systemPrompt: v('runConfig.systemPrompt'),
        postHistoryInstructions: v('runConfig.postHistoryInstructions'),
      ),
      extra: _character.profile.extra,
    );
  }

  Character get _draftCharacter => _character.copyWith(
        name: _name.text,
        description: _description.text,
        personality: _personality.text,
        scenario: _scenario.text,
        firstMessage: _firstMessage.text,
        exampleDialogue: _exampleDialogue.text,
        alternateGreetings: [
          for (final c in _alternates)
            if (c.text.trim().isNotEmpty) c.text.trim(),
        ],
        profile: _buildProfile(),
      );

  bool get _hasChanges {
    final draft = _draftCharacter;
    return draft.name != _character.name ||
        draft.description != _character.description ||
        draft.personality != _character.personality ||
        draft.scenario != _character.scenario ||
        draft.firstMessage != _character.firstMessage ||
        draft.exampleDialogue != _character.exampleDialogue ||
        draft.profile.encode() != _character.profile.encode() ||
        !_sameList(draft.alternateGreetings, _character.alternateGreetings) ||
        _pendingAvatar != null;
  }

  bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ── 交互 ──────────────────────────────────────────────────────────

  Widget _aiSuffix(
    String field,
    String label,
    TextEditingController controller,
  ) {
    return IconButton(
      tooltip: 'AI 改写',
      icon: const Icon(Icons.auto_fix_high, size: 20),
      onPressed: () => _aiRewrite(field, label, controller),
    );
  }

  Future<void> _aiRewrite(
    String field,
    String label,
    TextEditingController controller,
  ) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AiRewriteSheet(
        assistant: ref.read(characterAssistantProvider),
        character: _draftCharacter,
        field: field,
        fieldLabel: label,
        currentValue: controller.text,
      ),
    );
    if (!mounted || value == null) return;
    _aiUndo.add(
      (controller: controller, oldValue: controller.text, label: label),
    );
    controller.text = value;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已替换「$label」，保存后才会写入角色卡')),
    );
  }

  void _undoLastAi() {
    if (_aiUndo.isEmpty) return;
    final last = _aiUndo.removeLast();
    last.controller.text = last.oldValue;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已撤销「${last.label}」的 AI 改写')),
    );
  }

  void _addAlternate() {
    setState(() => _alternates.add(TextEditingController()));
  }

  void _removeAlternate(int index) {
    if (index < 0 || index >= _alternates.length) return;
    final removed = _alternates.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '标签',
            hintText: '校园 / 傲娇 / 奇幻',
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    controller.dispose();
    final tag = value?.trim() ?? '';
    if (tag.isEmpty || !mounted) return;
    if (_tags.contains(tag)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('标签已存在')));
      return;
    }
    setState(() => _tags.add(tag));
  }

  Future<void> _openWorkshop() async {
    if (widget.character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先保存角色，再使用 AI 工坊')),
      );
      return;
    }
    // 带上当前未保存的编辑内容，避免工坊基于旧值改写后覆盖用户修改。
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CharacterWorkshopPage(character: _draftCharacter),
      ),
    );
    if (changed == true && mounted) await _popPage(true);
  }

  Future<void> _openVersions() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CharacterVersionPage(
          characterId: _character.id,
          characterName: _character.name,
        ),
      ),
    );
    if (changed == true && mounted) await _reloadFromDb();
  }

  void _showExtensions() {
    final extensions = _character.extensions;
    final text = extensions.isEmpty
        ? '（无）'
        : const JsonEncoder.withIndent('  ').convert(extensions.toJson());
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('第三方 / 未识别扩展'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExportFormat() async {
    final format = await showModalBottomSheet<CharacterCardFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final format in CharacterCardFormat.values)
              ListTile(
                leading: Icon(
                  switch (format) {
                    CharacterCardFormat.png => Icons.image_outlined,
                    _ => Icons.data_object,
                  },
                ),
                title: Text(format.label),
                onTap: () => Navigator.pop(context, format),
              ),
          ],
        ),
      ),
    );
    if (format != null && mounted) await _exportCard(format);
  }

  ImageProvider? _avatarProvider() {
    final pending = _pendingAvatar;
    if (pending != null) return MemoryImage(pending);
    final path = _character.avatarPath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return FileImage(File(path));
    }
    return null;
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.pickFile(type: FileType.image);
    if (result == null) return;
    final bytes = await result.xFile.readAsBytes();
    if (!mounted) return;
    // 头像统一走 1:1 圆形裁剪（v8）。
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) =>
            ImageCropPage(imageBytes: bytes, aspectRatio: 1, title: '裁剪立绘'),
      ),
    );
    if (cropped == null || !mounted) return;
    setState(() => _pendingAvatar = cropped);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('名字不能为空')));
      return;
    }
    final repo = ref.read(characterRepositoryProvider);
    var character = _draftCharacter.copyWith(name: name);
    final pending = _pendingAvatar;
    if (pending != null) {
      final path = await repo.saveAvatar(character.id, pending);
      character = character.copyWith(avatarPath: path);
    }
    await repo.save(character);
    _character = character;
    _pendingAvatar = null;
    await _popPage();
  }

  Future<void> _reloadFromDb() async {
    final latest =
        await ref.read(characterRepositoryProvider).getById(_character.id);
    if (latest == null || !mounted) return;
    final oldAlternates = _alternates;
    final newAlternates = [
      for (final text in latest.alternateGreetings)
        TextEditingController(text: text),
    ];
    final values = _profileValues(latest.profile);
    setState(() {
      _character = latest;
      _name.text = latest.name;
      _description.text = latest.description;
      _personality.text = latest.personality;
      _scenario.text = latest.scenario;
      _firstMessage.text = latest.firstMessage;
      _exampleDialogue.text = latest.exampleDialogue;
      for (final entry in values.entries) {
        _profileFields[entry.key]?.text = entry.value;
      }
      _alternates = newAlternates;
      _tags = [...latest.profile.creator.tags];
      _pendingAvatar = null;
      _allowPop = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in oldAlternates) {
        c.dispose();
      }
    });
  }

  Future<void> _handleBack() async {
    if (_leaving) return;
    if (!_hasChanges) {
      await _popPage();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃未保存的修改？'),
        content: const Text('当前角色有未保存的改动，离开后会丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('放弃并离开'),
          ),
        ],
      ),
    );
    if (leave == true) await _popPage();
  }

  Future<void> _popPage([Object? result]) async {
    if (!mounted || _leaving) return;
    _leaving = true;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }

  /// 导出当前编辑中的角色（未保存的核心/档案字段也会写入导出文件）。
  Future<void> _exportCard(CharacterCardFormat format) async {
    final draft = _draftCharacter;
    if (draft.name.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('名字不能为空')));
      return;
    }

    Uint8List? avatarBytes;
    if (format == CharacterCardFormat.png) {
      avatarBytes = await _avatarBytes();
      if (avatarBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PNG 角色卡需要先设置立绘')),
          );
        }
        return;
      }
    }
    if (!mounted) return;

    const exporter = CharacterCardExporter();
    var includeXinyu = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final warnings = exporter.lossWarnings(
            character: draft,
            includeXinyuExtension: includeXinyu,
          );
          return AlertDialog(
            title: Text('导出 ${format.label}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('以下数据不会写入角色卡：'),
                  const SizedBox(height: 8),
                  for (final warning in warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('· $warning'),
                    ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: includeXinyu,
                    onChanged: (v) =>
                        setState(() => includeXinyu = v ?? true),
                    title: const Text('写入心语扩展（便于导回心语）'),
                    subtitle: const Text('第三方软件可能忽略；关闭后档案分区会丢失。'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('导出'),
              ),
            ],
          );
        },
      ),
    );
    if (confirmed != true || !mounted) return;

    final lore = widget.character == null
        ? const <LoreEntry>[]
        : await ref
              .read(loreRepositoryProvider)
              .listForCharacter(_character.id);
    if (!mounted) return;

    try {
      final export = switch (format) {
        CharacterCardFormat.v2Json => exporter.exportV2(
          character: draft,
          lore: lore,
          includeXinyuExtension: includeXinyu,
        ),
        CharacterCardFormat.v3Json => exporter.exportV3(
          character: draft,
          lore: lore,
          includeXinyuExtension: includeXinyu,
        ),
        CharacterCardFormat.png => exporter.exportPng(
          character: draft,
          lore: lore,
          avatarBytes: avatarBytes!,
          includeXinyuExtension: includeXinyu,
        ),
      };
      await shareBytes(export.bytes, export.fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已生成 ${export.fileName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    }
  }

  Future<Uint8List?> _avatarBytes() async {
    final pending = _pendingAvatar;
    if (pending != null) return pending;
    final path = _character.avatarPath;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除角色'),
        content: Text('确定删除「${_character.name}」？已绑定的会话将转为普通聊天，不再按 TA 的人设回复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(characterRepositoryProvider).delete(_character.id);
      await _popPage();
    }
  }
}

class _AiRewriteSheet extends StatefulWidget {
  final CharacterAssistantService assistant;
  final Character character;
  final String field;
  final String fieldLabel;
  final String currentValue;

  const _AiRewriteSheet({
    required this.assistant,
    required this.character,
    required this.field,
    required this.fieldLabel,
    required this.currentValue,
  });

  @override
  State<_AiRewriteSheet> createState() => _AiRewriteSheetState();
}

class _AiRewriteSheetState extends State<_AiRewriteSheet> {
  final TextEditingController _instruction = TextEditingController();
  String? _result;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _instruction.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final instruction = _instruction.text.trim();
    if (instruction.isEmpty) {
      setState(() => _error = '先写下想怎么改，例如「更嘴硬心软一点」');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final value = await widget.assistant.rewriteField(
        CharacterFieldRewriteRequest(
          base: widget.character,
          field: widget.field,
          instruction: instruction,
        ),
      );
      if (!mounted) return;
      setState(() => _result = value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('AI 改写 · ${widget.fieldLabel}',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '只生成建议，不会自动保存；替换后请点右上角「保存」。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.field == 'name') ...[
              const SizedBox(height: 8),
              Text(
                '名字会影响会话识别，建议确认后再替换。',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _instruction,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: '想怎么改？',
                hintText: '例如：更像傲娇大小姐，少一点解释，多一点动作描写',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text('原文', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              _PreviewBox(text: widget.currentValue),
              const SizedBox(height: 12),
              Text('建议', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              _PreviewBox(text: _result!),
            ],
            const SizedBox(height: 20),
            if (_result == null)
              FilledButton.icon(
                onPressed: _loading ? null : _generate,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_loading ? '生成中…' : '生成'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: const Text('放弃'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.pop(context, _result),
                      child: const Text('替换此字段'),
                    ),
                  ),
                ],
              ),
            if (_result != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : _generate,
                child: const Text('重新生成'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final String text;

  const _PreviewBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text.isEmpty ? '（空）' : text,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
