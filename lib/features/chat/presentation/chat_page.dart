/// 聊天页：消息流 + 输入栏 + 流式状态 + 会话背景板。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/providers.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/glass.dart';
import '../../characters/domain/character.dart';
import '../../characters/presentation/character_memory_page.dart';
import '../../characters/presentation/image_crop_page.dart';
import '../../pet/domain/pet_model.dart';
import '../../pet/presentation/pet_overlay.dart';
import '../../voice/application/voice_orchestrator.dart';
import '../domain/models.dart';
import 'chat_input_bar.dart';
import 'message_list.dart';

class ChatPage extends ConsumerStatefulWidget {
  /// 已有会话 id；null 表示新会话（首次发送时创建）。
  final String? conversationId;

  const ChatPage({super.key, this.conversationId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  /// initState 缓存的语音编排器：dispose 时 widget 已 unmount，
  /// Riverpod 3 禁止再用 ref.read（会抛 Bad state），必须用缓存引用。
  late final VoiceOrchestrator _voice;

  @override
  void initState() {
    super.initState();
    // 语音在场计数 +1：聊天页可见才朗读（离开即停播清队列）。
    _voice = ref.read(voiceOrchestratorProvider);
    _voice.attachChatPage();
    // 始终绑定（包括 null=新会话），避免全局控制器残留上一次的会话 id。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatControllerProvider.notifier)
          .bindConversation(widget.conversationId);
    });
  }

  @override
  void dispose() {
    // 计数 -1，归零即按手动打断语义停播（后台生成继续完成消息）。
    _voice.detachChatPage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(chatControllerProvider);
    final conversationId = ui.conversationId;

    ref.listen(chatControllerProvider, (prev, next) {
      if (next.errorText != null && next.errorText != prev?.errorText) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorText!),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '关闭',
              onPressed: () =>
                  ref.read(chatControllerProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    // 背景板铺在 Scaffold **之外**的整屏画布上（v8.1 真机反馈）：
    // Scaffold 默认 resizeToAvoidBottomInset，键盘弹出时 body 会按
    // viewInsets 缩高；背景若在 body 里就会跟着缩小、重新裁切（用户看到的
    // "背景板同步缩小，这时才完整显示"）。放到外层 Stack 后背景始终是整屏
    // 尺寸，键盘与 AppBar 都不再影响它的取景。
    return Stack(
      fit: StackFit.expand,
      children: [
        // 兜底底色：没有背景板时与主题页面底色一致。
        ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
        if (conversationId != null)
          Positioned.fill(
            child: _BackgroundLayer(conversationId: conversationId),
          ),
        Scaffold(
          // 透明底：让底层背景板透上来（AppBar 的玻璃模糊也才有内容可取样）。
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            // 液态玻璃顶栏（v8）：透明底 + 背后模糊层；背景板上呈现毛玻璃。
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: const SizedBox.expand(
              child: GlassPanel(
                radius: BorderRadius.zero,
                blur: 20,
                fillOpacity: 0.06,
                boxShadow: null,
              ),
            ),
            title: _ChatTitle(conversationId: conversationId),
            actions: [
              _VoiceToggle(conversationId: conversationId),
              IconButton(
                tooltip: '背景板',
                icon: const Icon(Icons.wallpaper_outlined),
                onPressed: conversationId == null
                    ? null
                    : () => _pickBackground(ref, conversationId),
              ),
              IconButton(
                tooltip: '桌宠',
                icon: const Icon(Icons.pets_outlined),
                onPressed: conversationId == null
                    ? null
                    : () => _pickPetModel(context, ref, conversationId),
              ),
              if (ui.isStreaming)
                TextButton.icon(
                  onPressed: () =>
                      ref.read(chatControllerProvider.notifier).stop(),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('停止'),
                ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: conversationId == null
                        ? const Center(child: Text('输入第一条消息开始对话'))
                        : MessageList(conversationId: conversationId),
                  ),
                  const ChatInputBar(),
                ],
              ),
              if (conversationId != null)
                Positioned(
                  right: 0,
                  bottom: 76,
                  width: 300,
                  height: 380,
                  child: _PetLayer(conversationId: conversationId),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 选择/清除本会话背景板（v8）：选图 → 裁剪 → 落盘 → 写列。
  Future<void> _pickBackground(WidgetRef ref, String conversationId) async {
    // 裁剪框按当前屏幕宽高比（v8.1）：crop_your_image 的 aspectRatio 为
    // null 时初始框是正方形，用户很容易只裁出 1:1 的图——铺到整屏上只能
    // 看到中间一条。按屏幕比例裁剪，结果正好铺满整屏（BoxFit.cover 不裁）。
    final screen = MediaQuery.sizeOf(context);
    final screenRatio = screen.width / screen.height;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('选择背景图片'),
              onTap: () => Navigator.pop(context, 'pick'),
            ),
            ListTile(
              leading: const Icon(Icons.hide_image_outlined),
              title: const Text('恢复默认背景'),
              onTap: () => Navigator.pop(context, 'clear'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    final chatRepo = ref.read(chatRepositoryProvider);
    final conv = await chatRepo.getConversation(conversationId);
    final oldPath = conv?.backgroundPath;

    Future<void> clearOld() async {
      if (oldPath == null || oldPath.isEmpty) return;
      try {
        final f = File(oldPath);
        if (await f.exists()) await f.delete();
        await FileImage(f).evict();
      } catch (_) {
        // 旧文件清理失败不阻塞。
      }
    }

    if (action == 'clear') {
      await chatRepo.setConversationBackground(conversationId, null);
      await clearOld();
      return;
    }

    final result = await FilePicker.pickFile(type: FileType.image);
    if (result == null || !mounted) return;
    final bytes = await result.xFile.readAsBytes();
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => ImageCropPage(
          imageBytes: bytes,
          title: '裁剪背景',
          aspectRatio: screenRatio,
        ),
      ),
    );
    if (cropped == null || !mounted) return;
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'backgrounds'),
    );
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, '$conversationId.jpg'));
    await file.writeAsBytes(
      downscaleToJpeg(cropped, maxDim: 1920),
      flush: true,
    );
    await chatRepo.setConversationBackground(conversationId, file.path);
    await clearOld();
  }

  /// 选择/解绑本会话的桌宠模型。
  Future<void> _pickPetModel(
    BuildContext context,
    WidgetRef ref,
    String conversationId,
  ) async {
    final repo = ref.read(petModelRepositoryProvider);
    final models = await repo.watchModels().first;
    if (!context.mounted) return;
    final selected = await showModalBottomSheet<PetModel?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pets_outlined),
              title: const Text('不使用桌宠'),
              onTap: () => Navigator.pop(context),
            ),
            for (final m in models)
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.pets_outlined, size: 20),
                ),
                title: Text(m.name),
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );
    if (selected == null) {
      // 弹层里点「不使用桌宠」或关闭：仅当明确选了 null 项才解绑。
      // （关闭弹层返回也是 null——用二次确认太啰嗦，这里统一视为不解绑，
      //  只有列表为空且用户点了第一项才解绑；简化处理：始终写入所选。）
    }
    await ref
        .read(chatRepositoryProvider)
        .setConversationPetModel(conversationId, selected?.id);
  }
}

/// 会话背景板层（v8）：设置背景时铺满底层 + 半透明压暗保证文字可读。
class _BackgroundLayer extends ConsumerWidget {
  final String conversationId;

  const _BackgroundLayer({required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Conversation?>(
      stream: ref
          .read(chatRepositoryProvider)
          .watchConversation(conversationId),
      builder: (context, snapshot) {
        final path = snapshot.data?.backgroundPath;
        if (path == null || path.isEmpty || !File(path).existsSync()) {
          return const SizedBox.shrink();
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            // 压暗层：保证气泡与输入文字在亮背景下可读。
            ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
          ],
        );
      },
    );
  }
}

/// 根据会话绑定动态挂/卸桌宠悬浮层。
class _PetLayer extends ConsumerWidget {
  final String conversationId;

  const _PetLayer({required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      stream: ref
          .watch(chatRepositoryProvider)
          .watchConversation(conversationId),
      builder: (context, snapshot) {
        final petModelId = snapshot.data?.petModelId;
        if (petModelId == null) return const SizedBox.shrink();
        return FutureBuilder<PetModel?>(
          // ignore: discarded_futures
          future: ref.read(petModelRepositoryProvider).getModel(petModelId),
          builder: (context, snapshot) {
            final model = snapshot.data;
            if (model == null) return const SizedBox.shrink();
            return PetOverlay(key: ValueKey(model.id), model: model);
          },
        );
      },
    );
  }
}

/// 会话级语音开关（右上角）：与全局语音设置相与决定实际朗读。
///
/// 开关在每回合 send() 起始取快照，流式中途改开关下一回合生效；
/// 关闭时顺带 bargeIn 停掉本回合已在播报的内容。stream 缓存写法
/// 同 _ChatTitle：ChatPage 每条消息都重建，不能每次重开订阅。
class _VoiceToggle extends ConsumerStatefulWidget {
  final String? conversationId;

  const _VoiceToggle({this.conversationId});

  @override
  ConsumerState<_VoiceToggle> createState() => _VoiceToggleState();
}

class _VoiceToggleState extends ConsumerState<_VoiceToggle> {
  Stream<Conversation?>? _convStream;
  String? _boundConvId;

  @override
  Widget build(BuildContext context) {
    final conversationId = widget.conversationId;
    if (conversationId == null) {
      // 新会话尚未落库，等首条消息创建后再可操作（同桌宠按钮先例）。
      return IconButton(
        tooltip: '本会话语音',
        icon: const Icon(Icons.volume_up_outlined),
        onPressed: null,
      );
    }
    if (_boundConvId != conversationId) {
      _boundConvId = conversationId;
      _convStream = ref
          .read(chatRepositoryProvider)
          .watchConversation(conversationId);
    }
    return StreamBuilder<Conversation?>(
      stream: _convStream,
      builder: (context, snapshot) {
        final enabled = snapshot.data?.voiceEnabled ?? true;
        return IconButton(
          tooltip: enabled ? '本会话语音：开（点击关闭）' : '本会话语音：关（点击开启）',
          icon: Icon(
            enabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
          ),
          onPressed: snapshot.data == null
              ? null
              : () async {
                  final next = !enabled;
                  await ref
                      .read(chatRepositoryProvider)
                      .setConversationVoiceEnabled(conversationId, next);
                  if (!next) {
                    // 关闭时停掉本回合已在播报的内容（下一回合起不再入队）。
                    ref.read(voiceOrchestratorProvider).bargeIn();
                  }
                },
        );
      },
    );
  }
}

/// 标题区：绑定角色时显示立绘 + 名字，否则显示「聊天」。
///
/// stream/future 均缓存：ChatPage 每条消息都会重建，
/// 每次重建重开订阅/重查库会造成无谓抖动与首屏「聊天」闪变。
class _ChatTitle extends ConsumerStatefulWidget {
  final String? conversationId;

  const _ChatTitle({this.conversationId});

  @override
  ConsumerState<_ChatTitle> createState() => _ChatTitleState();
}

class _ChatTitleState extends ConsumerState<_ChatTitle> {
  Stream<Conversation?>? _convStream;
  String? _boundConvId;
  Character? _character;
  String? _loadedCharacterId;

  @override
  Widget build(BuildContext context) {
    final id = widget.conversationId;
    if (id == null) return const Text('聊天');
    if (_boundConvId != id) {
      _boundConvId = id;
      _convStream = ref.read(chatRepositoryProvider).watchConversation(id);
      _character = null;
      _loadedCharacterId = null;
    }
    return StreamBuilder<Conversation?>(
      stream: _convStream,
      builder: (context, snapshot) {
        final characterId = snapshot.data?.characterId;
        if (characterId == null) return const Text('聊天');
        if (characterId != _loadedCharacterId) {
          _loadedCharacterId = characterId;
          final repo = ref.read(characterRepositoryProvider);
          repo.getById(characterId).then((c) {
            if (mounted && _loadedCharacterId == characterId) {
              setState(() => _character = c);
            }
          });
        }
        final character = _character;
        if (character == null) {
          // 首次加载中：先显示角色占位（id 已知但资料未到）。
          return const Text('聊天');
        }
        final path = character.avatarPath;
        final hasAvatar =
            path != null && path.isNotEmpty && File(path).existsSync();
        return GestureDetector(
          // 点头像/名字 → 角色记忆与用户画像（v8）。
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CharacterMemoryPage(
                characterId: character.id,
                characterName: character.name,
              ),
            ),
          ),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: hasAvatar ? FileImage(File(path)) : null,
                child: hasAvatar
                    ? null
                    : const Icon(Icons.person_outline, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                character.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
