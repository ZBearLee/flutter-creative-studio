import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'image_gen_state.dart';
import 'image_style.dart';

/// 画廊本地持久化
///
/// - 实现：shared_preferences 键值存储
///   （Windows/macOS 写注册表或文件，web 写 localStorage，移动端写 XML，
///   全平台可用；不依赖 path_provider，web 端无实现）
/// - 容量控制：最多保留 [_maxCount] 条，超出丢最旧的（web 端 localStorage 约 5MB）
/// - 注意：存的是图片 URL，服务端签名链接会过期（约 7 天），
///   过期后卡片会加载失败，属演示项目可接受范围
class GalleryStore {
  static const _key = 'gallery_images';
  static const _maxCount = 50;

  /// 启动时恢复历史（新图在前）。读取失败返回空列表，不抛异常。
  Future<List<GeneratedImage>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];

      final list = jsonDecode(raw) as List;
      final images = <GeneratedImage>[];
      for (final item in list) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final styleName = map['style'] as String?;
        final style = ImageStyle.values.asNameMap()[styleName];
        final url = map['url'] as String?;
        if (url == null || url.isEmpty || style == null) continue;
        images.add(
          GeneratedImage(
            url: url,
            prompt: map['prompt'] as String? ?? '',
            style: style,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              map['createdAt'] as int? ?? 0,
            ),
          ),
        );
      }
      return images;
    } catch (_) {
      // 数据损坏等情况：当作无历史，不阻塞启动
      return const [];
    }
  }

  /// 持久化整个列表（调用方传入完整列表，新图在前）。
  /// 只保留前 [_maxCount] 条，写失败静默（下次启动最多丢历史，不影响当前会话）。
  Future<void> save(List<GeneratedImage> images) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = images.take(_maxCount).map((img) {
        return {
          'url': img.url,
          'prompt': img.prompt,
          'style': img.style.name,
          'createdAt': img.createdAt.millisecondsSinceEpoch,
        };
      }).toList();
      await prefs.setString(_key, jsonEncode(list));
    } catch (_) {}
  }

  /// 清空历史
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

/// Riverpod 全局单例（无状态，直接复用）
final galleryStoreProvider = Provider<GalleryStore>((ref) => GalleryStore());
