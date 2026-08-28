import 'dart:async';
import 'dart:convert';

/// SSE（Server-Sent Events）解析器
///
/// 把 Dio 流式响应的字节流（[Stream<List<int>>]）按 SSE 协议切出
/// 业务事件，输出为 [Map<String, dynamic>] 流供 UI 逐字渲染。
///
/// SSE 协议简述：
/// - 事件之间用空行（`\n\n`）分隔
/// - 每行格式：`field: value`
/// - 我们只关心 `data:` 字段；`:xxx` 是心跳注释，`event:/id:/retry:` 忽略
/// - `data: [DONE]` 是 OpenAI 兼容服务的结束标记
///
/// 典型输入字节流：
/// ```
/// :ok\n\n                              ← 心跳（忽略）
/// data: {"content":"你"}\n\n            ← 输出 {content: "你"}
/// data: {"content":"好"}\n\n            ← 输出 {content: "好"}
/// data: [DONE]\n\n                      ← 结束，关闭 Stream
/// ```
class SseParser {
  SseParser._(); // 纯工具类，禁止实例化

  /// 把字节流解析为事件 Map 流
  ///
  /// - [byteStream]：Dio `ResponseType.stream` 响应里的 `response.data`
  /// - 跨 chunk 边界的事件会被自动拼接（不丢数据）
  static Stream<Map<String, dynamic>> parse(
    Stream<List<int>> byteStream,
  ) async* {
    // 字节流 → 字符流（UTF-8 解码）
    final charStream = byteStream.transform(utf8.decoder);

    // 缓冲区：累积未消费的字符，处理跨 chunk 边界的事件
    final buffer = StringBuffer();

    await for (final chunk in charStream) {
      buffer.write(chunk);

      // 按 \n\n 切事件块（SSE 规定空行分隔事件）
      while (true) {
        final sepIndex = buffer.toString().indexOf('\n\n');
        if (sepIndex < 0) break; // 没有完整事件，等下一个 chunk

        // 取出完整事件块
        final rawEvent = buffer.toString().substring(0, sepIndex);
        // 移除已消费部分 + 分隔符本身（2 个字符）
        final remaining = buffer.toString().substring(sepIndex + 2);
        buffer
          ..clear()
          ..write(remaining);

        // 解析事件块，提取 data 字段拼接结果
        final dataStr = _parseEvent(rawEvent);
        if (dataStr == null) continue; // 心跳 / 无 data 字段

        if (dataStr == '[DONE]') {
          // OpenAI 兼容服务的结束标记，关闭流
          return;
        }

        // 尝试 JSON 解析；失败则忽略（容错：纯文本心跳 data 不应让解析器崩溃）
        final json = _tryParseJson(dataStr);
        if (json != null) {
          yield json;
        }
      }
    }

    // 流结束后，缓冲区里可能还有未以 \n\n 结尾的尾部事件
    if (buffer.isNotEmpty) {
      final dataStr = _parseEvent(buffer.toString());
      if (dataStr != null && dataStr != '[DONE]') {
        final json = _tryParseJson(dataStr);
        if (json != null) yield json;
      }
    }
  }

  /// 解析单个事件块，返回拼接后的 data 字符串
  ///
  /// SSE 规范中同事件可有多个 data 行，它们用 `\n` 连接成一个完整字符串。
  /// 返回 null 表示这是心跳注释（以 `:` 开头）或没有 data 字段。
  static String? _parseEvent(String rawEvent) {
    final lines = rawEvent.split('\n');
    final dataLines = <String>[];

    for (final line in lines) {
      if (line.isEmpty) continue;
      if (line.startsWith(':')) continue; // 心跳注释，忽略
      if (line.startsWith('data:')) {
        // 去掉 "data:" 前缀和可能的一个空格
        final value = line.substring(5);
        dataLines.add(value.startsWith(' ') ? value.substring(1) : value);
      }
      // event:/id:/retry: 字段我们用不到，忽略
    }

    if (dataLines.isEmpty) return null;
    return dataLines.join('\n');
  }

  /// 安全 JSON 解析
  static Map<String, dynamic>? _tryParseJson(String s) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
}
