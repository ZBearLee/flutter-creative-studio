import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 全局应用配置
///
/// 所有 AI 服务配置从项目根 `.env` 文件读取（运行时），代码零厂商耦合：
/// ```ini
/// LLM_BASE_URL=https://...    # OpenAI 兼容接口地址
/// LLM_MODEL=...               # 模型名
/// LLM_API_KEY=sk-...          # 密钥
/// ```
/// 换厂商/换模型只改 .env，不动代码。
class AppConfig {
  AppConfig._(); // 禁止实例化

  /// 安全读取 .env 变量：未初始化（load 失败/未调用）时返回 null 而不是抛异常
  static String? _dotenv(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      return null; // DotEnv 未初始化
    }
  }

  /// OpenAI 兼容接口地址
  static String get llmBaseUrl => _dotenv('LLM_BASE_URL') ?? '';

  /// 默认对话模型（空串时由调用方决定兜底行为）
  static String get llmModel => _dotenv('LLM_MODEL') ?? '';

  /// API 密钥
  static String get llmApiKey => _dotenv('LLM_API_KEY') ?? '';

  /// Key 是否已配置（用于 UI 提示）
  static bool get hasLlmApiKey => llmApiKey.isNotEmpty;

  // ---------- 文生图配置（同为中性命名，与 LLM 独立可指向不同服务） ----------

  /// 文生图接口地址
  static String get imageBaseUrl => _dotenv('IMAGE_BASE_URL') ?? '';

  /// 文生图模型名
  static String get imageModel => _dotenv('IMAGE_MODEL') ?? '';

  /// 文生图 API 密钥
  static String get imageApiKey => _dotenv('IMAGE_API_KEY') ?? '';

  /// 文生图配置是否齐全
  static bool get hasImageConfig =>
      imageApiKey.isNotEmpty && imageBaseUrl.isNotEmpty && imageModel.isNotEmpty;
}
