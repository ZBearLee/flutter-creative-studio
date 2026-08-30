import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prompt_template.dart';
import 'text_gen_state.dart';

/// 文本历史本地持久化
///
/// - 实现：shared_preferences 键值存储（与画廊同方案，全平台可用）
/// - 容量控制：最多保留 [_maxCount] 条，超出丢最旧的。
///   文本比图片 URL 占空间，上限给 30 条（每条含全文 output）
class TextHistoryStore {
  static const _key = 'text_history_items';
  static const _maxCount = 30;

  /// 启动时恢复历史（新在前）。读取失败返回空列表，不抛异常。
  Future<List<TextHistoryItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];

      final list = jsonDecode(raw) as List;
      final items = <TextHistoryItem>[];
      for (final item in list) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final output = map['output'] as String?;
        if (output == null || output.isEmpty) continue;
        final templateId = map['templateId'] as String?;
        items.add(
          TextHistoryItem(
            prompt: map['prompt'] as String? ?? '',
            output: output,
            template: PromptTemplate.values.asNameMap()[templateId],
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              map['createdAt'] as int? ?? 0,
            ),
          ),
        );
      }
      return items;
    } catch (_) {
      // 数据损坏等情况：当作无历史，不阻塞启动
      return const [];
    }
  }

  /// 持久化整个列表（调用方传入完整列表，新在前）。
  /// 只保留前 [_maxCount] 条，写失败静默（下次启动最多丢历史）。
  Future<void> save(List<TextHistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.take(_maxCount).map((it) {
        return {
          'prompt': it.prompt,
          'output': it.output,
          'templateId': it.template?.id,
          'createdAt': it.createdAt.millisecondsSinceEpoch,
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
final textHistoryStoreProvider =
    Provider<TextHistoryStore>((ref) => TextHistoryStore());
