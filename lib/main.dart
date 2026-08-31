import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 从项目根 .env 加载 API Key 等配置（文件不存在时静默跳过，
  // Key 走 dart-define 兜底；.env 已进 .gitignore 不会提交）
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  runApp(const ProviderScope(child: MyApp()));
}
