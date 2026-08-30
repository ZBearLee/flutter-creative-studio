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

  /// 错误事件计数：每次设置新 error 时 +1。
  /// UI 不能只比较 error 文字（同一错误连发两次不会触发提示），
  /// 用 token 才能把"值变化"和"事件发生"区分开。
  final int errorToken;

  /// 当前选中的模板（null 表示不使用模板，直接发原文）
  final PromptTemplate? selectedTemplate;

  const TextGenState({
    this.prompt = '',
    this.output = '',
    this.isLoading = false,
    this.error,
    this.errorToken = 0,
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
      errorToken: clearError
          ? 0
          : (error != null ? errorToken + 1 : errorToken),
      selectedTemplate:
          clearTemplate ? null : (selectedTemplate ?? this.selectedTemplate),
    );
  }
}
