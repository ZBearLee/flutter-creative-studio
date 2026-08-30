import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import 'image_gen_controller.dart';
import 'image_gen_state.dart';
import 'image_style.dart';

/// web 端显示用的代理地址：图床不放行跨域头，浏览器会拦截应用内加载；
/// 经 wsrv.nl 图片代理（服务端取图 + CORS 放行）转发。桌面端无 CORS 概念，直连。
String _displayUrl(String url) {
  if (!kIsWeb) return url;
  return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}';
}

/// 网络图片 Provider：web 端 NetworkImage 走代理（浏览器自带 HTTP 缓存），
/// 其他平台用 CachedNetworkImageProvider（磁盘缓存，翻旧图不重新下载）
ImageProvider _imageProvider(String url) {
  final display = _displayUrl(url);
  if (kIsWeb) return NetworkImage(display);
  return CachedNetworkImageProvider(display);
}

/// 全屏预览用组件（保持缩放布局，带加载进度）
Widget netImage(String url, {BoxFit? fit}) {
  final display = _displayUrl(url);
  if (kIsWeb) {
    return Image.network(
      display,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }
  return CachedNetworkImage(
    imageUrl: display,
    fit: fit,
    placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
  );
}

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

  /// 清空输入框（输入框右侧 × 按钮）
  void _clearPrompt() {
    _promptController.clear();
    ref.read(imageGenControllerProvider.notifier).updatePrompt('');
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
            onCleared: _clearPrompt,
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
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        // 首尾对称：左 16；右侧 = 列表末端 8 + chip 自带间距 8 = 16，
        // 拖到最右时最后一个 chip 与首个 chip 的留白一致
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final s in ImageStyle.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StyleChip(
                label: s.label,
                selected: selected == s,
                onTap: () => onSelected(s),
              ),
            ),
        ],
      ),
    );
  }
}

/// 自绘示例标签（空态示例 prompt 用，与 _StyleChip 同实现、无选中态）
class _SampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SampleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.card,
      shape: StadiumBorder(side: const BorderSide(color: AppTheme.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 自绘风格标签（不依赖 FilterChip：其内部对短 label 的宽度计算
/// 在自定义主题下可能裁字，自绘可完全控制文字留白）
class _StyleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StyleChip({
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
          // 文字四周留足空间，单字 label 也不会被切
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
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
                  size: 34,
                  color: AppTheme.brand,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '描述画面，AI 帮你画',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '选个风格，或直接输入描述',
                style: TextStyle(fontSize: 13, color: AppTheme.inkTertiary),
              ),
              const SizedBox(height: 20),
              // 示例 prompt（自绘 chip，与风格条同视觉语言，无裁字问题）
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final s in _samplePrompts)
                    _SampleChip(label: s, onTap: () => onSampleTap(s)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 列数随窗口宽度自适应：约 240px 一列，窄窗 2 列、宽屏最多 6 列，
    // 避免大屏下单张卡片超过一屏
    final crossAxisCount =
        (MediaQuery.sizeOf(context).width / 240).clamp(2, 6).toInt();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
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
        // 图片区呼吸闪烁 + 居中加载状态
        child: FadeTransition(
          opacity: Tween(begin: 0.55, end: 1.0).animate(_controller),
          child: Container(
            color: const Color(0xFFEDEDFB),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 30, color: AppTheme.brand),
                SizedBox(height: 10),
                Text(
                  'AI 正在创作…',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
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
              child: Image(
                image: _imageProvider(image.url),
                fit: BoxFit.cover,
                // 图片下载期间的占位（URL 已到但字节还在传输）
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync || frame != null) return child;
                  return Container(
                    color: const Color(0xFFEDEDFB),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, _, _) => Container(
                  color: AppTheme.paper,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  child: kIsWeb
                      ? const Text(
                          '图片加载失败\n可点击卡片，右上角打开原图',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.inkTertiary,
                          ),
                        )
                      : const Icon(
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
        child: Stack(
          children: [
            // 可双指缩放的图片主体（web 端内部走代理地址）
            Center(
              child: InteractiveViewer(
                maxScale: 5,
                child: netImage(url),
              ),
            ),
            // 右上角：查看原图（浏览器新标签打开，代理失效时的兜底）
            Positioned(
              top: 40,
              right: 16,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.open_in_new, size: 18),
                tooltip: '查看原图',
                onPressed: () =>
                    launchUrl(Uri.parse(url), webOnlyWindowName: '_blank'),
              ),
            ),
          ],
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
  final VoidCallback onCleared;

  const _InputCard({
    required this.controller,
    required this.isLoading,
    required this.onChanged,
    required this.onGenerate,
    required this.onCleared,
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
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final hasText = value.text.isNotEmpty;
                return TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.newline,
                  onChanged: onChanged,
                  style: const TextStyle(fontSize: 14, color: AppTheme.ink),
                  decoration: InputDecoration(
                    hintText: '描述你想要的画面…',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.inkTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 10,
                    ),
                    // 有文字时显示清空按钮
                    suffixIcon: hasText
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppTheme.inkTertiary,
                            ),
                            tooltip: '清空输入',
                            onPressed: onCleared,
                          )
                        : null,
                  ),
                );
              },
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
