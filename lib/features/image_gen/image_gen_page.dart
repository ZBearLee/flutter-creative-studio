import 'package:flutter/material.dart';

/// AI 绘画 / 文生图页（占位，后续接入文生图 API + 任务轮询）
class ImageGenPage extends StatelessWidget {
  const ImageGenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 绘画')),
      body: const Center(child: Text('文生图（待实现）')),
    );
  }
}
