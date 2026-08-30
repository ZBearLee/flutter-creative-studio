import 'package:flutter/foundation.dart';

import 'image_style.dart';

/// 画廊中的一张生成图
@immutable
class GeneratedImage {
  const GeneratedImage({
    required this.url,
    required this.prompt,
    required this.style,
    required this.createdAt,
  });

  final String url;
  final String prompt;
  final ImageStyle style;
  final DateTime createdAt;
}

/// 文生图页状态（不可变）
@immutable
class ImageGenState {
  const ImageGenState({
    this.prompt = '',
    this.selectedStyle = ImageStyle.none,
    this.images = const [],
    this.isLoading = false,
    this.error,
    this.errorToken = 0,
  });

  final String prompt;

  /// 当前选中的风格（null = 未选）
  final ImageStyle selectedStyle;

  /// 生成历史（新的在前）
  final List<GeneratedImage> images;

  final bool isLoading;

  final String? error;

  /// 错误事件计数：每次设置新 error 时 +1。
  /// UI 不能只比较 error 文字（同一错误连发两次不会触发提示），
  /// 用 token 才能把"值变化"和"事件发生"区分开。
  final int errorToken;

  ImageGenState copyWith({
    String? prompt,
    ImageStyle? selectedStyle,
    List<GeneratedImage>? images,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ImageGenState(
      prompt: prompt ?? this.prompt,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      errorToken: clearError
          ? 0
          : (error != null ? errorToken + 1 : errorToken),
    );
  }
}
