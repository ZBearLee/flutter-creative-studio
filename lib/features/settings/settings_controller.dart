import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_state.dart';
import 'settings_store.dart';

/// 运行时设置控制器：修改即生效（请求时读取），即改即存（本地持久化）
class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _restore();
    return const SettingsState();
  }

  /// 启动时恢复（异步：不阻塞首帧渲染）
  Future<void> _restore() async {
    final saved = await ref.read(settingsStoreProvider).load();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> _persist() =>
      ref.read(settingsStoreProvider).save(state);

  /// 设置文本模型覆盖名（传空串 = 清除覆盖，回到 .env 默认）
  void setLlmModel(String value) {
    final v = value.trim();
    if (v == state.llmModelOverride) return;
    state = state.copyWith(llmModelOverride: v);
    _persist();
  }

  /// 设置绘画模型覆盖名
  void setImageModel(String value) {
    final v = value.trim();
    if (v == state.imageModelOverride) return;
    state = state.copyWith(imageModelOverride: v);
    _persist();
  }

  /// 设置生成温度
  void setTemperature(double value) {
    state = state.copyWith(temperature: value);
    _persist();
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
