# v1.4 方案：输出稳定性 / 记忆完整性 / 自定义上下文窗口 / 多会话共享 / Agent 模块

> 状态：**M1、M2、M3、M4 已完成；M5 真机进行中（2026-11-23）**。真实 API 已通：聊天、`tool_calls`、`write_file` 确认写入均验；已修 Agent Markdown 渲染、Android 工作区 canonical 根路径、记忆摘要被英文拒绝串污染三处。剩余：M1 mock 四场景（可选）、记忆守卫重装后复验、旧会话 profile pin 导致的 401 说明。按第 7 节里程碑实施，每个里程碑先补测试再动 UI。
> 基线：v1.3.5+9，schemaVersion 10，30 个测试文件 / 304 项用例；M1 后 321 项、M2 后 341 项、M3 后 362 项、M4 后 382 项、M5 后 **383 项全过**。
> 已确认决策（2026-11-23）：Agent = 本地工作区文件 + 底部第 5 个 tab；上下文窗口 = token 估算；空流自动重试 1 次；升级后旧会话一次性回填摘要。

## 0. 结论摘要

| # | 用户诉求 | 根因（已定位到代码） | 方案 | 优先级 | 预估 |
|---|---|---|---|---|---|
| 1 | 偶尔输出为空 / 错误输出 | 正常结束不判空；只解析 `delta.content` 字符串；`finish_reason` 未用；非 SSE 整包 JSON 零增量 | 解析归一化 + 空流重试 + 占位清理 + 截断诊断 | P0 | 1.5d |
| 2 | 角色记忆显示不全 / 丢失 | 摘要只读当前会话；字符硬截断；分隔标记必须精确独行；记忆页只加载一次 | 按会话水位线 + 容忍解析 + 分节截断 + 页面刷新 | P1 | 3d |
| 3 | 自定义上下文窗口 | `PromptAssembler.windowSize = 40` 写死；无角色分支无上限 | token 估算 + 预算化组装 + 跨会话独立预算 + 用量组件（已用/剩余/分类） | P1 | 1.5d |
| 4 | 增强多对话记忆共享 | 其他会话 40 条平铺、无会话分组/配额；纯图消息被过滤 | 按会话分组摘要 + 摘要覆盖全部会话 + 图片摘要纳入 | P1 | 含在第 2 项 |
| 5 | Agent 模块（简单读写） | 不存在 | 独立 Agent 会话 + 工作区文件 `list/read/write` + 写入确认 | P2 | 3.5d |
| 6 | 记忆压缩（事实 + 时间戳） | 现有摘要只有叙述、无结构化事实/时间；细节无法自然过期 | 新增 `memory_facts` 事实库 + 近期摘要分层 + 事实抽取提示词 | P1 | 1.5d |

总计约 10.5–11.5 个工作日；第 1、2、6 项建议同版本发布（都动记忆/流式链路，回归一次完成）。

---

## 1. 现状与根因（代码级）

### 1.1 空输出 / 错误输出

发送链路在 `lib/features/chat/application/chat_controller.dart`：

- L167-173 先插入 `status: streaming` 的 assistant 占位。
- L373-399 `endSegmentAtBoundary` 在 `[P]` 边界处只有当段非空才落库；空段复用占位。
- **L429 正常结束直接 `await finalizeSegment(MessageStatus.done)`，从不检查 `contentBuf` / `rawBuf` 是否为空** → 服务端零增量时留下一条空 assistant 消息（空泡）。
- L498-508 取消：仅当两个缓冲都空才 `deleteMessage`，否则按 done 落半截，合理。
- L509-516 异常：一律 `finalizeSegment(MessageStatus.error)`，即使内容为空也留一行空错误泡。
- `ChatDelta.finishReason`（`chat_api_client.dart` L19-22）在控制器里从未读取，无法区分 `stop` / `length` / `content_filter`。

网络层 `lib/features/chat/data/chat_api_client.dart`：

- L197-239 `_parseChunk` 只取 `choices[0].delta.content`（且必须是 String）或 `message.content`（String）。以下常见形状全部丢失：
  - `delta.content` 为多模态 parts 数组（部分聚合网关）；
  - `delta.reasoning_content` 只有推理没有正文；
  - 老式 `choices[0].text`；
  - `message.content` 为数组。
- L129-136 直接把 `response.data.stream` 交给 `decodeSseStream`。若服务端忽略 `stream:true`、返回整段 `application/json`（常见于反向代理/中转），`sse_decoder.dart` 会把 `{...}` 当未知字段静默丢弃 → 零事件 → 空消息。
- 没有捕获原始帧，问题发生时无法定位是「服务端没返回」还是「解析丢了」。
- 推理模型约束（已由 `title_generator.dart` L94 注释实测）：MiMo `mimo-v2.6-flash` 的 reasoning_tokens 计入 `max_tokens`，且推理长度随机；预算不足会在正文前 `length` 截断，正文恒空。聊天请求的 `max_tokens` 来自 `profile.maxTokens`（可空），用户填得偏小时就会偶发空输出。

### 1.2 角色记忆显示不全 / 丢失

`lib/features/chat/application/memory_summarizer.dart`：

- L65-179 `_run` 的水位线是**角色级全局时间** `characters.memoryUpdatedAt`，但增量只取**当前会话**：
  - `countDoneMessagesSince(conversationId, memory.updatedAt)` 只统计当前会话；
  - `_incrementalSince(conversationId, since)` 只取当前会话。
  - 结果：在会话 A 聊完 6 条生成摘要并把水位线推到 T；切到会话 B 后，B 的旧消息（< T）永远不进入摘要；再切回 A，A 的消息只从 T 之后算。**跨会话记忆在摘要层实际是断的。**
- L24/L27 硬上限 400 / 300 字符，`substring` 直接切 → 可能切在半句、切掉后面的小标题，表现为「显示不全」。
- L30 分隔标记要求**精确独行** `【对用户的了解】`；模型输出 `**【对用户的了解】**`、`## 【对用户的了解】`、`【TA眼中的你】` 时整轮被丢弃，保留旧文档 → 表现为「聊了很久记忆不更新」。
- L50-63 `_inFlight` 命中时直接 return，失败也不排队 → 连续快速对话时可能整段没整理。
- `maxTokens: 800` 对推理模型偏紧（推理+正文共享预算），有截断风险。

`lib/features/characters/presentation/character_memory_page.dart`：

- L83-99 `initState` 只 `_load()` 一次，没有下拉刷新/没有 watch；摘要更新后页面仍显示旧内容。

`lib/features/chat/data/chat_repository.dart`：

- L160-184 `getRecentOtherMessages` 的过滤条件是 `content != ''`，**纯图消息即使有 `imageSummary` 也被排除**，跨会话片段里看不到「用户发的图」。
- 固定 `limit=40` 平铺，无按会话配额；一个话痨会话可以占满全部配额。

### 1.3 上下文窗口

- `lib/features/characters/application/prompt_assembler.dart` L23：`static const int windowSize = 40;`，无参数、无设置。
- `chat_controller.dart` L188-236：无角色会话直接发送**全部历史**（无上限）；有角色会话固定 40。
- 跨会话片段固定 40（`chat_repository.dart` L160），与主窗口共用体感预算但没有独立控制。

### 1.4 多会话共享的结构性问题

- 只有「一份角色级摘要 + 其他会话最近 40 条原文」，没有按会话的消费进度（水位线），也没有「哪些会话已贡献过摘要」的记录。
- 其他会话片段没有会话标题/分组，模型分不清哪些话来自哪段关系。
- 摘要输入上限 80 条、输出 400 字，信息密度和覆盖面都不够。

### 1.5 Agent

`lib/` 下没有 agent 目录、没有工具调用解析、没有文件工作区。`ChatApiClient` 也不支持 `tools` / `tool_calls`。

---

## 2. 总览

### 2.1 目标架构

```
聊天发送
  └─ ChatController
       ├─ 上下文预算（新：AppSettingsRepository.contextWindowTokens + token 估算器）
       ├─ PromptAssembler（参数化 tokenBudget / otherTokenBudget）
       ├─ 跨会话摘要（新：按会话分组的 CrossSessionDigest）
       └─ ChatApiClient（新：内容归一化 / 整包 JSON 兜底 / finishReason / tool_calls）

记忆
  ├─ MemorySummarizer v2（新：MemoryCursors 按会话水位线、宽容解析、分节截断）
  └─ CharacterMemoryPage（新：下拉刷新、宽容标题解析、更新时间）

Agent（新）
  ├─ AgentController（工具循环、流式渲染、取消）
  ├─ AgentWorkspace（沙箱目录、路径校验、大小限制）
  ├─ AgentSessionRepository（会话/消息持久化）
  └─ AgentPage（会话、工具卡片、写入确认）
```

### 2.2 数据与配置变更

| 变更 | 内容 | 版本 |
|---|---|---|
| 表 `memory_cursors` | `characterId + conversationId` 复合主键，`summarizedAt` | schema v9 |
| 表 `memory_facts` | 长期事实：`id, characterId, fact, occurredAt, sourceConversationId, createdAt` | schema v9 |
| 表 `agent_sessions` | `id, title, createdAt, updatedAt` | schema v10 |
| 表 `agent_messages` | `id, sessionId, role, content, toolCallsJson, toolCallId, toolName, status, createdAt` | schema v10 |
| 设置 KV | `context_window_tokens`（默认 4096）、`context_window_other_tokens`（默认 1024） | 无迁移 |
| 设置 KV | `agent_auto_write`（默认 false）、`agent_max_steps`（默认 6） | 无迁移 |
| `ApiMessage` | 新增可选 `toolCalls` / `toolCallId` / `name` | 代码 |
| `ChatDelta` | 新增可选 `reasoning` / `toolCalls` | 代码 |

迁移注意（项目已有坑）：`from < 9` 只 `createTable(memoryCursors)`；`from < 10` 只 `createTable(agentSessions/agentMessages)`。不要在后续版本对同表 `addColumn` 而不加 `from >= 首建版本` 守卫。

---

## 3. 工作流 A：输出稳定性（P0）

### A1. API 解析归一化（`chat_api_client.dart`）

1. 新增 `_extractText(dynamic content)`：
   - String → 原样；
   - List → 拼接每项的 `text`（`type == 'text'`）或 `content`；
   - 其他 → null。
2. `_parseChunk` 改为：
   - `delta.content` 走 `_extractText`；
   - 同时解析 `delta.reasoning_content`（只放进 `ChatDelta.reasoning`，**绝不写入正文**）；
   - 老式 `choices[0].text` 兜底；
   - `finish_reason` 继续返回。
3. 整包 JSON 兜底：
   - 响应头 `content-type` 含 `application/json` 时，先聚合整个 body（上限 8MB），按一次性 completion 解析：`choices[0].message.content` + `finish_reason` + `usage`；
   - `text/event-stream` 或 `text/plain` 仍走 SSE；同时用一个小型 tee 缓存原始字节（上限 1MB）。若整条流**零 delta 且无 `[DONE]`**，用缓存尝试 JSON 解析，成功则 yield 一条 delta（这能救「标成 text/plain 的整包 JSON」）。
   - tee 只保留字节，不改变上游流。
4. 诊断：`kDebugMode` 下 `debugPrint` 每个错误帧的原始 `data`（截断 500 字）、`finish_reason`、reasoning 长度、content 长度。

### A2. 控制器空流兜底（`chat_controller.dart`）

把「消费流 + 分段 + 落盘」抽成 `_consumeOnce(...)`，返回：

```dart
({bool gotContent, bool gotRaw, String? finishReason, bool cancelled})
```

`send()` 的结束逻辑改为：

```
if (cancelled) -> deleteMessage（空）/ finalize done（半截）  // 保持现状
else if (!gotContent && !gotRaw) -> 清空占位 -> 允许重试一次 -> 仍空则 deleteMessage + errorText
else if (!gotContent && gotRaw)  -> 只有标签/空白：deleteMessage + 明确提示
else -> finalize done（现有逻辑）
```

重试矩阵：

| 情况 | 动作 |
|---|---|
| 取消 | 不重试 |
| 有正文后网络异常 | 保留半截（现状），不重试 |
| 零输出 + `finish_reason == 'length'` | 若 `profile.maxTokens != null`，用 `max(profile.maxTokens * 2, 1024)` 重试 1 次；null 则同参重试 |
| 零输出 + `finish_reason == 'content_filter'` | 不重试，提示「内容被模型安全策略拦截」 |
| 零输出 + `stop` / null | 同参重试 1 次 |
| 重试仍零输出 | 删除占位行，`errorText = '模型这次没有返回内容，请重试或检查最大输出设置'` |

实现要点：

- 重试前 `contentBuf/rawBuf`、`SegmentSplitter`、`EmotionTagParser`、`segmentCount` 全部重置；占位消息 `updateMessage(content:'', rawContent:'')`。
- 重试期间检查 `_sendSeq` 与 `cancelToken`，用户再次发送/取消立即放弃。
- 重试不重复插入用户消息，不重复触发图片概括。
- 只在**零正文**时重试，最多 1 次，避免双倍消耗。
- 标签-only 判定：`contentBuf.toString().trim().isEmpty`（`parser.flush()` 之后）。

### A3. 错误输出治理

- `finalizeSegment` 之后再跑一次 `stripTagMarkup` 兜底（防未知标签漏进气泡）；已有实现，补一条「整个回复只有标签」的回归用例。
- 错误提示统一走 `ChatUiState.errorText` + SnackBar；新增「重试」按钮（复用 `send()` 的重新生成入口；若没有该入口，则先补一个 `retryLastTurn()`：删掉最后一条 assistant，重发最后一条用户消息的 API 请求而不重复入库）。
- 空回复不写库；历史里不再出现空泡（`message_list` 现有空内容渲染也加一层防御：`content.trim().isEmpty` 且有图才显示图片）。

### A4. 测试

- `openai_chat_client_test.dart`：content 为数组、`reasoning_content`、`choices[0].text`、整包 JSON（application/json）、text/plain 整包 JSON、错误帧。
- 新增 `chat_controller_test.dart`（或现有 controller 测试）：零输出 → 占位删除 + errorText；length → 重试并加大 max_tokens；重试仍空 → 删除；取消不重试；有半截不重试。
- 手工用 `build/mock_openai_server.py` 增加 4 个场景：空流、length 空正文、非 SSE JSON、reasoning-only。

---

## 4. 工作流 B：自定义上下文窗口（P1，token 估算）

### B1. 计量

新增 `lib/core/utils/token_estimate.dart`：

```dart
/// 粗略估算 token 数：CJK 字符按 1.2、其他字符按 3.5 字符/token。
int estimateTokens(String text) {
  var cjk = 0, other = 0;
  for (final r in text.runes) {
    if (_isCjk(r)) {
      cjk++;
    } else {
      other++;
    }
  }
  return (cjk * 1.2 + other / 3.5).ceil();
}

bool _isCjk(int r) =>
    (r >= 0x3400 && r <= 0x9FFF) || // 扩展 A + 基本区
    (r >= 0xF900 && r <= 0xFAFF) || // 兼容区
    (r >= 0x3040 && r <= 0x30FF) || // 日文假名
    (r >= 0xAC00 && r <= 0xD7AF);   // 韩文
```

- 每条消息成本 = 4（role/分隔开销）+ `estimateTokens(content)`；历史图片只带 `[图片：摘要]` 文本，不把 base64 计入。
- 设置范围 1,024–32,768，默认 4,096，步进 512；预设 2K / 4K / 8K / 16K。
- 预算实际按 `budget * 0.9` 使用，给估算误差留余量。

`lib/features/settings/data/app_settings_repository.dart` 新增：

```dart
static const kContextWindowTokens = 'context_window_tokens';
static const kContextWindowOtherTokens = 'context_window_other_tokens';

Future<int> contextWindowTokens();   // 缺省 4096，clamp 1024..32768
Future<void> setContextWindowTokens(int n);
Future<int> contextWindowOtherTokens(); // 缺省 1024，clamp 0..8192
Future<void> setContextWindowOtherTokens(int n);
```

### B2. 提示词组装

`PromptAssembler.assemble(...)` 新增 `int tokenBudget = 4096` 与 `int otherTokenBudget = 1024` 参数：

- 当前会话历史：从最新一条往前累加 `4 + estimateTokens(contentWithImageNote)`，直到下一条会超预算；**当前用户消息永远保留**。
- 历史里单条超预算 30% 时，从尾部截断到 30% 并加 `…`，防止一条超长消息挤掉全部上下文；当前用户输入不截断。
- 无角色分支：`chat_controller.dart` L188-236 同样按 `tokenBudget` 从新到旧取（当前是全量）。
- 跨会话片段：用 `getCrossSessionDigest(...)` 的分组结果（见 C4），在 `otherTokenBudget * 0.9` 内按会话 `updatedAt` 轮转填充，每组至少 1 条（预算允许时）；`otherTokenBudget == 0` 时不注入原文，只保留摘要。
- 系统部分（人设、标签规范、示例对话、记忆摘要）不计入 `tokenBudget`，但在设置页单独展示「系统人设约 X token」，让用户知道总负担。

### B3. UI

#### B3.1 上下文用量组件（新增）

组件：`ContextUsageChip`（聊天页 AppBar 右侧）+ `ContextUsageSheet`（点开）。

- Chip 显示 `上下文 38%`；颜色 <70% 主题色、70–90% 琥珀、>90% 红。
- Sheet 顶部：`上下文已用 38%` 与 `剩余 12.4K / 20.0K`，下方进度条；再下方分类明细：
  - 系统提示词（人设 / 时间 / 场景 / 标签规范 / 示例）
  - 长期记忆（事实）
  - 近期记忆（近期摘要 + 对用户的了解）
  - 跨会话片段
  - 本会话消息（历史 + 当前输入，含图片摘要）
- 底部说明：「按估算 token 计算；预算为窗口的 90%，超出后从最早消息开始裁剪」。
- 数据：`PromptAssembler.assembleDetailed()` 返回 `AssembledPrompt{messages, usage}`，`usage` 给出各分类 token；`assemble()` 保留原签名并委托，避免测试大改。Chip 只在发送完成/切换会话/打开 sheet 时刷新，不逐 token 刷新。
- 空态：无 API 配置或未选角色时显示 `--`，不阻塞聊天。
- 设置页的「上下文窗口」tile 只显示窗口大小，不显示当前百分比：设置页不订阅聊天状态，避免耦合；当前用量在聊天页 chip 展示。

#### B3.2 窗口配置

设置页「配置」区新增「上下文窗口」tile：

- 主标题「上下文窗口」，副标题「约 4,096 token（≈ 3.4 千字）」；
- 点开 bottom sheet：Slider 1,024–32,768（步进 512）+ 预设 chips 2K / 4K / 8K / 16K + 「恢复默认 4,096」；
- 同 sheet 第二项「跨会话引用」0–8,192（步进 512，默认 1,024，0 = 不引用其他会话原文）；
- 底部说明：「按中文 1 字 ≈ 1.2 token、英文 4 字符 ≈ 1 token 估算，仅供预算参考」。

不新增独立页面，避免设置页膨胀。

### B4. 边界

- 预算大于历史 → 全发，不报错。
- 预算极小（1,024）且历史都超长 → 至少保留最近 2 条（user + assistant），`kDebugMode` 打警告。
- 估算不精确：不承诺与供应商 tokenizer 完全一致；预算按 90% 使用，且设置页明示「估算」。
- 「不限制」不作为选项：移动端上下文有上限，32K 已足够大。
- 关掉跨会话原文（0）时，摘要仍然注入，共享不断。

### B5. 测试

- 新增 `token_estimate_test.dart`：纯中文、纯英文、中英混合、emoji、空串、边界值。
- 新增 `context_usage_chip_test.dart`：百分比、空态、点击弹层分类、颜色阈值（70/90）。
- `prompt_assembler_test.dart`：budget=1,024 只取最近若干条；超长单条截断到 30%；预留当前输入后只剩 2 条兜底；otherTokenBudget=0 不注入其他会话原文。
- `app_settings_repository_test.dart`：缺省值、clamp（1024/32768、0/8192）、持久化。

---

## 5. 工作流 C：记忆完整性与多会话共享（P1）

### C1. schema v9：`memory_cursors`

```dart
class MemoryCursors extends Table {
  TextColumn get characterId => text()();
  TextColumn get conversationId => text()();
  DateTimeColumn get summarizedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {characterId, conversationId};
}
```

`AppDatabase.schemaVersion => 9`；迁移 `if (from < 9) await m.createTable(memoryCursors);`。

### C2. 摘要算法 v2（`memory_summarizer.dart`）

```
_run(characterId):
  memory   = getMemory(characterId)
  convs    = getConversationsForCharacter(characterId, excludeArchived: true, limit: 8)
  cursors  = getMemoryCursors(characterId)
  groups   = []
  for conv in convs:
    since  = cursors[conv.id] ?? epoch          // 无游标 = 补历史
    msgs   = getDoneMessagesAfter(conv.id, since, limit: 80)
    if msgs.isNotEmpty: groups.add((conv, msgs))
  if total(groups) < 6: return
  按 conv.updatedAt 倒序取前 4 个会话
  quota = max(4, 80 ~/ groupCount)
  每组取最新 quota 条 -> 合并按 createdAt 升序 -> 总 ≤ 80
  watermark = DateTime.now()                     // 调 LLM 前
  transcript = 按会话分组，格式：
      【会话 1：标题】
      【MM-DD】【用户】...
      【MM-DD】【角色名】...
  out = streamChat(system: 记忆整理指令, user: 旧摘要 + 旧用户画像 + transcript, maxTokens: 2048)
  (summary, userSummary) = _parseTolerant(out)
  if summary.trim().isEmpty: 保留旧文档; _pending.add(characterId); return
  setMemory(... updatedAt: watermark)
  for group in included: setMemoryCursor(characterId, conv.id, watermark)
```

关键决策：

- **无游标按 epoch 处理**：升级后第一次触发会把该会话最近 80 条（可能已部分总结过）重新合并一次，宁可轻微重复，不可丢失；成功后写入游标，不会反复。
- **水位线用 `>=` 取消息**（Drift `dateTime()` 秒级精度）：同一秒的边界消息可能被重复计入，靠提示词「去重合并」消化；避免丢消息。
- **单次最多 4 个会话 / 80 条**：防止提示词爆炸；最新 80 条优先，更老的积压不补（在文档中写明，避免用户误以为全量归档）。
- **失败排队**：`_inFlight` 命中时 `_pending.add(id)`；`finally` 里若 `_pending.remove(id)` 为真则再跑一次。失败也重排一次（最多连续 2 次，防死循环）。
- `maxTokens: 2048`：给推理模型留足正文预算。

提示词补充：

- 输入含「已有角色记忆 / 已有用户画像 / 新增对话」，要求合并去重、保留已有小标题。
- 输出恰好两段，第二段标记独行 `【对用户的了解】`；不要解释、不要代码块。
- 总长 ≤ 1200 字；按主题分节，每节 3~6 行。

### C3. 容忍解析 + 边界截断

`_parseTolerant`：

1. 去代码围栏（```）与首尾空行。
2. 标记识别：逐行归一化（去 `# * _ ` ~ 空白`，`【】[]` 统一），命中 `对用户的了解` 或 `TA眼中的你` 即分割；兼容 `**【对用户的了解】**`、`## 【对用户的了解】`。
3. 找不到标记：整段作为角色记忆（保留旧用户画像），不再整轮丢弃。
4. 任一段为空：用旧值补，不丢另一段。

`_truncateDoc(doc, maxChars)`：

- 按行扫描，遇 `#`/`##` 小标题开启新节；
- 累计超限时，优先整节丢弃（从末尾往前），而不是 `substring`；
- 最后一节仍超限：在最后一个 `。！？\n` 处截断；找不到再按 rune 截断（`String.fromCharCodes(s.runes.take(n))`，避免劈开代理对）；
- 上限调整为 `kMemorySummaryMaxChars = 800`、`kUserSummaryMaxChars = 500`（约 500–700 token，可接受）。

### C4. 跨会话片段增强

`chat_repository.dart` 新增：

```dart
Future<List<CrossSessionGroup>> getCrossSessionDigest({
  required String characterId,
  required String excludeConversationId,
  int maxConversations = 4,
  int perConversation = 8,
});
```

- 每组 = `{Conversation conversation, List<ChatMessage> messages}`。
- 过滤：`done + kind=text + (content != '' OR imageSummary != '')`（修复纯图丢失）。
- 按会话 `updatedAt` 倒序取前 4 个，每组取最新 8 条；组内按时间升序。
- 提示词渲染：

```
以下是该角色与用户在【其他对话】中的近期片段（按会话分组）：
【会话：标题】
【用户】...
【角色名】...
```

- 去重：与当前会话窗口重复的消息不可能跨会话，无需处理；同一内容多次出现由模型自行理解。

### C5. 记忆页修复

`character_memory_page.dart`：

- `_load()` 增加 `RefreshIndicator` + AppBar 刷新按钮；加载失败显示重试。
- `parseDocSections` 同时识别：
  - `#{1,6} 标题`；
  - `**标题**` 独占一行（模型常见输出）；
  - 其余归入当前节。
- 顶部显示「上次整理：yyyy-MM-dd HH:mm」；空记忆显示引导文案。
- 导出 PNG/Word 逻辑不变（导出前确保用最新 `_summary/_userSummary`）。

### C6. 记忆压缩：事实记忆

目标：把「今天和角色聊去关山游玩」压缩成 `[2026-11-23] 用户去关山游玩`，长期只保留事实与时间戳；细节在近期摘要过期后消失，模型被问细节时应表示记不清，而不是编造。

#### C6.1 数据模型（并入 schema v9）

```dart
class MemoryFacts extends Table {
  TextColumn get id => text()();
  TextColumn get characterId => text()();
  TextColumn get fact => text()();                 // 「用户去关山游玩」
  DateTimeColumn get occurredAt => dateTime()();   // 事件发生日（本地 00:00）
  TextColumn get sourceConversationId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}
```

- 索引 `(characterId, occurredAt desc)`；每角色上限 240 条，超出按 `occurredAt` 最旧淘汰。
- `memory_summary` 语义收窄为「近期记忆」：只保留最近 N 天的细节（默认 3 天），逐行 `【MM-DD】...`，≤300 字；`user_summary` 不变。
- 事实与近期摘要同时存在：近期摘要负责「这几天发生了什么」的细节，事实负责「更早发生过什么」的骨架。

#### C6.2 抽取流程

每次摘要触发时，在**同一次请求**内完成（不增加调用次数）：

输入 = 已有近期摘要 + 最近 60 条事实 + 未摘要对话。

输出三段：

1. `## 近期`：只保留最近 3 天细节，逐行 `【MM-DD】...`；过期条目删除；
2. `## 新事实`：每行 `[YYYY-MM-DD] 事实`，一事一条、≤40 字；
3. `## 对用户的了解`：沿用现有格式；不要输出解释/代码块。

本地处理：

- 解析新事实 → 归一化 → 与已有事实做完全匹配 + 二元组相似度 ≥0.8 去重；
- 日期缺失时回退到该条消息的日期 / 近期摘要行首日期；
- 事实插入成功后才推进游标；解析失败保留旧事实与旧摘要。
- **硬约束：近期摘要里的每一条事件都必须同时产出一条事实**（即使细节仍在保留期），这样 3 天后删细节不会丢事实。

#### C6.3 提示词注入

放在场景之后、近期摘要之前：

```
以下是你记得的长期事实（按时间倒序，方括号内是发生日期）。
你只记得这些事实和发生时间，不记得具体过程；被问到细节时不要编造，
可以自然地说「记不太清了」。
[2026-11-23] 用户去关山游玩
[2026-11-21] 用户养了一只叫团子的猫
```

- 事实块最多 60 条 / 1,200 字，超出取最近 60 条；设置页展示「长期记忆约 X token」。
- 与近期摘要重复时，近期摘要优先；提示词说明两者关系。

#### C6.4 展示

- 记忆页 SegmentedButton 增加第三段「长期记忆」：按日期倒序的时间线，每条 `2026-11-23 · 用户去关山游玩`；空态引导。
- 长按删除单条（二次确认），导出 PNG/Word 包含事实段。
- 「角色记忆」段只展示近期摘要，避免与事实重复。

#### C6.5 边界

- 同一天同一事件 → 合并一条；不同事件按条保留。
- 用户问「还记得我去关山吗」→ 事实块让她能答「记得，11 月 23 号去的」；追问细节 → 应回答记不清。
- 事实不替代原文：消息仍在 DB，用户可回看，但不再进上下文。
- 旧数据升级：首次回填从旧摘要 + 旧会话抽取事实；旧摘要作为近期摘要保留（无日期行按 `memory.updatedAt` 补）。
- 压缩时机：已确认保留最近 3 天细节；更早的条目只保留事实 + 发生日期。N 作为常量 `kRecentMemoryDays = 3`，不做 UI 开关。

#### C6.6 测试

- 事实解析：日期行、无日期、超长、重复、相似去重。
- 近期摘要过期：3 天前条目被删且事实存在；事实块顺序。
- 提示词：事实块位置、防编造指令、60 条截断。
- 页面：第三段渲染、空态、删除。
- 集成：两个会话的事件都进入事实库，日期来自消息而非整理时间。

### C7. 迁移与回填

- 升级只建表，不改旧数据；`memoryUpdatedAt` 保留给旧代码/排序使用。
- 首次触发即为回填：每个会话 `since = epoch`，最多 80 条，一次摘要请求；用户可在设置里关「跨会话记忆」阻止。
- 成本提示：升级后首轮可能多花 1 次摘要请求/角色，属于预期。

### C8. 测试

- `memory_summarizer_test.dart`：
  - 两会话各 6 条 → 一次请求包含两组；
  - 游标推进后不重复；切回旧会话仍能纳入新消息；
  - 标记加粗/加 `#` 仍能分割；
  - 缺标记 → 整段作为角色记忆；
  - 超长文档按节/句截断，不出现半句；
  - 失败后 `_pending` 重跑一次。
- `chat_repository_test.dart`：纯图 + imageSummary 进入 digest；每会话配额；排除 archived。
- `migration_test.dart`：v8→v9 建表且旧数据可用。

---

## 6. 工作流 D：Agent 模块（P2）

> 默认推荐「本地工作区文件读写」。备选「角色记忆/角色卡读写」放到 v1.5（见 6.8）。

### D1. 产品形态

- 底部导航新增第 5 个 tab「Agent」（会话 / 角色 / Agent / 桌宠 / 设置）。
- 页面 = 会话列表（新建/删除）+ 对话页：
  - 普通气泡 + 工具调用卡片（读取/写入路径、状态、展开内容）；
  - 写入卡片带「确认写入 / 取消」；
  - 顶部显示当前工作区路径与「清空」入口；
  - 输入栏支持停止生成。
- 工作区：`getApplicationSupportDirectory()/agent_workspace/`，首次创建；支持从系统文件选择器「导入」到工作区、长按文件「导出/分享」。
- 模型：复用默认 API profile；Agent 会话可后续加 profile 选择，MVP 不做。

### D2. 数据模型（schema v10）

```dart
class AgentSessions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override Set<Column> get primaryKey => {id};
}

class AgentMessages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get role => text()();            // user / assistant / tool
  TextColumn get content => text()();
  TextColumn get toolCallsJson => text().nullable()();
  TextColumn get toolCallId => text().nullable()();
  TextColumn get toolName => text().nullable()();
  TextColumn get status => text()();          // streaming / done / error
  DateTimeColumn get createdAt => dateTime()();
  @override Set<Column> get primaryKey => {id};
}
```

`AgentSessionRepository`：会话 CRUD、消息插入/更新、按会话 watch 消息（页面级 `.autoDispose`）。

### D3. 工具协议与循环

扩展 `ApiMessage`：

```dart
final List<ApiToolCall> toolCalls; // assistant
final String? toolCallId;          // tool
final String? name;                // tool
```

`ApiToolCall{id, type:'function', function:{name, arguments}}`。

`ChatApiClient.streamChat` 新增 `List<ApiTool>? tools`，解析 `delta.tool_calls[]`（按 `index` 累积 `id/name/arguments` 片段），放入 `ChatDelta.toolCalls`，`finish_reason == 'tool_calls'` 时结束本轮。

循环（`AgentController.send`）：

```
messages = [system, ...历史, user]
for step in 1..maxSteps(默认6，硬上限12):
  流式请求（tools）
  渲染正文；若本轮有 toolCalls:
    落库 assistant(toolCallsJson)
    逐个执行工具（串行）：
      read/list 直接执行
      write 需用户确认（除非 agent_auto_write=true）
      结果落库 role=tool
    messages += assistant(toolCalls) + tool 结果
    continue
  否则：
    落库 assistant 正文; break
```

工具：

| 工具 | 参数 | 行为 | 限制 |
|---|---|---|---|
| `list_files` | `path="."` | 返回目录项（名称/大小/mtime） | ≤200 项，只列工作区内 |
| `read_file` | `path, offset=0, limit=2000` | 返回 UTF-8 文本片段 + total/nextOffset | 单次 ≤4,000 字符；二进制/越界报错 |
| `write_file` | `path, content` | 覆盖写；自动建父目录 | ≤64,000 字符；默认需确认 |

路径安全：`p.normalize` + 拼接根目录后 `canonicalize`，必须 `startsWith(workspaceRoot + separator)`；拒绝绝对路径、`..`、空路径；写入前检查目标不是符号链接（`File.resolveSymbolicLinks` 失败则按不存在处理）。

工具结果 JSON：`{"ok":true,...}` / `{"ok":false,"error":"..."}`；提示模型「工具失败时不要假装成功」。

系统提示：工作区根、可用工具、路径规则、写前先读、不要编造内容、最终回答用中文。

### D4. 安全与失败

- 只读工具自动执行；写工具默认弹确认（底部 sheet：路径、大小、前 2,000 字预览、确认/取消）。用户拒绝 → `{"ok":false,"error":"用户拒绝写入"}`，模型继续。
- 上下文预算：Agent 复用「上下文窗口」设置（按 90%）；工具结果进提示词前按剩余预算截断（默认最多占 35%），完整结果留在工具卡片；超过 3 步的旧工具结果优先裁掉，避免多步循环撑爆窗口。
- 工作区内不提供删除工具（MVP），避免误删；清空工作区需在 UI 二次确认。
- 供应商不支持 `tools`：首个请求 400/422 且错误体含 `tool`/`function` → 抛 `AgentToolsUnsupportedException`，UI 显示「当前模型不支持工具调用」+ 引导换模型；设置里可关闭工具模式退化为普通对话。
- 流中断：保留半截文本 + 错误卡片；工具执行中取消：已执行的写入不回滚，UI 明示。

### D5. 测试

- `agent_tool_executor_test.dart`：`../`、绝对路径、大小上限、非 UTF-8、正常读写、目录不存在。
- `agent_loop_test.dart`：fake API 先返回 tool_calls 再返回正文；消息顺序（assistant tool_calls → tool → assistant）；maxSteps 截止；取消。
- `agent_message_codec_test.dart`：`toJson` 的 tool_calls/tool 形状。
- `agent_page_test.dart`：写入确认弹层允许/拒绝；空工作区引导。
- `migration_test.dart`：v9→v10 建表。

### D6. 工时

- 数据层 + 迁移：0.5d
- 客户端 tool_calls + codec：0.5d
- 工作区与工具执行（含安全）：0.5d
- 控制器循环 + 持久化：0.7d
- UI（列表/对话/确认/导入导出）：0.8d
- 测试与真机：0.5d

### D7. 备选（不在本期）

让角色会话内调用工具读写「记忆/角色卡」：需要权限模型、防止提示词注入篡改记忆、写入审计；建议 v1.5 再评估，且必须默认确认。

---

## 7. 实施顺序与里程碑

| 里程碑 | 内容 | 涉及文件 | 验收 |
|---|---|---|---|
| M1（P0） | 输出稳定性 | `chat_api_client.dart`、`sse_decoder.dart`（tee）、`chat_controller.dart`、`chat_page.dart`、测试 | 空流不再留空泡；length 能自动重试；非 SSE JSON 能出字；mock 四场景通过 |
| M2（P1） ✅ | 上下文窗口 + 用量组件 | `token_estimate.dart`（新）、`context_usage_chip.dart`（新）、`app_settings_repository.dart`、`prompt_assembler.dart`、`chat_controller.dart`、`settings_page.dart`、`chat_page.dart`、测试 | 设置 4,096 token 后请求历史估算 ≤ 3,686；跨会话引用可调 0–8,192；重启保留；chip/sheet 显示已用、剩余与分类明细 |
| M3（P1） ✅ | 记忆 v2 + 共享 + 压缩 | `tables.dart`、`app_database.dart`、`chat_repository.dart`、`memory_summarizer.dart`、`character_memory_page.dart`、`prompt_assembler.dart`、测试 | 两会话摘要互相可见；记忆页刷新；无半句截断；图片摘要纳入；事实带日期且细节按期过期 |
| M4（P2） ✅ | Agent | 新 `features/agent/*`、`tables.dart`、`app_database.dart`、`chat_api_client.dart`、`app.dart`、测试 | 读/写/列目录可用；写入需确认；路径逃逸被拒 |
| M5 | 回归与真机 | 全量 `flutter test`、`flutter analyze`、MuMu 手工 | 304+ 全绿，无新增 analyze 警告 |

### 7.1 M1 完成记录（2026-11-23）

- 代码：`chat_api_client.dart` 解析归一化 + 整包 JSON/tee 兜底；`chat_controller.dart` 空流判空、清理占位、一次自动重试（length 加大预算）、异常前 flush 半截；`app_settings_repository.dart` + `settings_page.dart` 增加「空回复自动重试」开关；`message_list.dart` 空泡防御。
- 测试：新增 `chat_controller_test.dart` 10 项、`openai_chat_client_test.dart` 6 项、settings 1 项；`flutter analyze` 零问题；`flutter test` **321 项全过**。
- 待真机：MuMu + `build/mock_openai_server.py` 四场景（关键词「空流」「长度」「整包JSON」「推理」），需 `adb reverse tcp:8089 tcp:8089`，profile 指向 `http://127.0.0.1:8089/v1`。
- 未做：A3 的「错误提示里的重试按钮 / `retryLastTurn()`」。当前自动重试已覆盖偶发空流，且错误提示会说明原因；按钮留到 M5 视真机反馈再定。

### 7.2 M2 完成记录（2026-11-23）

- 代码：新增 `lib/core/utils/token_estimate.dart`（CJK 1.2 token/字、其他 3.5 字符/token、`truncateToTokens`）；`app_settings_repository.dart` 增加窗口 1024–32,768（默认 4,096、步进 512）与跨会话 0–8,192（默认 1,024）KV 及 clamp；`prompt_assembler.dart` 改为 `PromptUsage` + `assembleDetailed`/`assembleBare`，历史按 `budget * 0.9` 从新到旧取、单条超 30% 截断、至少 2 条兜底、跨会话独立预算；`chat_controller.dart` 接入设置并把 `usage` 写入 `ChatUiState.contextUsage`；新增 `context_usage_chip.dart`（AppBar chip + 明细 sheet，70/90 阈值）；`settings_page.dart` 增加「上下文窗口」tile 与 2K/4K/8K/16K 预设 sheet。
- 测试：新增 `token_estimate_test.dart`（10 项）、`context_usage_chip_test.dart`（4 项），`prompt_assembler_test.dart` 改为 45 条不硬截断 + 小预算 + 预留 + 跨会话 0 + 超长单条截断，settings repo 增加窗口/跨会话 clamp 与持久化，controller 增加 `contextUsage` 断言。
- 结果：`flutter analyze --no-pub` 零问题；`flutter test` **341 项全过**。
- 待真机（M5）：芯片/弹层在 MuMu 上的布局与颜色，设置 sheet 调窗口后 mock 日志确认历史预算生效。

### 7.3 M3 完成记录（2026-11-23）

- 数据层：schema v9 新增 `memory_cursors`（角色+会话复合主键）与 `memory_facts`（事实 + 发生日期 + 来源会话），索引 `idx_memory_facts_character_occurred`；`app_database.dart` 的 `from < 9` 只建表，旧库无损；drift 生成代码已重跑。
- 摘要器：`memory_summarizer.dart` 改为按会话游标取增量、最多 4 个会话 / 80 条；水位线在调 LLM 前捕获，事实插入成功后才推进游标；同一请求输出「近期 / 新事实 / 对用户的了解」三段，标记容忍 `#*_\`~[]【】`、缺标记整段当近期记忆；maxTokens 2,048；失败补跑 1 次（改为 `await`，保证测试/DB 生命周期确定）；近期上限 800、画像 500，按节/句截断；事实按「完全匹配 + 二元组 ≥ 0.8」去重、每角色 240 条。
- 共享：`chat_repository.dart` 新增 `getConversationsForCharacter`（非 archived、更新倒序）、`getDoneMessagesAfter`（含纯图 imageSummary，`>= since`）、`getCrossSessionDigest`（4 组 × 8 条、组内升序）；`prompt_assembler.dart` 按「【会话：标题】」注入，新增长期事实块（场景后、近期摘要前，≤ 60 条 / 1,200 字，明确「只记得事实与时间、被问细节不要编造」）。
- 记忆页：三段「角色记忆 / 长期记忆 / TA眼中的你」；下拉刷新 + AppBar 刷新；识别 `#` 与独占一行 `**标题**`；长期记忆时间线、长按二次确认删除；导出 PNG/Word 包含长期记忆。
- 测试：`memory_summarizer_test.dart` 12 项（多会话/游标/容忍标记/截断/补跑/事实去重/纯图/角色已删）；`chat_repository_test.dart` 17 项（含 digest 配额、archived、纯图）；`prompt_assembler_test.dart` +5 项（事实块、分组、预算 0、60 条上限）；`migration_test.dart` 增 v8→v9；新增 `character_memory_page_test.dart` 5 项（分节解析 + 三段切换 + 长按删除）。
- 结果：`flutter analyze --no-pub` 零问题；`flutter test` **362 项全过**。
- 待真机（M5）：两会话各发 6 条 → 记忆页包含两边事件；3 天后旧细节从「近期」消失、只留事实；追问细节不编造。

### 7.4 M4 完成记录（2026-11-23）

- 数据层：schema v10 新增 `agent_sessions` / `agent_messages`（role、toolCallsJson、toolCallId、toolName、status），索引 `idx_agent_messages_session_created`；`from < 10` 只建表，旧库无损。
- 协议：`ApiMessage` 支持 `tool_calls` / `tool_call_id` / `name`；`ChatApiClient.streamChat` 支持 `tools` + `tool_choice: auto`，按 `index` 累积 `delta.tool_calls`，在 `[DONE]` 或流尾 flush；整包 JSON 解析 `message.tool_calls`；400/422 且错误体含 tool/function 转 `AgentToolsUnsupportedException`。
- 工作区：`getApplicationSupportDirectory()/agent_workspace`；`list_files` ≤ 200 项、`read_file` 分页单次 ≤ 4,000 字符、`write_file` ≤ 64,000 字符；拒绝绝对路径 / `..` / 盘符 / NUL / 符号链接逃逸；`clear()` 保留根目录。
- 控制器：最多 6 步（硬上限 12），工具串行；写工具默认确认（`auto_write` 可关）；拒绝回填 `{"ok":false,"error":"用户拒绝写入"}`；取消/异常保留半截并删空占位；模型不支持工具时提示并降级。
- UI：底部第 5 tab（会话 / 角色 / Agent / 桌宠 / 设置）；会话列表（新建 / 重命名 / 删除）；对话页工具卡片、写确认卡、停止生成、工作区面板（列表 / 复制内容 / 导入文本 / 清空）。导出暂用「复制到剪贴板」，`share_plus` 分享留 polish。
- 测试：`agent_tool_executor_test` 7、`agent_repository_test` 4、`agent_controller_test` 7、`agent_page_test` 2、`migration_test` 扩到 v8→v10；`flutter analyze` 零问题；`flutter test` **382 项全过**。
- 未做/限制：①设备内 profile key 请求返回 401 `Invalid API Key`，真实 mimo `tool_calls` 未验证（mock/单测已覆盖协议），需有效 key 后补；②设置页尚未暴露 `agent_auto_write` / `agent_max_steps` / `agent_enabled` 三个 KV（代码可读，默认 autoWrite=false、maxSteps=6、enabled=true），留 M5 视需要补；③工作区导出用复制替代分享。

### 7.5 M5 进展（2026-11-23，真机部分）

- 自动化回归：`flutter analyze --no-pub` 零问题；`flutter test --no-pub` **383 项全过**。
- MuMu 真机（`app-release.apk` 为 debug 签名，`adb install -r` 保留数据）：v10 迁移成功，旧会话/角色未丢；底部五 tab 正常；Agent 空态、新建会话、输入栏、工作区面板（路径 `/data/user/0/…/files/agent_workspace`、导入/清空）正常；聊天页 AppBar 显示「上下文 --」chip。
- 真实 API（用户更新 key 后）：无角色新会话发 `hi` 成功，回复正常、chip 显示「上下文 1%」；角色会话连发 3 次 `hello` 后 chip 41%；Agent 发 `List the files please` → 模型发起 `list_files` 工具调用并收到结果，确认 mimo-v2.6-flash 支持 `tool_calls`；发 `Write hello to todo.txt` → 写确认卡 → 允许后 `{"ok":true,"path":"todo.txt","chars":6}`。
- 本轮修复：
  1. **Agent Markdown 未渲染**：引入 `flutter_markdown: ^0.7.7+1`，assistant 气泡改 `MarkdownBody`（用户气泡仍 `SelectableText`）；`agent_page_test` 断言改 `findRichText`。
  2. **工作区写文件误报「路径越出工作区」**：`AgentWorkspace.open()` 改为 `create` 后 `resolveSymbolicLinks()` 再用真实路径构造（Android `/data/user/0/...` 是 `/data/data/...` 的 symlink，原实现 canonical 比较一侧未解析）。
  3. **记忆摘要被英文拒绝串污染**：设备上摘要返回 `The request was rejected because it was considered high risk`，无分节标记 → 旧逻辑整段当近期记忆写库。`memory_summarizer.dart` 增加守卫：无标记且（命中拒绝关键词或完全不含中文）→ 保留旧文档、不推进游标；新增回归测试（13/13）。
- 已知行为（非 bug）：旧会话 pin 了创建时的 `apiProfileId`，换 key/default 后旧会话仍用旧 profile → 401；新建会话走当前 default，正常。设置页仍未暴露 `agent_auto_write` / `agent_max_steps` / `agent_enabled`。
- 真机复验（22:46–22:51）：清掉被污染的星野雀记忆后重发消息，摘要成功写回「3 条近期记忆」与 10 条长期事实；记忆页三段正常，证明守卫不会误杀正常三段输出。Agent 端「直接回答」的 Markdown 标题/要点已按 rich text 渲染（`#`/`-` 不裸奔），代码块按等宽块渲染。
- 未完成（可选）：M1 mock 四场景（空流/长度/整包JSON/推理）需临时把 profile 指向 `http://127.0.0.1:8089/v1`；M3 跨会话共享与 3 天事实过期仍建议在干净数据上再走一遍；设置页 Agent 三个 KV 待暴露。事实日期由模型给出，本轮出现把 2026-10 写成 2025-10 的年份偏差，属模型抽取质量问题，可后续在提示词中强调「年份以消息时间为准」。

---

## 8. 测试与验收

### 8.1 自动化

- `flutter analyze` 零新增。
- `flutter test`：383 项（M1 321 → M2 341 → M3 362 → M4 382 → M5 记忆守卫 383）。
- 新增/修改用例覆盖：解析归一化、整包 JSON、空流重试、窗口参数、游标推进、容忍标记、截断边界、digest 配额、路径安全、工具循环、tool_calls 编解码、Agent 会话/消息、v8→v10 迁移。

### 8.2 手工（MuMu + mock）

1. `build/mock_openai_server.py` 已加场景开关（按最后一条用户消息关键词）：发「空流」首次空、二次正常；发「长度」首次 length 空正文、二次正常；发「整包JSON」返回 `application/json` 整包；发「推理」只返回 `reasoning_content`。逐项在 MuMu 真机验收。
2. 两会话记忆：A 发 6 条、B 发 6 条 → 记忆页「角色记忆」包含两边事件；导出 Word 检查分节完整。
3. 窗口：设置 1,024 / 4,096 / 8,192 → mock 日志（可临时加打印）确认请求 messages 的估算 token ≤ 窗口 90%；跨会话引用设 0 → 无「【其他对话】」片段，摘要仍在。
4. Agent：读文件、写文件（确认/拒绝）、`../` 逃逸、大文件、取消。

### 8.3 对照验收

| 诉求 | 验收标准 |
|---|---|
| 空/错误输出 | 连续 20 次流式请求不出现空 assistant 消息；length 截断自动重试成功或给明确提示 |
| 记忆显示/丢失 | 两个会话的记忆都进入摘要；记忆页内容完整（无半句/无丢节）；刷新可见新摘要 |
| 记忆压缩 | 事件在事实库中只有一条事实 + 发生日期；保留期满后近期摘要不再有该事件细节；追问细节时模型不编造 |
| 自定义上下文窗口 | 设置 1,024–32,768 token 生效，重启保留；历史部分估算不超预算的 90%；跨会话引用可独立调 0–8,192；用量组件显示的已用/剩余与分类合计一致 |
| 多会话共享 | 摘要覆盖全部非归档会话；其他会话片段按会话分组且带标题 |
| Agent | 可列出/读取/写入工作区文件；写入默认需确认；无法越出工作区 |

---

## 9. 风险与回退

| 风险 | 影响 | 缓解 |
|---|---|---|
| 自动重试翻倍消耗 | 空流时多一次请求 | 仅零正文重试 1 次；设置里可关闭「自动重试」（默认开） |
| 摘要回填消耗额度 | 升级后首轮每角色多 1 次请求 | 只在有未摘要消息时触发；最多 4 会话 × 80 条 |
| 摘要变长挤占窗口 | prompt 变大 | 800/500 字符上限 + 分节截断；窗口可调 |
| token 估算偏差 | 实际请求可能超预算，供应商报超长 | 按 90% 预算使用；设置页明示「估算」；报错时引导调低窗口 |
| schema v9/v10 迁移失败 | 启动崩溃 | 迁移测试；只加表不改列；备份导出（M5 既有计划）不在本期 |
| 供应商不支持 tools | Agent 不可用 | 明确报错 + 普通对话降级开关 |
| 文件路径逃逸 | 数据泄露/覆盖 | canonicalize 前缀校验 + 单测 |
| 提示词注入（文件内容） | 模型被诱导 | 文件内容仅作数据；写操作需确认；不提供删除 |

回退开关：

- `memory_enabled` 已有关闭能力（摘要/共享全部停用）。
- `agent_enabled`（新增 KV，默认开）可隐藏 Agent tab。
- `auto_retry_enabled`（新增 KV，默认开）可关闭空流重试。

---

## 10. 已确认决策与开工条件

| 决策 | 结论 |
|---|---|
| Agent 读写对象 | 本地工作区文件（应用私有目录沙箱），写入默认确认 |
| Agent 入口 | 底部第 5 个 tab |
| 上下文窗口单位 | token 估算（中文 1 字 ≈ 1.2 token，英文 4 字符 ≈ 1 token），预算按 90% 使用 |
| 空流重试 | 允许 1 次，仅零正文时触发，设置里可关闭 |
| 旧会话补摘要 | 允许升级后一次性回填，每角色最多多 1 次请求 |
| 记忆压缩细节窗口 | 保留最近 3 天细节；更早的事件只保留事实 + 发生日期（`kRecentMemoryDays = 3`） |
| 上下文用量组件 | 聊天页顶部 chip 显示百分比；点开 bottom sheet 看已用/剩余与五类明细；不做常驻进度条 |

无剩余产品决策。M1–M4 已完成代码与自动化验证；M5 已做真机回归：v10 迁移、五 tab、真实 chat/tool_calls/write_file、Markdown 渲染、canonical 路径、记忆防污染均已验（383 项测试、analyze 零问题）。剩余可选：①M1 mock 四场景（临时 profile 指向本地 mock）；②M3 两会话记忆/事实过期在干净数据上复验；③记忆守卫重装后复验；④设置页暴露 Agent 三个 KV。旧会话 401 属 profile pin 的预期行为，不是缺陷。
