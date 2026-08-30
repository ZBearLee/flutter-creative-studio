import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 全局轻提示 toast（业界 web 端普遍做法，参考 AntD/Element Message）：
/// - 位置：顶部居中（避开 AppBar 往下一档），非底部
/// - 尺寸：按内容收缩，最大宽 420 —— 短文案是小短条，不铺满屏
/// - 视觉：深色圆角浮条 + 轻投影，2.6s 自动淡出
/// - 重复触发：新提示直接替换旧的（不叠加）
///
/// 不用 SnackBar：其 floating 模式尺寸始终撑满可用宽（减 margin），
/// 无法实现"按内容收缩"，宽屏下必然拉成长条。
class AppToast {
  static OverlayEntry? _entry;

  static void show(BuildContext context, String message) {
    // 替换旧 toast
    _entry?.remove();
    _entry = null;

    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        onDismissed: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;

  const _ToastWidget({required this.message, required this.onDismissed});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> {
  var _opacity = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 首帧后淡入
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1.0);
    });
    _timer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _opacity = 0.0);
      // 淡出动画结束后移除 overlay
      Timer(const Duration(milliseconds: 200), widget.onDismissed);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // 顶部居中：AppBar(56) + 16 间距
      top: 72,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 180),
            child: Material(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(10),
              elevation: 6,
              shadowColor: Colors.black38,
              child: ConstrainedBox(
                // 关键：黑条宽度由内容决定，上限 420
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
