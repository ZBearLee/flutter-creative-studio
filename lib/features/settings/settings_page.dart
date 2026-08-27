import 'package:flutter/material.dart';

/// 设置页（占位，后续放 API-Key 配置、模型切换、清历史）
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: const Center(child: Text('设置（待实现）')),
    );
  }
}
