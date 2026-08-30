import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/app_exception.dart';
import '../../core/network/dio_providers.dart';
import 'gallery_store.dart';
import 'image_gen_state.dart';
import 'image_style.dart';

/// 文生图业务逻辑
///
/// 同步生成模式：POST 一次，等待数秒后响应直接带图片 URL。
/// 画廊历史通过 [GalleryStore] 持久化，重启自动恢复。
class ImageGenController extends Notifier<ImageGenState> {
  @override
  ImageGenState build() {
    _restore();
    return const ImageGenState();
  }

  /// 启动时恢复历史（异步：不阻塞首帧渲染）
  Future<void> _restore() async {
    try {
      final images = await ref.read(galleryStoreProvider).load();
      if (images.isNotEmpty && !state.isLoading) {
        state = state.copyWith(images: images);
      }
    } catch (_) {
      // provider 已销毁等情况：恢复失败不影响启动
    }
  }

  Future<void> generate() async {
    if (state.isLoading) return;

    final prompt = state.prompt.trim();
    if (prompt.isEmpty) {
      state = state.copyWith(error: '请输入画面描述');
      return;
    }

    if (!AppConfig.hasImageConfig) {
      state = state.copyWith(
        error:
            '配置不完整，请在项目根 .env 文件中填写 '
            'IMAGE_API_KEY / IMAGE_BASE_URL / IMAGE_MODEL',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final finalPrompt = state.selectedStyle.apply(prompt);

    try {
      final client = ref.read(imageGenDioClientProvider);
      // post 直接返回解析好的 Map（适配器差异已在网络层兜底）
      final resp = await client.post(
        '/images/generations',
        body: {'model': AppConfig.imageModel, 'prompt': finalPrompt},
      );
      // OpenAI 兼容结构：{"data": [{"url": "..."}]}
      final dataList = resp['data'] as List?;
      // 服务端返回的 url 可能被反引号/换行等杂质包裹，
      // 直接用正则提取干净的 URL（https:// 开头，到第一个空白/引号为止）
      final rawUrl = dataList?.firstOrNull?['url'] as String? ?? '';
      final url =
          RegExp("https?://[^\\s'`]+").firstMatch(rawUrl)?.group(0);
      if (url == null || url.isEmpty) {
        throw const ApiException(message: '响应中没有图片数据');
      }

      final image = GeneratedImage(
        url: url,
        prompt: finalPrompt,
        style: state.selectedStyle,
        createdAt: DateTime.now(),
      );

      // 新图插到最前
      final images = [image, ...state.images];
      state = state.copyWith(isLoading: false, images: images);
      // 持久化（失败静默，不影响当前会话）
      await ref.read(galleryStoreProvider).save(images);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '生成失败：$e');
    }
  }

  void updatePrompt(String value) {
    state = state.copyWith(prompt: value);
  }

  void selectStyle(ImageStyle style) {
    state = state.copyWith(selectedStyle: style);
  }

  void clearImages() {
    state = state.copyWith(images: const []);
    ref.read(galleryStoreProvider).clear();
  }
}

final imageGenControllerProvider =
    NotifierProvider<ImageGenController, ImageGenState>(ImageGenController.new);
