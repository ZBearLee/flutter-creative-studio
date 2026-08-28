import 'dart:async';

/// 异步任务轮询器
///
/// 用于文生图这类「提交任务 → 拿 task_id → 循环查状态 → 拿到结果」的场景。
/// 每隔 [interval] 调一次 [fetchFn]，直到 [shouldStop] 返回 true 或超时。
///
/// 典型用法：
/// ```dart
/// final result = await PollingRunner.run<Map<String, dynamic>>(
///   fetchFn: () => dioClient.get('/tasks/$taskId'),
///   shouldStop: (resp) =>
///     resp.data['status'] == 'SUCCEEDED' ||
///     resp.data['status'] == 'FAILED',
///   interval: const Duration(seconds: 3),
///   timeout: const Duration(minutes: 2),
/// );
/// ```
///
/// 设计要点：
/// - 超时统一抛 [TimeoutException]，UI 提示「生成超时，请重试」
/// - 调用方传入 [cancelToken] 可在用户离开页面时中止轮询
/// - 不内置重试：网络失败直接抛，让 UI 层决定是否给「重试」按钮
class PollingRunner {
  PollingRunner._();

  static Future<T> run<T>({
    required Future<T> Function() fetchFn,
    required bool Function(T) shouldStop,
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (true) {
      // 超时检查（放在 fetch 前，避免最后一次请求叠加超时）
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('轮询超时');
      }

      final result = await fetchFn();
      if (shouldStop(result)) return result;

      // 等待下一次轮询，可被外部取消
      await Future.delayed(interval);
    }
  }
}
