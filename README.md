<p align="center">
  <img src="assets/branding/app_icon.png" width="160" alt="心语 App 图标">
</p>

<h1 align="center">心语</h1>

<p align="center">让每一次对话，都怦然心动</p>

<p align="center">
  安卓 AI 角色扮演聊天应用：自备 API、完整角色档案与 V1/V2/V3 角色卡导入导出、Live2D 桌宠互动、双向语音对话，以及能帮你创建、改写角色卡的 AI 角色工坊。<br>
  奇点重现工作室出品 · <a href="https://www.sigborn.xyz">www.sigborn.xyz</a><br>
  English：<a href="README.en.md">README.en.md</a>
</p>

<p align="center">
  <a href="https://ineermostwords.sigborn.xyz/">宣传页</a> ·
  <a href="https://adcoof.github.io/ineermost_words/">GitHub Pages 镜像</a> ·
  <a href="https://github.com/adcoof/ineermost_words/releases/latest">GitHub 下载 APK</a> ·
  <a href="https://gitee.com/phantexdream/ineermost_words/releases">Gitee 镜像</a>
</p>

---

## 功能特性

### 💬 会话
- 流式打字机回复（SSE），支持随时停止/打断
- 全量历史本地保存（SQLite），重启不丢
- **多段短回复**：一轮回复拆成最多 4 条短消息逐条上屏，更像真人在打字；模型偷懒写成一大段时客户端自动兜底分段
- **时间感知**：消息带时间锚点（`今天 14:00` / `昨天 21:35` / `3天前 09:12`），角色不会把昨天的事说成“刚刚”
- **上下文窗口可调**：按估算 token 而非固定条数取历史，默认 4096（1024–32768 可调），实际预算按窗口 90%；聊天页顶栏显示已用百分比与分类明细
- **空回复自动重试**：模型偶尔只返回推理/空正文时自动重试一次；出错后可一键「重试」，不必重新输入
- **消息长按菜单**：复制文本、删除单条消息、重新生成、切换候选回复、编辑、从这里分支
- **群聊**：2–3 个角色同群，每轮按选择顺序由一位角色回复，气泡显示发言者名字；其他角色的发言会转成带名字的上下文
- **聊天分支**：从任意一条消息「从这里分支」，复制该条及之前的消息与群成员到新会话，原会话不受影响
- **对话收纳**：会话列表顶部角色头像条，点头像只看该角色的会话（最近在最上）
- **微信式时间戳**：相邻消息间隔超 5 分钟自动插入时间分隔，连续对话不刷屏
- **会话语音开关**：聊天页右上角一键静音/恢复本会话朗读（与全局语音开关独立）
- **会话背景板**：每个会话独立设置背景图（选图 → 裁剪 → 铺满整屏），键盘弹出不缩放，可随时恢复默认
- 绑定角色的会话按固定顺序组装提示词：人设 → 当前时间 → 场景 → **长期事实** → **近期记忆** → **跨会话片段** → **TA对你的了解** → 对话示例（few-shot）→ 标签规范 → 按预算滑动取历史

### 👤 角色
- 手动创建，或 **导入 SillyTavern V1/V2/V3 角色卡**（PNG tEXt / JSON）
- 人设、性格、场景、开场白、示例对话完整映射；`nickname / creator / tags / system_prompt / post_history_instructions` 等字段落位
- **完整角色档案**：基础身份、外貌、背景、关系、语言风格、互动方式、创作者信息、卡内系统提示；编辑页分「基础 / 档案 / 高级」三页签
- **角色卡导出**：V2/V3 JSON 与 PNG 角色卡；未知 extensions 与未识别字段原样保留；世界书随卡往返；导出前列出心语专有数据损失
- **版本历史**：保存时自动快照，每角色最多 20 条；可查看差异、恢复、删除；立绘不参与回滚
- **多开场白与标签**：主开场白 + 多个备用开场白，聊天页可切换；标签用于角色库与导出
- 角色立绘本地展示，上传时 1:1 可视化裁剪
- **跨会话记忆 v2**：同一角色的多个会话共用一份记忆——每个会话有独立摘要水位线，自动汇总近期片段；更早的对话压缩成带日期的事实（「和用户去了关山」+ 日期），不保留过程细节
- **记忆按需召回**：每轮只注入与当前话题命中的长期事实（最多 12 条 / 800 token，按时间衰减排序），不再整块塞入
- **世界书**：编辑页「世界书」入口添加关键词与设定，只有聊到相关词时才注入（可设历史前/后、深度、优先级）；SillyTavern `character_book` 导入为默认禁用草稿
- **记忆文档 + 长期记忆 + TA眼中的你**：记忆页分三段——近期记忆、长期事实时间线（可长按删除）、角色视角下的用户画像；支持下拉刷新，导出 PNG / Word
- **表情包库**：按 14 种心情（喜 / 怒 / 哀 / 乐 / 疑惑 / 害羞……）为角色上传贴纸，一心情可多张；角色回复带对应情绪时自动发一张，没有完全匹配的心情会借用相近心情（如「哭泣」借用「哀」）

### 🪄 AI 角色工坊
- 从底部「工坊」页的「AI 创作角色」卡片进入；编辑页的每个字段旁也有「AI 改写」
- **一句话生成角色卡**：描述想要的角色，一次生成名字、描述、性格、场景、开场白、示例对话 6 个字段
- **多字段提案**：模型给出修改理由 + 逐字段勾选 + 原文/建议 diff，可应用选中、全部应用或放弃
- **单字段改写**：需求输入 → 生成 → 对比 → 替换此字段；替换只改输入框，点「保存」才写入角色卡，可撤销上一次替换
- **多轮修改**：在工坊里继续说「把性格改得更嘴硬一点」即可继续调整草稿
- 工坊只读写角色字段，不执行文件 / 命令 / 网络操作；提案会校验 JSON、字段白名单、长度与控制标记

### 🐾 桌宠（Live2D）
- **内置 Haru 默认桌宠**：开箱即用，首次启动自动导入，新会话默认绑定；也可换用自己的模型
- 导入 `.moc3` 模型包（zip），WebView + pixi-live2d-display 离线渲染
- AI 回复中的 `<emotion:happy>` / `<action:wave>` 标签实时驱动表情与动作
- 关键词情绪兜底（如文本出现“生气”也能触发对应表情）
- 句级口型驱动（播放期包络动画）

### 🎙 语音（双向）
| 方向 | 引擎 |
|---|---|
| TTS（朗读） | **MiMo 云端**（`mimo-v2.5-tts`，默认）→ Edge 免费 → OpenAI 兼容 → 系统引擎，失败自动降级 |
| ASR（按住说话） | **MiMo 云端**（`mimo-v2.5-asr`，默认）→ 独立配置 → 系统本机识别，启动失败自动回退 |

- 按住说话、松手识别并直接发送；播报中按麦克风即刻打断
- **音色工坊**：用一句话描述（如“温柔甜美的年轻女声”）定制专属音色（MiMo `voicedesign` 云端合成），可试听、可多套管理，选中后与内置发音人并列
- **引擎级 API 配置**：OpenAI TTS 档与 ASR「独立配置」档可各自填写接口地址/Key/模型名，留空则回落聊天 API 配置；MiMo 档永远复用聊天配置
- TTS 输入自动剥离 `<标签>`，绝不朗读标记
- 播放队列流水线预合成（播第 N 句时后台合成第 N+1 句），句间近无缝
- 9 个 MiMo 发音人 + 自定义音色，语速 0.5~2.0x

### ⚙️ 设置
- **API 供应商**：任意 OpenAI 兼容接口（DeepSeek / Kimi / Qwen / Ollama / 中转站 / 小米 MiMo），测试连接；旧会话在供应商被删除或 Key 为空时自动回退默认配置
- **上下文窗口**：1024–32768 可调，含跨会话片段预算
- **语音**：TTS/ASR 引擎、发音人、识别语言、云端 API 独立配置
- **跨会话记忆**：全局开关（默认开）
- **空回复自动重试**：全局开关（默认开）
- **外观**：深空紫 / 樱夜粉 / 青岚蓝 / 薄荷绿 / 晨光白（浅色）**五套完整主题**，各含全套配色与深浅亮度，带预览卡片，全局即时生效
- **更多**：官网入口、版本信息

### 🎨 界面
- 二次元科技风，多套整机主题可切换（含一套浅色主题）
- **液态玻璃质感**：底部导航、聊天顶栏、输入栏使用真实背景模糊 + 半透明渐变描边；消息气泡用半透明填充（滚动列表不逐条模糊，保证流畅）
- **窄屏适配**：360dp 下聊天顶栏动作收进更多菜单，上下文用量保持可见；标题优先完整显示角色名；桌宠悬浮层按屏宽缩放，减少遮挡
- 启动过渡页：图标 + 标语 + 工作室署名
- 底部导航：**聊天 / 工坊 / 资产 / 设置**；桌宠、立绘、表情包、音色从「资产」页进入

## 近期更新

- **v2.1**：完整角色档案（基础身份 / 外貌 / 背景 / 关系 / 语言风格 / 互动方式 / 创作者 / 卡内提示）；SillyTavern V1/V2/V3 导入、V2/V3 JSON 与 PNG 导出、未知字段保留、世界书往返；保存自动版本快照与恢复；编辑页三页签、多开场白、标签、档案 token 估算；四栏导航与资产聚合页；schema v17；466 项测试
- **v2.0**：群聊（2–3 个角色，每轮一位发言者轮换，气泡显示发言者）与聊天分支（从任意消息复制前缀到新会话，保留参与者与 parent 指针）；schema v16；416 项测试
- **v1.9**：世界书（关键词命中的设定才注入，支持历史前/后与优先级）与记忆按需召回（事实 12 条/800 token，时间衰减）；SillyTavern `character_book` 导入为禁用草稿；schema v15；410 项测试
- **v1.8**：移除通用 Agent（tab、工具、审批、Shizuku / 无障碍、数据库表），以「AI 角色工坊」为主：一句话生成角色卡、多字段提案、单字段改写、diff 与撤销；schema v13 自动删除 Agent 表；385 项测试
- **v1.7**：关闭系统备份与设备迁移（数据库不出应用沙盒）、为消息/会话查询补索引、旧会话供应商自动回退、错误后可一键重试、消息长按复制/删除、Agent 回复 Markdown 渲染、Agent 打开即定位最新消息、图片转 PNG
- **v1.6**：新增 Agent（文件 / 命令 / HTTP / 联网搜索 / 手机控制）、会话级 Agent 权限、Agent 上下文窗口与用量、保存到下载、常用格式转换、更细的上下文压缩
- **v1.5**：Agent 权限体系（每步确认 / 自动审查 / 全自动）、SAF 授权文件夹、删除/移动/重命名、Shizuku shell 与无障碍读屏点击
- **v1.4**：空回复与错误输出修复、自定义上下文窗口、记忆 v2（多会话共享 + 长期事实 + 3 天近期记忆）、工具调用与 Markdown
- **v1.3 系列**：表情包、多段短回复、液态玻璃界面、记忆文档与「TA眼中的你」导出、会话背景板与头像裁剪、内置 Haru 桌宠、时间感知

## 技术栈

Flutter（Android，minSdk 24）· Riverpod 3 · Drift/SQLite · dio（SSE 自研解码）· just_audio · edge_tts / flutter_tts / speech_to_text / record · flutter_inappwebview + PixiJS + pixi-live2d-display · crop_your_image（裁剪）· share_plus（导出分享）· image / archive（图片与压缩包）

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
>
> 若 release 构建报 `PathExistsException ... flutter_assets/...`，删除 `build/app/intermediates/flutter/release/flutter_assets` 后重试。

## 配置说明

1. **添加 API 供应商**：设置 → API 供应商 → 填入接口地址（形如 `https://api.xxx.com/v1`，不带 `/chat/completions`）与密钥，可测试连接
2. **语音开箱即用**：TTS/ASR 默认走 MiMo 云端，复用默认聊天 API 配置；在 设置 → 语音 可切换引擎与发音人，OpenAI/ASR 独立配置档可填专用接口
3. MiMo 平台注意事项（实测）：
   - Key 仅在 `https://token-plan-cn.xiaomimimo.com/v1` 有效（`api.xiaomimimo.com` 返回 401）
   - TTS 走 `chat/completions` + `audio` 参数（**不是** `/audio/speech`），发音人固定 9 个
   - 音色定制走 `mimo-v2.5-tts-voicedesign`：音色描述进 user 消息、朗读文本进 assistant 消息，无需音色 ID；同描述两次合成音色存在随机差异
   - ASR 的 `content` 中**不能携带任何 text 片段**，只接受 `input_audio`
4. Edge 免费语音在部分网络环境会被微软接口拒绝（403），届时自动降级其他引擎

## 权限与隐私

- 应用不包含统计/广告 SDK；会话、角色、记忆均保存在本机 SQLite，不上传服务器
- 你配置的 API Key 仅保存在本机数据库，用于直连你填写的接口；请勿在共享设备上保存长期 Key
- v1.7 起关闭 Android 系统自动备份与设备迁移，避免数据库被云备份带出应用沙盒
- 图片、语音只在需要时由你触发上传到你配置的接口

## 项目结构

```
lib/
  app/          # MaterialApp、主题、启动页、全局 providers
  core/         # 统一异常、SSE 解码
    utils/      # 时间锚点、token 估算、图片压缩、Word(.docx) 生成、导出分享
    widgets/    # 液态玻璃组件
  data/local/   # Drift 数据库与表定义
  features/
    chat/       # 会话、消息流、输入栏（按住说话）、分段器、上下文用量、记忆摘要、表情包、会话背景板
    characters/ # 角色卡、完整档案、SillyTavern 导入导出、AI 角色工坊、版本快照、世界书、提示词组装、记忆文档、表情包库、图片裁剪
    assets/     # 资产聚合页（桌宠 / 立绘 / 表情包 / 音色入口）
    pet/        # Live2D 桌宠、WebView 桥、情绪→表情映射、内置 Haru
    voice/      # TTS/ASR 各引擎实现、播放队列、音色工坊、语音设置
    settings/   # API 供应商、应用通用设置
assets/
  pet/          # 桌宠 WebView 宿主、离线 vendor 库、内置 Haru 模型包及其许可声明
  branding/     # 应用图标与工作室 logo
website/        # 宣传页（纯静态，GitHub Pages 自动发布；说明见 website/README.md）
```

## 测试

```bash
flutter analyze   # 静态检查
flutter test      # 466 项用例：SSE/标签解析/分段与兜底/提示词与 token 预算/表情包映射/语音队列/滚底/数据库迁移/记忆摘要与事实/世界书注入与召回/上下文压缩/角色工坊/群聊轮换/分支复制/角色档案与版本/角色卡导入导出/PNG tEXt 等
```

## 致谢与版权

- © 奇点重现工作室（sigborn.xyz）。应用名称「心语」及图标素材版权归工作室所有。
- 桌宠渲染基于 [pixi-live2d-display](https://github.com/guansss/pixi-live2d-display)（MIT）与 Live2D Cubism Core；**Powered by Live2D**。Cubism Core 按 Live2D 许可协议使用（个人及年营收低于门槛免费，商用前请自行确认条款）。
- 内置默认桌宠 Haru 为 Live2D 官方示例模型，按 Live2D Sample Model License Agreement 打包分发（许可声明见 `assets/pet/HARU_LICENSE.txt`，模型版权归 Live2D 所有）。
- 用户导入的角色卡/模型素材由用户自行保证版权，应用仅在本地渲染展示。
