import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // 私有构造，禁止实例化

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4B3FE3), // 紫色主调，和AIGC概念图呼应
      brightness: Brightness.light,
    ),
  );
}
