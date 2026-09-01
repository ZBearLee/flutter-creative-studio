# AI创作工坊

基于Flutter开发的跨平台AI创作工具，集**文本生成**与 **AI生图**于一体，一套代码同时运行于Android、Windows与Web。

## 效果展示

### Android 端

| 文本生成 | 生成历史 | 图片生成 |
| :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/ba021565-1e1f-482d-b96e-bd39d631f586" width="230" alt="Android端文本生成"> | <img src="https://github.com/user-attachments/assets/ded0efd0-1c7d-4271-9d40-2ceb760a3b8a" width="230" alt="Android端文本历史列表"> | <img src="https://github.com/user-attachments/assets/aaac976c-c80b-4bfe-a7c5-7f4afbee49b5" width="230" alt="Android端生成图片"> |

### Windows 端

| 文本生成 | 图片生成 | 图片预览与下载 |
| :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/1810bde5-fcb4-4044-89bd-5f2b2898e1fd" width="380" alt="Windows端文本生成"> | <img src="https://github.com/user-attachments/assets/c9b5bf03-c5c4-40a2-a776-2a425bd448ae" width="380" alt="Windows端生成图片"> | <img src="https://github.com/user-attachments/assets/dd8c9e5d-1ab5-4322-bfb5-ddccd7d73367" width="380" alt="Windows端图片预览与下载"> |

## 功能特性

### 文本生成
- **流式输出**：基于SSE逐字呈现，带光标动效，所见即所得
- **提示词模板**：常用场景一键填充，降低输入成本
- **历史记录**：本地持久化，随时回看此前生成的内容
- **随时停止**：生成中途可打断，已输出的内容自动保留

### AI 绘画
- **风格预设**：水彩、像素、赛博朋克、国风水墨、3D卡通、摄影写实、扁平插画等多种风格
- **画廊展示**：响应式网格布局，自动适配手机 / 桌面屏幕宽度
- **风格徽标**：每张生成图标注所用风格，一目了然
- **全屏预览**：支持查看原图与下载保存

### 通用
- 一套代码，三端一致体验（Android / Windows / Web）
- API密钥通过 `.env` 环境变量隔离，不进仓库
- 自定义Toast、骨架屏、空态引导等组件化UI
- release构建包含 R8 代码混淆与资源压缩

## 技术栈

| 类别 | 选型 |
| --- | --- |
| 框架 | Flutter / Dart 3 |
| 路由 | go_router |
| 状态管理 | flutter_riverpod |
| 网络请求 | dio（SSE 流式）+ pretty_dio_logger |
| 本地持久化 | shared_preferences |
| 图片加载与缓存 | cached_network_image |
| 外部链接跳转 | url_launcher |
| 环境变量 | flutter_dotenv |

## 快速开始

### 环境要求

- Flutter SDK（stable）
- Android 端：Android Studio / Android SDK
- Windows 端：Visual Studio（含C++ 桌面开发工作负载）
- Web 端：Chrome

### 配置并运行

```bash
git clone <仓库地址>
cd flutter-creative-studio
flutter pub get
```

启动运行：

```bash
flutter run                 # 自动检测设备
flutter run -d windows      # Windows
flutter run -d chrome       # Web
flutter run -d <设备ID>     # Android（flutter devices 查看）
```

### 构建 release

```bash
flutter build apk --release       # Android
flutter build windows --release   # Windows
flutter build web --release       # Web
```