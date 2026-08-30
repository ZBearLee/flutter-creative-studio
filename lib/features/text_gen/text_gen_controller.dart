import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/dio_providers.dart';
import '../../core/network/sse_parser.dart';
import 'prompt_template.dart';
import 'text_history_store.dart';
import 'text_gen_state.dart';

/// 文本生成控制器（Riverpod 2.x Notifier 写法，无需额外包）
///
/// 职责：
/// - 持有 [TextGenState]，通过 Notifier.state 暴露给 UI
/// - 调 [DioClient.streamSse] 拿到字节流
/// - 用 [SseParser] 切成事件 Map
/// - 逐字追加到 [TextGenState.output]，UI 自动流式渲染
/// - 支持 [stop] 中途取消
class TextGenController extends Notifier<TextGenState> {
  /// 当前请求的取消令牌；null 表示无进行中的请求
  CancelToken? _cancelToken;

  @override
  TextGenState build() {
    _restore();
    return const TextGenState();
  }

  /// 启动时恢复历史（异步：不阻塞首帧渲染）
  Future<void> _restore() async {
    try {
      final items = await ref.read(textHistoryStoreProvider).load();
      if (items.isNotEmpty) {
        state = state.copyWith(history: items);
      }
    } catch (_) {
      // provider 已销毁等情况：恢复失败不影响启动
    }
  }

  /// 取 Dio 客户端（Notifier 内部通过 ref 访问）
  DioClient get _dioClient => ref.read(textGenDioClientProvider);

  /// 更新输入框内容
  void updatePrompt(String p) => state = state.copyWith(prompt: p);

  /// 选中/取消选中模板（再次点击同一个取消选中）
  void selectTemplate(PromptTemplate? t) {
    final isSame = state.selectedTemplate?.id == t?.id;
    state = state.copyWith(
      selectedTemplate: isSame ? null : t,
      clearTemplate: isSame,
    );
  }

  /// 重置模板选择（切走 Tab 时调用，回来不残留上次的选择）
  void resetSelection() {
    if (state.selectedTemplate != null) {
      state = state.copyWith(clearTemplate: true);
    }
  }

  /// 发起生成（流式）
  Future<void> generate() async {
    if (state.isLoading) return;

    final userPrompt = state.prompt.trim();
    if (userPrompt.isEmpty) {
      state = state.copyWith(error: '请输入内容');
      return;
    }

    if (!AppConfig.hasLlmApiKey || AppConfig.llmModel.isEmpty) {
      state = state.copyWith(
        error: '配置不完整，请在项目根 .env 文件中填写 '
            'LLM_API_KEY / LLM_MODEL / LLM_BASE_URL',
      );
      return;
    }

    _cancelToken = CancelToken();
    state = state.copyWith(
      output: '',
      isLoading: true,
      clearError: true,
    );

    try {
      // 拼 prompt：模板前缀 + 用户输入
      final prefix = state.selectedTemplate?.prefix ?? '';
      final finalPrompt =
          prefix.isEmpty ? userPrompt : '$prefix\n\n$userPrompt';

      final resp = await _dioClient.streamSse(
        '/chat/completions',
        body: {
          'model': AppConfig.llmModel,
          'messages': [
            {'role': 'user', 'content': finalPrompt}
          ],
          'stream': true,
        },
        cancelToken: _cancelToken,
      );

      // response.data 是 ResponseBody，.stream 才是字节流
      final responseBody = resp.data as ResponseBody;
      final eventStream = SseParser.parse(responseBody.stream);

      await for (final event in eventStream) {
        // OpenAI 兼容协议：choices[0].delta.content 是流式分片
        final choices = event['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) continue;
        final delta = choices[0]['delta'] as Map<String, dynamic>?;
        final content = delta?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          state = state.copyWith(output: state.output + content);
        }
      }

      state = state.copyWith(isLoading: false);

      // 成功生成一条 → 记入历史（新在前）并持久化
      final item = TextHistoryItem(
        prompt: userPrompt,
        output: state.output,
        template: state.selectedTemplate,
        createdAt: DateTime.now(),
      );
      final items = [item, ...state.history];
      state = state.copyWith(history: items, clearViewing: true);
      // 持久化（失败静默，不影响当前会话）
      await ref.read(textHistoryStoreProvider).save(items);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '生成失败：$e',
      );
    } finally {
      _cancelToken = null;
    }
  }

  /// 停止生成
  void stop() {
    _cancelToken?.cancel('用户主动停止');
    _cancelToken = null;
    if (state.isLoading) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 清空输入 + 输出 + 历史（含本地持久化，与绘画页清空画廊同语义）
  void clear() {
    stop();
    state = const TextGenState();
    ref.read(textHistoryStoreProvider).clear();
  }

  /// 查看某条历史（输出区切换为该条详情）
  void viewHistory(TextHistoryItem item) {
    state = state.copyWith(viewingHistory: item);
  }

  /// 退出历史详情，回到历史列表
  void closeHistory() {
    if (state.viewingHistory != null) {
      state = state.copyWith(clearViewing: true);
    }
  }
}

/// 文本生成控制器 Provider（Riverpod 2.x NotifierProvider）
final textGenControllerProvider =
    NotifierProvider<TextGenController, TextGenState>(
  TextGenController.new,
);
