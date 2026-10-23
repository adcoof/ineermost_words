/// MaterialApp 装配：启动过渡页 + 会话 / 角色 / 桌宠 / 设置 四页导航壳。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/presentation/conversation_list_page.dart';
import '../features/characters/presentation/character_list_page.dart';
import '../features/pet/presentation/pet_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/voice/presentation/voice_error_listener.dart';
import 'providers.dart';
import 'splash_page.dart';
import 'theme.dart';

class AiRoleplayApp extends ConsumerWidget {
  const AiRoleplayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 强调色跟随设置（未加载期间用默认霓虹紫）。
    final accent =
        ref.watch(themeAccentProvider).value ?? BrandColors.violet;
    return MaterialApp(
      title: '心语',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(accent),
      themeMode: ThemeMode.dark,
      home: SplashPage(next: const _MainShell()),
    );
  }
}

/// 主界面壳：四页切换 + 底部导航。
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VoiceErrorListener(
        child: IndexedStack(
          index: _index,
          children: const [
            ConversationListPage(),
            CharacterListPage(),
            PetPage(),
            SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: '会话'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: '角色'),
          NavigationDestination(
              icon: Icon(Icons.pets_outlined), label: '桌宠'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: '设置'),
        ],
      ),
    );
  }
}
