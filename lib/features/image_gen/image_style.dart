/// 文生图风格预设
///
/// 纯数据模块：选中的风格会作为后缀拼进 prompt 发给服务。
/// 改风格文案/加减风格只动这个文件。
enum ImageStyle {
  none('无', ''),
  watercolor('水彩', '，水彩画风格，柔和笔触'),
  pixel('像素', '，像素艺术风格，8-bit'),
  cyberpunk('赛博朋克', '，赛博朋克风格，霓虹灯，未来感'),
  ink('国风水墨', '，中国水墨画风格，留白意境'),
  cartoon3d('3D 卡通', '，3D 卡通渲染，可爱风格'),
  photo('摄影写实', '，摄影写实风格，自然光影，高清细节'),
  flat('扁平插画', '，扁平插画风格，简洁配色');

  const ImageStyle(this.label, this.suffix);

  /// 展示标签
  final String label;

  /// 拼进 prompt 的风格后缀（空串 = 不拼）
  final String suffix;

  /// 把用户输入的 prompt 应用本风格，返回最终 prompt
  String apply(String prompt) => suffix.isEmpty ? prompt : '$prompt$suffix';
}
