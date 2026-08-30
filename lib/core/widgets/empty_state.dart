import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 通用空态内容（文本/绘画页共用）
///
/// 配合外层"固定高内容盒 + 视口居中"布局使用：
/// 图标/标题规格统一（72 圆底 / 34 图标 / 间距 16-4-20），
/// 保证两个页面空态的视觉锚点位置完全一致。
class EmptyStateContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> samples;
  final ValueChanged<String> onSampleTap;

  const EmptyStateContent({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.samples,
    required this.onSampleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 渐变圆底图标
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
            child: Icon(icon, size: 34, color: AppTheme.brand),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppTheme.inkTertiary),
          ),
          const SizedBox(height: 20),
          // 示例 prompt
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final s in samples)
                _EmptySampleChip(label: s, onTap: () => onSampleTap(s)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 空态示例标签（自绘胶囊，与两页选择条同视觉语言，无裁字问题）
class _EmptySampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmptySampleChip({required this.label, required this.onTap});

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
            style: const TextStyle(fontSize: 12, color: AppTheme.inkSecondary),
          ),
        ),
      ),
    );
  }
}
