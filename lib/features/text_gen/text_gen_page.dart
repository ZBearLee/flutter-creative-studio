import 'package:flutter/material.dart';

/// 文本生成页（占位，后续接入流式输出）
class TextGenPage extends StatelessWidget {
  const TextGenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('文本生成')),
      body: const Center(child: Text('文本生成（待实现）')),
    );
  }
}
