<p align="center">
  <img src="assets/branding/app_icon.png" width="160" alt="心语 App 图标">
</p>

<h1 align="center">心语</h1>

<p align="center">让每一次对话，都怦然心动</p>

<p align="center">
  安卓 AI 角色扮演聊天应用：自备 API、导入角色卡、Live2D 桌宠互动、双向语音对话。<br>
  奇点重现工作室出品 · <a href="https://www.sigborn.xyz">www.sigborn.xyz</a>
</p>

---

## 功能特性

### 💬 会话
- 流式打字机回复（SSE），支持随时停止/打断
- 全量历史本地保存（SQLite），重启不丢
- 绑定角色的会话按固定顺序组装提示词：人设 → 场景 → 标签规范 → 对话示例（few-shot）→ 最近 40 条滑动窗口

### 👤 角色
- 手动创建，或 **导入 SillyTavern V2 角色卡**（PNG tEXt / JSON）
- 人设、性格、场景、开场白、示例对话完整映射
- 角色立绘本地展示

### 🐾 桌宠（Live2D）
- 导入 `.moc3` 模型包（zip），WebView + pixi-live2d-display 离线渲染
- AI 回复中的 `<emotion:happy>` / `<action:wave>` 标签实时驱动表情与动作
- 关键词情绪兜底（如文本出现"生气"也能触发对应表情）
- 句级口型驱动（播放期包络动画）

### 🎙 语音（双向）
| 方向 | 引擎 |
|---|---|
| TTS（朗读） | **MiMo 云端**（`mimo-v2.5-tts`，默认）→ Edge 免费 → OpenAI 兼容 → 系统引擎，失败自动降级 |
| ASR（按住说话） | **MiMo 云端**（`mimo-v2.5-asr`，默认）→ 系统本机识别，启动失败自动回退 |

- 按住说话、松手识别并直接发送；播报中按麦克风即刻打断
- TTS 输入自动剥离 `<标签>`，绝不朗读标记
- 播放队列流水线预合成（播第 N 句时后台合成第 N+1 句），句间近无缝
- 9 个 MiMo 发音人可选，语速 0.5~2.0x

### ⚙️ 设置
- **API 供应商**：任意 OpenAI 兼容接口（DeepSeek / Kimi / Qwen / Ollama / 中转站 / 小米 MiMo），测试连接
- **语音**：TTS/ASR 引擎、发音人、识别语言独立配置
- **外观**：霓虹紫 / 星光青 / 樱粉 / 薄荷 四色主题，全局即时生效
- **更多**：官网入口、版本信息

### 🎨 界面
- 深空黑底 + 蓝紫霓虹的二次元科技风（暗色主题）
- 启动过渡页：图标 + 标语 + 工作室署名
- 底部导航：会话 / 角色 / 桌宠 / 设置

## 技术栈

Flutter（Android，minSdk 24）· Riverpod 3 · Drift/SQLite · dio（SSE 自研解码）· just_audio · edge_tts / flutter_tts / speech_to_text / record · flutter_inappwebview + PixiJS + pixi-live2d-display

## 快速开始

```bash
# 依赖
flutter pub get

# 运行（连接设备/模拟器后）
flutter run

# 打包 release APK
flutter build apk --release
# 产物: build/app/outputs/flutter-apk/app-release.apk
```

> 构建内存不足时（Gradle daemon OOM）参见 `android/gradle.properties`，JVM 参数已按 16GB 内存机器调优（`-Xmx4G`）。

## 配置说明

1. **添加 API 供应商**：设置 → API 供应商 → 填入接口地址（形如 `https://api.xxx.com/v1`，不带 `/chat/completions`）与密钥，可测试连接
2. **语音开箱即用**：TTS/ASR 默认走 MiMo 云端，复用默认聊天 API 配置；在 设置 → 语音 可切换引擎与发音人
3. MiMo 平台注意事项（实测）：
   - Key 仅在 `https://token-plan-cn.xiaomimimo.com/v1` 有效（`api.xiaomimimo.com` 返回 401）
   - TTS 走 `chat/completions` + `audio` 参数（**不是** `/audio/speech`），发音人固定 9 个
   - ASR 的 `content` 中**不能携带任何 text 片段**，只接受 `input_audio`
4. Edge 免费语音在部分网络环境会被微软接口拒绝（403），届时自动降级其他引擎

## 项目结构

```
lib/
  app/          # MaterialApp、主题、启动页、全局 providers
  core/         # 统一异常、SSE 解码
  data/local/   # Drift 数据库与表定义
  features/
    chat/       # 会话、消息流、输入栏（按住说话）、提示词驱动
    characters/ # 角色卡、SillyTavern 导入、提示词组装、情绪标签解析
    pet/        # Live2D 桌宠、WebView 桥、情绪→表情映射
    voice/      # TTS/ASR 各引擎实现、播放队列、语音设置
    settings/   # API 供应商、应用通用设置
assets/
  pet/          # 桌宠 WebView 宿主与离线 vendor 库
  branding/     # 应用图标与工作室 logo
```

## 测试

```bash
flutter analyze   # 静态检查
flutter test      # 160+ 用例：SSE/标签解析/提示词组装/语音队列/滚底/主题设置等
```

## 致谢与版权

- © 奇点重现工作室（sigborn.xyz）。应用名称「心语」及图标素材版权归工作室所有。
- 桌宠渲染基于 [pixi-live2d-display](https://github.com/guansss/pixi-live2d-display)（MIT）与 Live2D Cubism Core；**Powered by Live2D**。Cubism Core 按 Live2D 许可协议使用（个人及年营收低于门槛免费，商用前请自行确认条款）。
- 用户导入的角色卡/模型素材由用户自行保证版权，应用仅在本地渲染展示。
