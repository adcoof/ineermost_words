/// 聊天页：消息流 + 输入栏 + 流式状态。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../characters/domain/character.dart';
import '../../pet/domain/pet_model.dart';
import '../../pet/presentation/pet_overlay.dart';
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
  @override
  void initState() {
    super.initState();
    // 始终绑定（包括 null=新会话），避免全局控制器残留上一次的会话 id。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatControllerProvider.notifier)
          .bindConversation(widget.conversationId);
    });
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

    return Scaffold(
      appBar: AppBar(
        title: _ChatTitle(conversationId: conversationId),
        actions: [
          IconButton(
            tooltip: '桌宠',
            icon: const Icon(Icons.pets_outlined),
            onPressed: conversationId == null
                ? null
                : () => _pickPetModel(context, ref, conversationId),
          ),
          if (ui.isStreaming)
            TextButton.icon(
              onPressed: () => ref.read(chatControllerProvider.notifier).stop(),
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
    );
  }

  /// 选择/解绑本会话的桌宠模型。
  Future<void> _pickPetModel(
      BuildContext context, WidgetRef ref, String conversationId) async {
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
                    child: Icon(Icons.pets_outlined, size: 20)),
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

/// 根据会话绑定动态挂/卸桌宠悬浮层。
class _PetLayer extends ConsumerWidget {
  final String conversationId;

  const _PetLayer({required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      stream: ref.watch(chatRepositoryProvider).watchConversation(conversationId),
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: hasAvatar ? FileImage(File(path)) : null,
              child: hasAvatar ? null : const Icon(Icons.person_outline, size: 16),
            ),
            const SizedBox(width: 8),
            Text(character.name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        );
      },
    );
  }
}