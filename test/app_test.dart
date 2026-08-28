// 根 Widget 冒烟测试：验证 MyApp（MaterialApp.router + GoRouter）能正常 build。
// 文件路径镜像 lib/app.dart，符合 Dart 测试"测试文件镜像 lib/ 结构"惯例。

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_creative_studio/app.dart';

void main() {
  testWidgets('MyApp 能正常构建并显示底部导航', (tester) async {
    // 用 ProviderScope 包裹（和 main.dart 一致）
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );

    // 触发一帧渲染
    await tester.pump();

    // 底部三个 Tab 应该都渲染出来
    expect(find.text('文本'), findsOneWidget);
    expect(find.text('绘画'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);

    // 默认进文本 Tab，AppBar 标题应为「文本生成」
    expect(find.text('文本生成'), findsOneWidget);
  });
}
