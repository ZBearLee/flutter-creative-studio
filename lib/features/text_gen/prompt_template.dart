/// 文本生成预设模板
///
/// 每个模板提供一段固定 prompt 前缀，用户输入内容会被拼接到前缀之后。
/// 新增模板只需在此 enum 添加一项，UI 会自动渲染对应 chip。
enum PromptTemplate {
  xiaohongshu(
    id: 'xiaohongshu',
    label: '小红书',
    prefix: '请用小红书风格改写以下内容：'
        '要求：1. 带合适的 emoji  2. 结尾加 3-5 个 hashtag  3. 段落短、口语化、有情绪。',
  ),
  copywriting(
    id: 'copywriting',
    label: '营销文案',
    prefix: '请用专业营销文案风格改写以下内容：突出卖点、制造紧迫感、结尾带行动号召。',
  ),
  translate(
    id: 'translate',
    label: '中英互译',
    prefix: '请将以下内容翻译为英文（如已是英文则翻译为简体中文）：只输出译文，不要解释。',
  ),
  slogan(
    id: 'slogan',
    label: '品牌 Slogan',
    prefix: '请为以下产品/品牌生成 5 条 Slogan 候选：要求简短、有记忆点、不同风格各一条。'
        '用编号列表输出。',
  ),
  story(
    id: 'story',
    label: '短篇故事',
    prefix: '请基于以下设定写一个 1000 字以内的短篇故事：要求有人物、冲突、结尾反转。',
  ),
  polish(
    id: 'polish',
    label: '文字润色',
    prefix: '请润色以下文字：保持原意，但让语言更流畅、专业、地道。只输出润色后的文字。',
  );

  final String id;
  final String label;
  final String prefix;

  const PromptTemplate({
    required this.id,
    required this.label,
    required this.prefix,
  });
}
