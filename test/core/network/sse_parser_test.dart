import 'dart:async';
import 'dart:convert';

import 'package:flutter_creative_studio/core/network/sse_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// 模拟 SSE 字节流：把字符串切成 UTF-8 字节，按指定 chunk 分多次吐出
Stream<List<int>> _byteStream(List<String> chunks) async* {
  for (final c in chunks) {
    yield utf8.encode(c);
  }
}

void main() {
  group('SseParser', () {
    test('解析单个 data 事件', () async {
      // 最简单的合法 SSE 事件：一个 data 行
      final stream = _byteStream([
        'data: {"content":"你好"}\n\n',
      ]);

      final results = await SseParser.parse(stream).toList();

      expect(results.length, 1);
      expect(results.first['content'], '你好');
    });

    test('解析多个连续 data 事件', () async {
      // 模拟真实 LLM 响应：逐字吐
      final stream = _byteStream([
        'data: {"content":"你"}\n\n',
        'data: {"content":"好"}\n\n',
        'data: {"content":"，"}\n\n',
        'data: {"content":"Flutter"}\n\n',
      ]);

      final results = await SseParser.parse(stream).toList();

      expect(results.length, 4);
      expect(results.map((e) => e['content']).toList(),
          ['你', '好', '，', 'Flutter']);
    });

    test('忽略心跳注释行', () async {
      // 真实服务常常发 ':ok' 心跳保活，必须忽略
      final stream = _byteStream([
        ':ok\n\n',
        'data: {"content":"hi"}\n\n',
        ':ping\n\n',
      ]);

      final results = await SseParser.parse(stream).toList();

      expect(results.length, 1);
      expect(results.first['content'], 'hi');
    });

    test('遇到 [DONE] 结束流', () async {
      // OpenAI 兼容协议：[DONE] 标志流结束
      final stream = _byteStream([
        'data: {"content":"a"}\n\n',
        'data: {"content":"b"}\n\n',
        'data: [DONE]\n\n',
        'data: {"content":"c"}\n\n', // DONE 之后的内容不应被产出
      ]);

      final results = await SseParser.parse(stream).toList();

      expect(results.length, 2);
      expect(results.map((e) => e['content']).toList(), ['a', 'b']);
    });

    test('跨 chunk 边界的事件能正确拼接', () async {
      // 真实网络场景：一个事件可能被 TCP 分包切成多段
      // 这里把一个完整事件硬切成 4 段分别吐出
      final stream = _byteStream([
        'da',
        'ta: ',
        '{"content":"拼接成功"}',
        '\n\n',
      ]);

      final results = await SseParser.parse(stream).toList();

      expect(results.length, 1);
      expect(results.first['content'], '拼接成功');
    });

    test('忽略无 data 字段的事件', () async {
      // event:/id:/retry: 字段我们都用不到，应被忽略
      final stream = _byteStream([
        'event: ping\nid: 1\n\n', // 只有 event 和 id，无 data
        'data: {"content":"ok"}\n\n',
      ]);

      final results = await SseParser.parse(stream).toList();

      expect(results.length, 1);
      expect(results.first['content'], 'ok');
    });

    test('非 JSON 的 data 内容被忽略（容错）', () async {
      // 某些服务会发纯文本心跳 data，不应让解析器崩溃
      final stream = _byteStream([
        'data: connected\n\n', // 非 JSON
        'data: {"content":"正常"}\n\n',
      ]);

      final results = await SseParser.parse(stream).toList();

      expect(results.length, 1);
      expect(results.first['content'], '正常');
    });
  });
}
