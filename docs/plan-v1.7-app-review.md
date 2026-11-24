# 心语 App 全面评估与改进方案（v1.7）

> 评估日期：2026-11-24
> 评估基线：v1.6.1+11，schema v11，418 项测试，`flutter analyze` 0 问题
> 评估方式：代码盘点 + 测试/构建检查 + 真机回归（MuMu，Android 13）+ 近期问题复盘

---

## 0. 一句话结论

这是一款**功能完成度很高、测试底子不错**的个人向 AI 角色扮演 App：聊天、角色卡、记忆、语音、桌宠、Agent、SAF/Shizuku 都已落地，418 项自动化测试全部通过。

但当前版本更像是「能自己用的完整原型」，距离「可以稳定发布、换机不丢数据、长期可维护」还有三类硬缺口：

1. **发布与数据安全**：release 仍用 debug 签名；API Key 明文存在 SQLite；系统备份默认开启；没有整库备份/恢复。
2. **日常体验缺口**：消息不能重发/编辑/删除/复制；会话不能搜索/置顶/归档；错误提示没有「重试」；老会话换 Key 后 401；聊天页上下文 chip 打开时是 `--`。
3. **可维护性**：`agent_tools.dart` 1,601 行、`agent_chat_page.dart` 1,005 行、`settings_page.dart` 954 行、`chat_controller.dart` 718 行；App 无 CI、无集成测试、README 仍写 304 项/4 tab。

建议先做 **v1.7 安全与日常可用性（约 2 周）**，再做 **v1.8 架构与体验**，最后做 **v2.0 Agent 安全与扩展**。不要先加新功能。

---

## 1. 现状量化

| 指标 | 数值 |
|---|---|
| Dart 文件 | 95 个（`lib/`） |
| `lib/` 代码行 | 29,514 行（含生成的 `app_database.g.dart` 10,684 行） |
| 测试文件 / 行数 | 40 个 / 8,087 行 |
| 自动化测试 | **418 项全过**；`flutter analyze` 0 |
| 数据库 | Drift，schema v11 |
| 版本 / 包体 | 1.6.1+11 / release APK 约 79.4 MB |
| 主要依赖 | Riverpod 3、Drift、dio、just_audio、flutter_inappwebview、file_picker、image、archive、markdown、pdf、flutter_markdown、Shizuku API |
| 主导航 | 会话 / 角色 / Agent / 桌宠 / 设置（5 tab） |
| 真机已验证 | 聊天、记忆摘要/事实、上下文窗口、Agent 工具/SAF/shell/HTTP/搜索/转 PNG、无障碍读屏 |
| 真机未覆盖/受限 | Shizuku 未安装；`device_click_text` 有 `clicked=false`；web_search 依赖 360 页面 |

### 体量最大的文件

| 文件 | 行数 | 说明 |
|---|---:|---|
| `lib/features/agent/application/agent_tools.dart` | 1,601 | 15 个工具 + 工作区/SAF/搜索/设备/转换全在一起 |
| `lib/features/agent/presentation/agent_chat_page.dart` | 1,005 | 会话、消息、确认卡、权限面板、工作区面板 |
| `lib/features/settings/presentation/settings_page.dart` | 954 | 设置 + 上下文窗口 + Agent 权限 + 手机控制 |
| `lib/features/chat/application/chat_controller.dart` | 718 | 发送、流式、重试、分段、语音、记忆、标题、贴纸 |
| `lib/features/chat/data/chat_api_client.dart` | 674 | OpenAI 兼容协议 + 工具协议 + SSE + 兜底 |
| `lib/features/agent/application/agent_controller.dart` | 645 | 工具循环、审批、上下文、系统提示 |
| `lib/features/characters/presentation/character_memory_page.dart` | 525 | 三段记忆 + 导出 |
| `lib/features/chat/application/memory_summarizer.dart` | 459 | 多会话摘要 + 事实 + 防污染 |

---

## 1.5 值得保留的设计（不要推倒重来）

- **流式稳定性**：空流判空、一次自动重试、整包 JSON 兜底、`reasoning_content` 隔离、`finish_reason` 处理，这些是踩坑后的有效积累。
- **记忆 v2**：按会话游标、多会话聚合、事实+近期双轨、3 天细节窗口、防拒绝串污染，方向正确。
- **上下文用量**：`PromptUsage` 分类 + 90% 预算 + chip/sheet，用户可感知，是差异化能力。
- **Agent 工具协议**：9→15 个工具、审批模式、SAF/Shizuku/无障碍、二进制读写，能力边界清晰。
- **测试习惯**：418 项、迁移测试、fakes 齐全；新增功能基本都带测试，这在个人项目里很难得。
- **Drift + Riverpod**：技术选型没问题，不需要换框架；问题在文件组织和数据访问方式。

**不建议**：为了「架构整洁」重写聊天/Agent 主流程；先修 P0，再逐步抽模块。

---

## 2. 发现清单（按严重度）

### P0：发布与数据安全（必须先解决）

#### P0-1 release 仍用 debug 签名
- 证据：`android/app/build.gradle.kts` 的 `buildTypes.release` 仍是 `signingConfig = signingConfigs.getByName("debug")`，注释 TODO 未处理。
- 影响：无法正规上架；不同机器构建的 APK 升级会签名不一致；用户数据迁移/信任链脆弱。
- 方案：生成正式 keystore（离线保存），`key.properties` + `signingConfigs.release`；构建 AAB；CI 注入密钥；`flutter build appbundle`。

#### P0-2 API Key 明文 + 系统备份默认开启
- 证据：`lib/data/local/tables.dart:83` `ApiProfiles.apiKey`、`TtsProfiles.apiKey` 均为普通 `text()`；`AndroidManifest.xml` 没有 `android:allowBackup="false"`，也没有 `dataExtractionRules`，默认允许云备份/ADB 备份。
- 影响：换机/云备份可能带走 Key 与全部聊天；设备丢失无应用锁；隐私风险高。
- 方案：
  1. 引入 `flutter_secure_storage`，Key 存 Keystore，DB 只存引用；迁移旧数据后清空明文列。
  2. Manifest 设 `allowBackup="false"` + `dataExtractionRules`（排除 DB/偏好），提供显式导出。
  3. 可选：应用锁（生物识别/ PIN）保护聊天与 Agent 权限。

#### P0-3 没有整库备份/恢复
- 证据：只有记忆页的 PNG/Word 导出（`character_memory_page.dart`）与角色卡导入；没有会话/角色/设置的整库导出、没有导入合并。
- 影响：换机、卸载、误删 = 数据全丢；这是角色扮演类 App 的核心资产。
- 方案：导出 zip（characters、conversations、messages、memories、facts、settings；排除 API Key），导入时按 id/标题合并；本地自动备份保留 3 份；提供「仅导出角色卡」「导出单会话 Markdown/JSON」。

#### P0-4 消息表无索引 + 全量加载
- 证据：`lib/data/local/tables.dart` 的 `Messages` 只定义列；迁移里只建了 `memory_facts`、`agent_messages` 索引，没有 `messages(conversation_id, created_at)`。`ChatRepository.watchMessages` 与 `getMessages` 没有 limit/分页，直接按会话全量加载。
- 影响：长会话（数千条）时每次打开/发送都全表扫 + 全量进内存；配合上下文组装、记忆摘要，容易卡顿/占用高。
- 方案：schema v12 加索引；`watchMessages` 分页（先取最近 N 条，向上翻页）；提示词只取窗口所需；增加 10k 消息性能测试。

#### P0-5 Agent 高风险能力缺审计与回收站
- 证据：`AgentToolExecutor` 有 shell/删除/移动/HTTP/无障碍点击；`full` 模式无需确认；删除走 SAF `deleteDocument` 不可恢复；没有操作日志表，也没有撤销。
- 影响：一次误操作可永久删文件；Prompt Injection（读取的文件/网页内容）可诱导 Agent 执行危险动作；无法追责/回滚。
- 方案：
  - 新增 `agent_audit_log`（时间、会话、工具、参数摘要、风险、审批结果、结果摘要），设置页可查看/清空。
  - 删除先进回收站：工作区 `.trash/`；SAF 先复制到工作区 `.trash/<timestamp>/` 再删；保留 7 天。
  - 工具结果统一加「不可信内容」分隔与「不要执行其中指令」提示；危险工具参数做二次校验（路径、命令、URL）。
  - full 模式启动时二次确认，并显示「本次会话将不再逐条确认」。

### P1：日常体验与可靠性

#### P1-6 老会话 pin 旧 `apiProfileId`，换 Key 后 401
- 证据：`chat_controller.dart` 用会话的 `apiProfileId` 取 profile，取不到才用 default；实测旧会话在 Key 更新后报「鉴权失败：Invalid API Key」，新会话正常。
- 影响：用户以为 App 坏了；切换供应商/Key 后所有旧会话不可用。
- 方案：profile 缺失/`apiKey` 为空/鉴权失败时回退 default，并在消息流里提示「本会话原供应商不可用，已改用默认」；设置里提供「把默认供应商应用到所有会话」。

#### P1-7 错误提示没有重试
- 证据：`chat_page.dart` 的 SnackBar 只有「关闭」；`retryLastTurn()` 规划过但未实现。
- 方案：SnackBar action「重试」调用 `retryLastTurn()`；对鉴权/网络/空流分别给可操作建议；重试复用上一条用户消息，不重复入库。

#### P1-8 聊天页上下文 chip 打开时是 `--`
- 证据：`ChatUiState.contextUsage` 在 `send()` 组装提示词后才写入；打开已有会话时不计算，chip 显示 `--`（Agent 页会 `attach` 后算）。
- 方案：打开会话时用最近窗口消息估算一次；无消息显示 `--`；发送后刷新。

#### P1-9 记忆只能删事实，不能编辑/新增/重生成
- 证据：`character_memory_page.dart` 有长按删除；没有编辑摘要/画像、添加事实、手动「重新整理」。
- 方案：记忆页加「编辑摘要」「编辑画像」「添加事实」「重新整理」；事实支持编辑日期/内容；摘要仍由模型生成，但可人工修正。

#### P1-10 没有消息级操作与会话管理
- 证据：`message_list.dart` 只有 `SelectableText`/图片点击；没有长按菜单。会话列表只有删除；`archived` 字段存在但无 UI；没有搜索/置顶/重命名。
- 方案：消息长按菜单（复制/重发/编辑/删除/朗读）；会话长按菜单（重命名/置顶/归档/导出）；标题栏搜索（先按标题，后接 FTS）。

#### P1-11 web_search 依赖 360 页面结构
- 证据：`agent_tools.dart` 的 `_webSearch` 顺序 360 → 百度 → Bing RSS → Bing HTML → DDG；360 是 HTML 正则解析，页面改版即失效；无缓存、无 provider 配置。
- 方案：搜索结果缓存（10 分钟）；设置里允许填 SearXNG/Bing API/Serper 端点；360 解析失败时明确提示「搜索源不可用，可配置搜索引擎」；结果去重与来源标注。

#### P1-12 设置/权限 UI 重复且过大
- 证据：`settings_page.dart` 954 行；全局 Agent 权限 sheet 与会话内权限 sheet 各维护一套模式/文件夹/SAF 选择逻辑。
- 方案：抽出 `AgentPermissionEditor`（模式 + 文件夹 + 手机控制）；设置页拆成「外观/聊天/语音/Agent/关于」子页；会话内复用编辑器，只改作用域。

#### P1-13 无障碍与动态字体未验证
- 证据：代码中没有 `Semantics`/`textScaler` 相关处理；图标按钮多用 `tooltip`；固定高度/`SizedBox` 较多；未做 TalkBack/大字体真机测试。
- 方案：关键按钮补 `Semantics(label:)`；布局改 `Wrap`/`Flexible`；用系统 200% 字体与 TalkBack 跑主流程；补 golden/溢出测试。

#### P1-14 仅中文硬编码，README 过期
- 证据：所有文案硬编码中文；无 `flutter_localizations`/ARB；`README.md` 仍写 304 项测试、4 个 tab、近期更新停在 v1.3。
- 方案：引入 ARB（中/英）；README 更新到 v1.6.1（5 tab、418 测试、Agent/SAF/Shizuku/搜索/PNG、已知限制）。

#### P1-15 没有 App CI / 集成测试 / 性能门禁
- 证据：仓库只有 `.github/workflows/pages.yml`（部署宣传页），没有 App 的 analyze/test/build 流水线；`integration_test/` 不存在；测试全是单测/组件测；无 golden、无性能基准。
- 方案：GitHub Actions（analyze + test + build debug APK）；新增 `integration_test`（mock SSE 服务）覆盖发送/重试/记忆/Agent 工具确认/备份导入；关键页 golden；性能基准（启动、打开 10k 消息会话）。

### P2：优化项

- **P2-16 依赖与体积**：`flutter_markdown` 已停止维护；`permission_handler` 固定 11.3.1；APK 79 MB 未 split/obfuscation。评估替代（`flutter_markdown_plus`/`markdown_widget`），升级依赖，`--split-per-abi` + R8。
- **P2-17 数据库无 FTS**：消息搜索只能内存过滤；后续加 FTS5（`messages_fts`）与搜索页。
- **P2-18 崩溃/诊断**：无 crash reporting（隐私取舍）；至少加本地错误日志（脱敏、可导出），便于排查空回复/搜索失败。
- **P2-19 角色卡只能导入**：补导出 PNG/JSON；贴纸/表情包管理入口。
- **P2-20 语音真机覆盖不足**：TTS/ASR 测试多为 fake；补真机回归清单（打断、切后台、蓝牙、静音）。
- **P2-21 发布物料**：隐私政策、BYOK/云端数据说明、应用商店截图/描述、版本迁移说明。

---

## 3. 路线图与工时

### v1.7 安全与日常可用性（建议 2 周，优先）

| 项 | 内容 | 工时 | 验收 |
|---|---|---:|---|
| 1 | 正式签名 + AAB + CI 构建 | 1d | `apksigner verify` 通过；CI 产出 AAB |
| 2 | Key 迁移 secure storage；关闭 allowBackup；dataExtractionRules | 2d | 旧 Key 自动迁移；备份不含 DB/Key |
| 3 | 整库导出/导入 + 本地自动备份 | 2d | 导出→清空→导入回环，消息/角色/记忆一致 |
| 4 | messages 索引 + 分页 + 10k 消息基准 | 2d | 打开/发送 p95 < 200ms（模拟器基线） |
| 5 | Agent 审计日志 + 删除回收站 + full 二次确认 | 2.5d | 删除可恢复；审计页可见 |
| 6 | 老会话 profile 回退 + 重试按钮 + chip 打开即算 | 1.5d | 换 Key 后旧会话可用；错误可一键重试 |
| 7 | 记忆编辑/添加事实/重新整理 | 1d | 三段均可编辑并持久化 |
| 8 | 会话搜索/置顶/归档/重命名 + 消息长按菜单 | 2d | 搜索标题、置顶排序、归档隐藏、复制/删除/重发 |
| 9 | README/隐私说明/已知限制更新 | 0.5d | 文档与 1.6.1 一致 |

**v1.7 验收门槛**：analyze 0；测试 ≥ 450；release AAB 签名正确；备份回环通过；换 Key 旧会话可用；10k 消息不卡死；删除可恢复。

### v1.8 架构与体验（2–3 周）

1. 拆分大文件：`agent_tools` → `file_tools/web_tools/device_tools/convert_tools`；`chat_controller` → `reply_runner/prompt_context/usage`；`settings` 拆子页；抽 `AgentPermissionEditor`。
2. 统一错误模型：`AppFailure`（用户文案、可重试、技术细节），替换散落的 `AppException` 字符串。
3. FTS5 消息搜索 + 会话列表分页；会话导出 Markdown/JSON。
4. i18n（中/英）+ 无障碍（Semantics/动态字体/对比度）+ 平板/横屏布局。
5. 集成测试（mock SSE）+ golden + 性能基准；CI 增加 Android build。
6. 依赖升级与体积优化（split ABI、R8、资源按需）。

**验收**：单文件 ≤ 600 行；新增集成测试 ≥ 8 条；中英切换；TalkBack 主流程；APK 体积下降 ≥ 15%。

### v2.0 Agent 安全与扩展（3–4 周）

1. 工具结果不可信标记 + Prompt Injection 检测；危险工具 allowlist/deny。
2. 搜索 provider 可配置（SearXNG/Bing/Serper）+ 缓存 + 来源。
3. 成本预算：每日 token/费用上限，超限提醒/暂停；多模型路由（快/慢/便宜）。
4. 回收站/撤销、审计查看页、shell 命令白名单/超时/沙箱说明。
5. 可选：定时任务/触发器、角色卡导出、桌面端/平板。

---

## 4. 建议先做的 10 个「快赢」

1. release 签名 + `flutter build appbundle`。
2. `android:allowBackup="false"` + `dataExtractionRules`。
3. `flutter_secure_storage` 迁移 API Key。
4. messages `(conversation_id, created_at)` 索引（schema v12）。
5. 老会话 profile 回退 default + 提示。
6. SnackBar「重试」调用 `retryLastTurn()`。
7. 聊天页打开即计算 `contextUsage`。
8. 消息长按：复制/删除/重发（先做这三个）。
9. 记忆页「编辑摘要/画像 + 添加事实」。
10. README + 隐私说明 + 已知限制更新。

这些加起来约 1 周，能显著降低「数据丢失/换 Key 失效/长会话卡顿/无法排障」的风险。

---

## 5. 风险与取舍

- **Secure storage 迁移**：Android Keystore 在卸载/换机后不可恢复，必须配合导出；迁移失败要能回退到旧列并提示。
- **备份/导入**：id 冲突、角色重名、消息时间线错乱；需定义合并策略（默认按 id 覆盖、可「作为副本导入」）。
- **SAF 回收站**：复制大文件耗时；限制单文件 ≤ 10MB，超限只提示不自动备份。
- **全文搜索**：FTS5 需要新表与触发器，迁移成本高；可先做标题 + 最近消息内存搜索，再上 FTS。
- **web_search**：HTML 抓取不稳定且可能涉及服务条款；长期应提供可配置 API，而不是依赖单一站点。
- **发布合规**：BYOK + 云端语音/搜索涉及第三方数据处理；隐私政策与首次授权说明必须补齐。

---

## 6. 需要产品决策的点

1. 是否准备上架应用商店？决定签名、隐私政策、AAB、崩溃上报的优先级。
2. 是否要做中英双语？决定 i18n 是否进 v1.8。
3. Agent 的 `full` 模式是否保留？保留则必须加审计/回收站/二次确认。
4. 备份是「全量 zip」还是「仅角色卡 + 会话 Markdown」？前者体验好，后者实现快。
5. 搜索是否接受「可配置 API + 360 兜底」，还是必须零配置可用？

---

## 7. 结论

当前版本的功能与测试基础足以支撑一次「质量版本」，不建议继续堆功能。  
**推荐顺序：v1.7 安全与日常可用性 → v1.8 架构与体验 → v2.0 Agent 安全与扩展。**  
先做 P0 的签名、密钥、备份、索引、Agent 审计五项；这五项完成前，不建议对外大规模分发。

---

## 8. 已实施（2026-11-24）

- 关闭系统备份：`allowBackup="false"`、`fullBackupContent="false"`、`dataExtractionRules`（cloud-backup / device-transfer 全排除）。
- schema v12 索引：`messages(conversation_id, created_at)`、`conversations(character_id, updated_at)`；迁移测试覆盖 v8→12。
- 旧会话供应商回退：pin 的 profile 不存在或 Key 为空时改用默认，并 debugPrint 记录。
- 错误 SnackBar 增加「重试」：`ChatController.retryLastTurn()` 删除失败轮次后重发，不重复用户消息。
- 消息长按菜单：复制文本 / 删除（二次确认）；消息正文由 SelectableText 改为 Text 以让长按稳定触发。
- 验证：`flutter analyze` 0；`flutter test` **421 项全过**；release APK 79.5MB 安装，真机长按菜单可用。
- 待办：release 签名、flutter_secure_storage 迁移 Key、整库导出/导入、聊天打开即算 chip、会话搜索/置顶/归档、记忆编辑、Agent 审计/回收站/full 二次确认。
