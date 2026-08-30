import '../../core/config/app_config.dart';

/// 运行时设置（覆盖 .env 默认值，本地持久化，重启恢复）
///
/// 设计原则：
/// - API Key / 接口地址只在 .env 配置（敏感信息隔离），设置页仅展示状态
/// - 模型名、温度可运行时调整：覆盖值优先，留空回退 .env
class SettingsState {
  /// 文本模型覆盖名（空 = 使用 .env 的 LLM_MODEL）
  final String llmModelOverride;

  /// 绘画模型覆盖名（空 = 使用 .env 的 IMAGE_MODEL）
  final String imageModelOverride;

  /// 生成温度 0.0 - 1.5（仅文本生成生效；越低越稳定，越高越发散）
  final double temperature;

  const SettingsState({
    this.llmModelOverride = '',
    this.imageModelOverride = '',
    this.temperature = 0.7,
  });

  /// 实际生效的文本模型名（覆盖值优先，回退 .env）
  String get effectiveLlmModel =>
      llmModelOverride.isNotEmpty ? llmModelOverride : AppConfig.llmModel;

  /// 实际生效的绘画模型名
  String get effectiveImageModel =>
      imageModelOverride.isNotEmpty ? imageModelOverride : AppConfig.imageModel;

  SettingsState copyWith({
    String? llmModelOverride,
    String? imageModelOverride,
    double? temperature,
  }) {
    return SettingsState(
      llmModelOverride: llmModelOverride ?? this.llmModelOverride,
      imageModelOverride: imageModelOverride ?? this.imageModelOverride,
      temperature: temperature ?? this.temperature,
    );
  }
}
