import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'image_gen_controller.dart';
import 'image_gen_state.dart';
import 'image_style.dart';

/// 示例 prompt（空状态点击直接填入输入框）
const _samplePrompts = ['一只戴眼镜的橘猫在看书', '夕阳下的江南水乡小巷', '宇航员在月球上喝咖啡', '开满樱花的城市街道'];

class ImageGenPage extends ConsumerStatefulWidget {
  const ImageGenPage({super.key});

  @override
  ConsumerState<ImageGenPage> createState() => _ImageGenPageState();
}

class _ImageGenPageState extends ConsumerState<ImageGenPage> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _onGenerate() {
    if (ref.read(imageGenControllerProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    _promptController.clear();
    ref.read(imageGenControllerProvider.notifier).generate();
  }

  void _fillSample(String sample) {
    _promptController.text = sample;
    ref.read(imageGenControllerProvider.notifier).updatePrompt(sample);
  }

  void _showPreview(GeneratedImage image) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => _ImageFullScreen(url: image.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageGenControllerProvider);

    ref.listen<ImageGenState>(imageGenControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('绘画'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空画廊',
            onPressed: state.isLoading || state.images.isEmpty
                ? null
                : () => ref
                      .read(imageGenControllerProvider.notifier)
                      .clearImages(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 风格选择条
          _StyleBar(
            selected: state.selectedStyle,
            onSelected: (s) =>
                ref.read(imageGenControllerProvider.notifier).selectStyle(s),
          ),

          // 画廊
          Expanded(
            child: _Gallery(
              state: state,
              onSampleTap: _fillSample,
              onImageTap: _showPreview,
            ),
          ),

          // 底部输入卡片（与文本页同形态）
          _InputCard(
            controller: _promptController,
            isLoading: state.isLoading,
            onChanged: (v) =>
                ref.read(imageGenControllerProvider.notifier).updatePrompt(v),
            onGenerate: _onGenerate,
          ),
        ],
      ),
    );
  }
}

/// 风格横向选择条
class _StyleBar extends StatelessWidget {
  final ImageStyle selected;
  final ValueChanged<ImageStyle> onSelected;

  const _StyleBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          for (final s in ImageStyle.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s.label),
                selected: selected == s,
                onSelected: (_) => onSelected(s),
                labelStyle: TextStyle(
                  color: selected == s ? AppTheme.brand : AppTheme.inkSecondary,
                  fontSize: 13,
                  fontWeight: selected == s ? FontWeight.w600 : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 画廊区：空态 / 骨架占位 + 网格
class _Gallery extends StatelessWidget {
  final ImageGenState state;
  final ValueChanged<String> onSampleTap;
  final ValueChanged<GeneratedImage> onImageTap;

  const _Gallery({
    required this.state,
    required this.onSampleTap,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    // 空态
    if (state.images.isEmpty && !state.isLoading) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEDEDFB), Color(0xFFF7F7FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.palette_outlined,
                  size: 40,
                  color: AppTheme.brand,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '描述画面，AI 帮你画',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '选个风格，或直接输入描述',
                style: TextStyle(fontSize: 13, color: AppTheme.inkTertiary),
              ),
              const SizedBox(height: 28),
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

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85, // 卡片含 prompt 小字
      ),
      itemCount: state.images.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // 生成中：第一格插骨架占位卡
        if (state.isLoading && index == 0) {
          return const _SkeletonCard();
        }
        final img = state.images[state.isLoading ? index - 1 : index];
        return _ImageCard(image: img, onTap: () => onImageTap(img));
      },
    );
  }
}

/// 生成中的骨架占位卡（不用转圈）
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // 图片区呼吸闪烁
            Expanded(
              child: FadeTransition(
                opacity: Tween(begin: 0.55, end: 1.0).animate(_controller),
                child: Container(color: const Color(0xFFEDEDFB)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: AppTheme.brand),
                  SizedBox(width: 6),
                  Text(
                    '生成中…',
                    style: TextStyle(fontSize: 12, color: AppTheme.inkTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 画廊图片卡
class _ImageCard extends StatelessWidget {
  final GeneratedImage image;
  final VoidCallback onTap;

  const _ImageCard({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: image.url,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: const Color(0xFFEDEDFB),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  color: AppTheme.paper,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.inkTertiary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                image.prompt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 全屏预览（可双指缩放）
class _ImageFullScreen extends StatelessWidget {
  final String url;

  const _ImageFullScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: InteractiveViewer(
          maxScale: 5,
          child: Center(child: CachedNetworkImage(imageUrl: url)),
        ),
      ),
    );
  }
}

/// 底部悬浮输入卡片（与文本页同形态：白卡 16 圆角 + 44px 按钮）
class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onGenerate;

  const _InputCard({
    required this.controller,
    required this.isLoading,
    required this.onChanged,
    required this.onGenerate,
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
              maxLines: 3,
              enabled: !isLoading,
              textInputAction: TextInputAction.newline,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: AppTheme.ink),
              decoration: const InputDecoration(
                hintText: '描述你想要的画面…',
                hintStyle: TextStyle(fontSize: 14, color: AppTheme.inkTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton.filled(
              onPressed: isLoading ? null : onGenerate,
              icon: const Icon(Icons.auto_awesome, size: 20),
              tooltip: '生成',
            ),
          ),
        ],
      ),
    );
  }
}
