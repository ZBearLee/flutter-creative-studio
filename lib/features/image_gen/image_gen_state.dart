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
  });

  final String prompt;

  /// 当前选中的风格（null = 未选）
  final ImageStyle selectedStyle;

  /// 生成历史（新的在前）
  final List<GeneratedImage> images;

  final bool isLoading;

  final String? error;

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
    );
  }
}
