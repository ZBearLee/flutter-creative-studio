import 'package:flutter/material.dart';

/// 全局主题
class AppTheme {
  AppTheme._(); // 私有构造，禁止实例化

  static const Color brand = Color(0xFF5B5BD6);

  static const Color ink = Color(0xFF2A2A33); // 主文字
  static const Color inkSecondary = Color(0xFF6E6E7A); // 次文字
  static const Color inkTertiary = Color(0xFF9B9BA6); // 弱文字/占位
  static const Color paper = Color(0xFFF7F7FA); // 页面底
  static const Color card = Color(0xFFFFFFFF); // 卡片面
  static const Color line = Color(0xFFE8E8EE); // 分割线/描边

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? brand
                : inkSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? brand
                : inkSecondary,
          ),
        ),
        indicatorColor: const Color(0xFFEDEDFB),
        height: 64,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: ink),
        bodyMedium: TextStyle(color: ink),
      ),
      // 全局 chip 样式（模板条用）
      // padding：横向给足让文字不贴边，竖向收窄避免 Chip 被容器裁剪
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: const Color(0xFFEDEDFB),
        labelStyle: const TextStyle(color: inkSecondary, fontSize: 13),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
