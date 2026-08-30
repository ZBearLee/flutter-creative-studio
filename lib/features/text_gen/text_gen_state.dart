import 'prompt_template.dart';

/// 一条文本生成历史（成功生成一次记一条，新在前）
class TextHistoryItem {
  /// 用户输入的原始 prompt
  final String prompt;

  /// 生成结果全文
  final String output;

  /// 当时使用的模板（null 表示未用模板）
  final PromptTemplate? template;

  /// 生成时间
  final DateTime createdAt;

  const TextHistoryItem({
    required this.prompt,
    required this.output,
    this.template,
    required this.createdAt,
  });
}

/// 文本生成页状态
///
/// 不可变：所有变更通过 [copyWith] 产生新实例，Riverpod 自动触发 UI 重建。
class TextGenState {
  /// 历史记录（新在前，由 [TextHistoryStore] 持久化，重启恢复）
  final List<TextHistoryItem> history;

  /// 正在查看的历史条目（null 表示不在"查看历史"模式）
  final TextHistoryItem? viewingHistory;
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
    this.history = const [],
    this.viewingHistory,
    this.prompt = '',
    this.output = '',
    this.isLoading = false,
    this.error,
    this.errorToken = 0,
    this.selectedTemplate,
  });

  TextGenState copyWith({
    List<TextHistoryItem>? history,
    TextHistoryItem? viewingHistory,
    String? prompt,
    String? output,
    bool? isLoading,
    String? error,
    PromptTemplate? selectedTemplate,
    bool clearError = false,
    bool clearTemplate = false,
    bool clearViewing = false,
  }) {
    return TextGenState(
      history: history ?? this.history,
      viewingHistory:
          clearViewing ? null : (viewingHistory ?? this.viewingHistory),
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
