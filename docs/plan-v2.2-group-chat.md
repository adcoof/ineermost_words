# v2.2 群聊方案（P0 已实施）

> 状态：P0 已实施（2026-11-27）；schema v18；478 项测试\
> 基线：v2.1.0+15 / schema v17\
> 目标：先让群聊「能指定谁说话」，再对齐成熟开源项目的发言策略

---

## 1. 问题诊断

v2.0 的群聊是「每轮一位角色、按参与者顺序轮转」的最小实现：

- `createGroupConversation` 会把第一个角色作为会话主角色，并把全部选择写入 `conversation_participants`；数据层和轮转都有测试。
- 但聊天页顶栏只读取 `conversation.characterId`（第一个角色），没有成员列表、静音、强制发言或排序。
- 每次发送只允许一位角色回复；无法指定「这一条让谁回」。
- 群聊入口藏在「新会话 → 创建群聊」；从角色列表点「与 TA 对话」进入的是单聊，容易误以为只创建了第一个角色。
- **分段 bug**：模型输出 `[P]` 或多段时，第二段及之后的 assistant 消息没有写 `speakerCharacterId`，消息列表回退显示成会话主角色，看起来像「第一个角色在抢话」。

## 2. 开源调研与许可结论

| 项目 | 群聊能力 | 许可 |
|---|---|---|
| SillyTavern | Manual / Natural / List / Pooled 四种发言策略、Talkativeness、Mute、Force Talk、Auto-mode、Allow Self Responses、成员增删排序、群聊场景、Swap/Join 角色卡 | AGPL-3.0 |
| RisuAI | 多角色同群、Lorebook、情绪立绘、TTS | GPL-3.0 |
| Agnaistic | 多用户多 Bot 群聊、角色/预设/Lorebook | AGPL-3.0 |

- 三者均为 copyleft，不能把代码直接并入木兰许可的心语；且它们不是 Flutter/Dart，群聊逻辑与各自 UI/提示词/存储深度耦合。
- **结论**：保留木兰 PSL v2，独立实现设计思想，不复制代码或素材。

## 3. P0 已实施内容

### 数据层（schema v18）

- `conversation_participants.enabled`：静音成员不参与自动轮转，但仍可被 Force Talk。
- 仓储新增：`setParticipantEnabled`、`addParticipant`、`removeParticipant`、`reorderParticipants`；增删/排序同步会话主角色。
- `createGroupConversation` 校验 2–3 位成员；分支复制保留静音状态。

### 发言与提示词

- 自动轮转只在启用成员中进行；全部静音时防御性退回全体，避免死锁。
- `ChatController.forceSpeaker(id)`：只作用于下一条消息，发送后自动清空；可覆盖静音。
- 分段回复（`[P]` 与兜底补切）的每一段都写入当前 `speakerCharacterId`；表情包消息同样带发言者。
- 记忆、世界书、上下文用量按当前发言者计算。

### UI

- 群聊顶栏：成员头像堆叠 + 「群聊」+ 展开箭头，点击打开成员面板。
- 成员面板：开关静音、上移/下移、移除、添加（最多 3 人）；点成员 = 让 TA 回复下一条。
- 会话页 AppBar 增加「创建群聊」入口；新会话 FAB 入口保留。
- 消息气泡显示角色/用户头像；群聊按 speaker 取头像。

## 4. P1 待做

1. 发言策略：List（现状）、Manual（手动选人）、Natural（名字提及 + Talkativeness）、Pooled（本轮未发言者随机）。
2. 每角色 Talkativeness 滑杆；Auto-mode 与单轮 1–3 位连续回复；Allow Self Responses。
3. 群聊场景 / 群备注；Swap vs Join 角色卡提示词策略；Join Prefix/Suffix。
4. 每个角色的独立记忆摘要归属（当前按发言人加载已有记忆）。
5. 角色专属 TTS 音色 / Live2D 模型绑定（资产工坊阶段）。
6. 群聊关系网络、剧情状态、按发言人分支。

## 5. 验证

- `flutter analyze` 0。
- 全量 **478 项测试**通过。
- 新增覆盖：成员启停/排序/增删、主角色同步、分支保留静音、静音跳过轮转、Force Talk 只生效一轮且覆盖静音、分段 speaker、v17→v18 迁移、成员面板 widget。
- 真机（MuMu 360dp）：创建两人群聊、群标题/头像、成员面板、Force Talk、群聊回复与头像正常。
