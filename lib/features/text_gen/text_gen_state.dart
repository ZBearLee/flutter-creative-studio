import 'prompt_template.dart';

/// 文本生成页状态
///
/// 不可变：所有变更通过 [copyWith] 产生新实例，Riverpod 自动触发 UI 重建。
class TextGenState {
  /// 用户输入的原始 prompt
  final String prompt;

  /// AI 流式输出内容（逐字追加）
  final String output;

  /// 是否正在生成（控制发送/停止按钮 + 骨架屏）
  final bool isLoading;

  /// 错误信息（非 null 时 UI 显示 SnackBar 提示）
  final String? error;

  /// 当前选中的模板（null 表示不使用模板，直接发原文）
  final PromptTemplate? selectedTemplate;

  const TextGenState({
    this.prompt = '',
    this.output = '',
    this.isLoading = false,
    this.error,
    this.selectedTemplate,
  });

  TextGenState copyWith({
    String? prompt,
    String? output,
    bool? isLoading,
    String? error,
    PromptTemplate? selectedTemplate,
    bool clearError = false,
    bool clearTemplate = false,
  }) {
    return TextGenState(
      prompt: prompt ?? this.prompt,
      output: output ?? this.output,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedTemplate:
          clearTemplate ? null : (selectedTemplate ?? this.selectedTemplate),
    );
  }
}
