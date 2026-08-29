import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'dio_client.dart';

/// 文本生成用的 Dio 客户端
///
/// 通过 [AppConfig.llmBaseUrl] + [AppConfig.llmApiKey] 构造，
/// 切换 AI 提供商只需改环境变量，无需改代码。
final textGenDioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: AppConfig.llmBaseUrl,
    apiKey: AppConfig.llmApiKey,
  );
});
