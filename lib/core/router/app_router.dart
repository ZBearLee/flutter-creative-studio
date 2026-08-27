import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/image_gen/image_gen_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/text_gen/text_gen_page.dart';

/// 全局路由配置
final appRouter = GoRouter(
  initialLocation: '/text', // 启动默认进文本 Tab
  routes: [
    // 底部导航外壳：切换 Tab 时保留各分支状态（不重建）
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              // 切换分支；若点击的是当前 Tab，则回到该 Tab 根
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.text_fields_outlined),
                selectedIcon: Icon(Icons.text_fields),
                label: '文本',
              ),
              NavigationDestination(
                icon: Icon(Icons.image_outlined),
                selectedIcon: Icon(Icons.image),
                label: '绘画',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: '设置',
              ),
            ],
          ),
        );
      },
      branches: [
        // 三个 Tab 分支，各自独立导航栈
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/text', builder: (c, s) => const TextGenPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/image', builder: (c, s) => const ImageGenPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/settings', builder: (c, s) => const SettingsPage()),
          ],
        ),
      ],
    ),
  ],
);
