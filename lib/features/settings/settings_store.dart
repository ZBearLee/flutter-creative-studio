import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_state.dart';

/// 运行时设置本地持久化（与画廊/文本历史同方案：shared_preferences + JSON）
class SettingsStore {
  static const _key = 'app_settings';

  /// 启动时恢复设置。无存储或数据损坏返回 null（用默认值）。
  Future<SettingsState?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;

      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return SettingsState(
        llmModelOverride: map['llmModel'] as String? ?? '',
        imageModelOverride: map['imageModel'] as String? ?? '',
        temperature: (map['temperature'] as num?)?.toDouble() ?? 0.7,
      );
    } catch (_) {
      return null;
    }
  }

  /// 保存设置（写失败静默，仅丢运行时覆盖值，回退 .env 默认）
  Future<void> save(SettingsState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode({
        'llmModel': state.llmModelOverride,
        'imageModel': state.imageModelOverride,
        'temperature': state.temperature,
      }));
    } catch (_) {}
  }
}

/// Riverpod 全局单例（无状态，直接复用）
final settingsStoreProvider =
    Provider<SettingsStore>((ref) => SettingsStore());
