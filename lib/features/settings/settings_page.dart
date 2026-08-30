import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import 'settings_controller.dart';

/// 设置页
///
/// - 模型名 / 温度：运行时可改，即时生效 + 持久化（覆盖值留空回退 .env）
/// - API Key / 接口地址：只读状态展示（敏感信息只在项目根 .env 配置）
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _llmModelController = TextEditingController();
  final _imageModelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 恢复的历史覆盖值异步到达 → 监听同步进输入框
    // （仅在值与输入框当前内容不一致时才写，避免打断正在输入的用户）
    ref.listenManual(settingsControllerProvider, (prev, next) {
      if (next.llmModelOverride != _llmModelController.text.trim()) {
        _llmModelController.text = next.llmModelOverride;
      }
      if (next.imageModelOverride != _imageModelController.text.trim()) {
        _imageModelController.text = next.imageModelOverride;
      }
    });
  }

  @override
  void dispose() {
    _llmModelController.dispose();
    _imageModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SectionTitle('模型'),
          _SettingsCard(
            child: Column(
              children: [
                _ModelField(
                  controller: _llmModelController,
                  label: '文本模型',
                  envDefault: AppConfig.llmModel,
                  onChanged: ref
                      .read(settingsControllerProvider.notifier)
                      .setLlmModel,
                ),
                const Divider(height: 1, color: AppTheme.line),
                _ModelField(
                  controller: _imageModelController,
                  label: '绘画模型',
                  envDefault: AppConfig.imageModel,
                  onChanged: ref
                      .read(settingsControllerProvider.notifier)
                      .setImageModel,
                ),
              ],
            ),
          ),
          const _SectionTitle('生成参数'),
          _SettingsCard(
            child: _TemperatureTile(
              value: settings.temperature,
              onChanged: ref
                  .read(settingsControllerProvider.notifier)
                  .setTemperature,
            ),
          ),
          const _SectionTitle('接口配置'),
          // AppConfig 是运行时读 .env，非编译期常量 → 这里不能用 const
          _SettingsCard(
            child: Column(
              children: [
                _ConfigRow(label: '文本 API Key', ok: AppConfig.hasLlmApiKey),
                const Divider(height: 1, color: AppTheme.line),
                _ConfigRow(
                  label: '文本接口地址',
                  ok: AppConfig.llmBaseUrl.isNotEmpty,
                ),
                const Divider(height: 1, color: AppTheme.line),
                _ConfigRow(
                  label: '绘画 API Key',
                  ok: AppConfig.imageApiKey.isNotEmpty,
                ),
                const Divider(height: 1, color: AppTheme.line),
                _ConfigRow(
                  label: '绘画接口地址',
                  ok: AppConfig.imageBaseUrl.isNotEmpty,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '密钥与接口地址在项目根 .env 文件中配置，修改后需重启应用。\n'
            '模型名留空时使用 .env 默认值。',
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
              color: AppTheme.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 分组标题
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.inkSecondary,
        ),
      ),
    );
  }
}

/// 分组卡片容器
class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// 模型名输入行（label + 输入框；hint 显示 .env 默认值）
class _ModelField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String envDefault;
  final ValueChanged<String> onChanged;

  const _ModelField({
    required this.controller,
    required this.label,
    required this.envDefault,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.inkSecondary,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: AppTheme.ink),
              decoration: InputDecoration(
                // .env 有默认值时 hint 展示它（"默认 xxx"），没有则提示未配置
                hintText: envDefault.isNotEmpty
                    ? '默认 $envDefault'
                    : '未在 .env 配置',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.inkTertiary,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 温度行（label + 数值 + 滑块，拖动即时保存）
class _TemperatureTile extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _TemperatureTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '温度',
                style: TextStyle(fontSize: 14, color: AppTheme.inkSecondary),
              ),
              const Spacer(),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brand,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 1.5,
            divisions: 15,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
          const Text(
            '值越低越稳定，越高越有创意（仅文本生成生效）',
            style: TextStyle(fontSize: 12, color: AppTheme.inkTertiary),
          ),
        ],
      ),
    );
  }
}

/// .env 配置状态行（只读）
class _ConfigRow extends StatelessWidget {
  final String label;
  final bool ok;
  const _ConfigRow({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.inkSecondary,
              ),
            ),
          ),
          const Spacer(),
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: ok ? const Color(0xFF34A853) : AppTheme.inkTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            ok ? '已配置' : '未配置',
            style: TextStyle(
              fontSize: 13,
              color: ok ? AppTheme.ink : AppTheme.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
