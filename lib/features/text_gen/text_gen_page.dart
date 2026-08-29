import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'prompt_template.dart';
import 'text_gen_controller.dart';
import 'text_gen_state.dart';

/// 示例 prompt（空状态点击直接填入输入框）
const _samplePrompts = [
  '写一首关于秋天的短诗',
  '给一家咖啡店起 5 个名字',
  '用一句话解释什么是 AI',
  '帮我把这句话翻译成英文：今天天气真好',
];

class TextGenPage extends ConsumerStatefulWidget {
  const TextGenPage({super.key});

  @override
  ConsumerState<TextGenPage> createState() => _TextGenPageState();
}

class _TextGenPageState extends ConsumerState<TextGenPage> {
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动输出区到底部（流式追加新字后自动滚）
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
  }

  void _onSend() {
    final state = ref.read(textGenControllerProvider);
    if (state.isLoading) return;
    FocusScope.of(context).unfocus(); // 收起键盘
    _promptController.clear(); // 发送后清空输入框
    ref.read(textGenControllerProvider.notifier).generate();
  }

  void _onStop() {
    ref.read(textGenControllerProvider.notifier).stop();
  }

  void _onClear() {
    _promptController.clear();
    ref.read(textGenControllerProvider.notifier).clear();
  }

  void _fillSample(String sample) {
    _promptController.text = sample;
    ref.read(textGenControllerProvider.notifier).updatePrompt(sample);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(textGenControllerProvider);

    // 监听 state 变化：错误提示 + 输出滚动
    ref.listen<TextGenState>(textGenControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (next.output != prev?.output) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('文本生成'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空',
            onPressed: state.isLoading ? null : _onClear,
          ),
        ],
      ),
      body: Column(
        children: [
          // 模板选择条（横向滚动）
          _TemplateBar(
            selected: state.selectedTemplate,
            onSelected: (t) => ref
                .read(textGenControllerProvider.notifier)
                .selectTemplate(t),
          ),

          // 输出区（可滚动）
          Expanded(
            child: _OutputArea(
              state: state,
              scrollController: _scrollController,
              onSampleTap: _fillSample,
            ),
          ),

          // 底部悬浮输入卡片
          _InputCard(
            controller: _promptController,
            isLoading: state.isLoading,
            onChanged: (v) =>
                ref.read(textGenControllerProvider.notifier).updatePrompt(v),
            onSend: _onSend,
            onStop: _onStop,
          ),
        ],
      ),
    );
  }
}

/// 模板横向选择条
class _TemplateBar extends StatelessWidget {
  final PromptTemplate? selected;
  final ValueChanged<PromptTemplate?> onSelected;

  const _TemplateBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          for (final t in PromptTemplate.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(t.label),
                selected: selected?.id == t.id,
                onSelected: (_) => onSelected(t),
                labelStyle: TextStyle(
                  color: selected?.id == t.id
                      ? AppTheme.brand
                      : AppTheme.inkSecondary,
                  fontSize: 13,
                  fontWeight: selected?.id == t.id ? FontWeight.w600 : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 输出区域：空态（带示例）/ 流式文本
class _OutputArea extends StatelessWidget {
  final TextGenState state;
  final ScrollController scrollController;
  final ValueChanged<String> onSampleTap;

  const _OutputArea({
    required this.state,
    required this.scrollController,
    required this.onSampleTap,
  });

  @override
  Widget build(BuildContext context) {
    // 空态：插画感 + 示例 prompt
    if (state.output.isEmpty && !state.isLoading) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 渐变圆底图标
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEDEDFB), Color(0xFFF7F7FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: AppTheme.brand,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '描述你的想法，AI 帮你写',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '选个风格模板，或直接输入内容',
                style: TextStyle(fontSize: 13, color: AppTheme.inkTertiary),
              ),
              const SizedBox(height: 28),
              // 示例 prompt
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final s in _samplePrompts)
                    ActionChip(
                      label: Text(s),
                      onPressed: () => onSampleTap(s),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.inkSecondary,
                      ),
                      backgroundColor: AppTheme.card,
                      side: const BorderSide(color: AppTheme.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            state.output,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: AppTheme.ink,
            ),
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: _BlinkingDot(),
            ),
        ],
      ),
    );
  }
}

/// 流式生成中的闪烁光标
class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Text(
        '●',
        style: TextStyle(color: AppTheme.brand, fontSize: 12),
      ),
    );
  }
}

/// 底部悬浮输入卡片（ChatGPT/豆包形态）
class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const _InputCard({
    required this.controller,
    required this.isLoading,
    required this.onChanged,
    required this.onSend,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A2A33).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              enabled: !isLoading,
              textInputAction: TextInputAction.newline,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.ink,
              ),
              decoration: InputDecoration(
                hintText: '输入要生成的内容…',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.inkTertiary,
                ),
                border: InputBorder.none, // 无边框，卡片本身就是容器
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 发送/停止按钮（位置稳定，44px 固定）
          SizedBox(
            width: 44,
            height: 44,
            child: isLoading
                ? IconButton.filled(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop, size: 20),
                    tooltip: '停止',
                    style: const ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll(AppTheme.ink),
                    ),
                  )
                : IconButton.filled(
                    onPressed: onSend,
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    tooltip: '发送',
                  ),
          ),
        ],
      ),
    );
  }
}
