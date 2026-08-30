import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/empty_state.dart';
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
  // 模板条横向滚动控制器（切 Tab 后归零）
  final _barController = ScrollController();
  var _tabVisible = true;

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    _barController.dispose();
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

    // Tab 切走感知：IndexedStack 非激活分支的 TickerMode 会被关闭，
    // 检测到可见 → 不可见时重置模板选择 + 模板条滚动归零（切回来不残留）
    final tabVisible = TickerMode.of(context);
    if (_tabVisible && !tabVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(textGenControllerProvider.notifier).resetSelection();
        if (_barController.hasClients) {
          _barController.jumpTo(0);
        }
      });
    }
    _tabVisible = tabVisible;

    // 监听 state 变化：错误提示 + 输出滚动
    ref.listen<TextGenState>(textGenControllerProvider, (prev, next) {
      // 用 token 判断"新的错误事件"（同一错误连发两次文字不变，但 token 会变）
      if (next.error != null && next.errorToken != prev?.errorToken) {
        AppToast.show(context, next.error!);
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
            scrollController: _barController,
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
  final ScrollController? scrollController;
  final PromptTemplate? selected;
  final ValueChanged<PromptTemplate?> onSelected;

  const _TemplateBar({
    this.scrollController,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        // 首尾对称：左 16；右侧 = 列表末端 8 + chip 自带间距 8 = 16
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final t in PromptTemplate.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TemplateChip(
                label: t.label,
                selected: selected?.id == t.id,
                onTap: () => onSelected(t),
              ),
            ),
        ],
      ),
    );
  }
}

/// 自绘模板标签（与绘画页 _StyleChip 同实现：不依赖 FilterChip，
/// 其内部对短 label 的宽度计算在自定义主题下可能裁字）
class _TemplateChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEDEDFB) : AppTheme.card,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppTheme.brand : AppTheme.line,
          width: selected ? 1.2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // 文字四周留足空间，短 label 也不会被切
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? AppTheme.brand : AppTheme.inkSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
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
    // 空态：固定高内容盒（340）在视口居中（与绘画页同布局策略）。
    // 盒子高度恒定 → 图标/标题位置两页完全一致，且不随示例 chips
    // 换行行数变化；窗口过矮时内容可滚动。
    if (state.output.isEmpty && !state.isLoading) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 340),
                child: EmptyStateContent(
                  icon: Icons.auto_awesome,
                  title: '描述你的想法，AI 帮你写',
                  subtitle: '选个风格模板，或直接输入内容',
                  samples: _samplePrompts,
                  onSampleTap: onSampleTap,
                ),
              ),
            ),
          ),
        ],
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
