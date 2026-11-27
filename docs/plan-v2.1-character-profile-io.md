# v2.1 方案：角色档案 + 角色卡导入导出

> 状态：M1–M7 代码/文档/构建完成（2026-11-27）；真机验收与站点发布待执行\
> 基线：v2.0.0+14，schema v16，`flutter test` 416 项通过（2026-11-27 实测）\
> 上游规划：`docs/plan-v1.8-character-studio-roleplay.md`（v1.8–v2.0 已完成）\
> 产品规划：`心语_AI角色工坊_升级改造计划.md`（外部文档）\
> 本版范围：角色档案扩容、ST V2/V3 导入导出、未知字段保留、角色版本快照、编辑器分区、四栏导航与资产页

---

## 0. 已定决策

| 决策点 | 结论 |
|---|---|
| 本轮计划层级 | 2.1 + 2.2 两版路线；2.1 做透，2.2 给方向 |
| 2.1 优先模块 | 角色档案 + 导入导出（其余进入 2.2） |
| 档案存储 | 混合：6 个 ST 核心字段继续用列，扩展档案与未知字段存 JSON |
| 底部导航 | 聊天 / 工坊 / 资产 / 设置；桌宠并入资产页 |
| 导入导出目标 | ST V3 为主，兼容 V1/V2；PNG 卡与 JSON 均支持 |

### 0.1 开工前置

当前工作区有 v1.8–v2.0 的未提交改动（Agent 移除、工坊、世界书、群聊、分支）。**先把这批改动提交并打一个可回退点**，再开 v2.1；否则新迁移与新测试会混在旧改动里，出问题无法定位。

---

## 1. 范围

### 1.1 本版做

- 角色档案：基础身份、外貌、背景、关系、语言风格、互动方式、创作者信息、运行配置。
- 档案进入提示词：分区块注入、长度上限、上下文用量可见。
- ST 导入：V1/V2/V3 JSON 与 PNG 卡；完整字段映射；未知字段与未知 extension 原样保留。
- ST 导出：V2 JSON、V3 JSON、PNG 卡；世界书随卡导出；导出前提示心语专有数据损失。
- 角色版本：保存时自动快照、手动保存版本、查看与恢复；每角色最多 20 条。
- 编辑器：基础 / 档案 / 高级三页签；多开场白可编辑；档案 Token 估算。
- 导航：聊天 / 工坊 / 资产 / 设置；资产页聚合桌宠、立绘、表情包、音色。

### 1.2 本版不做

| 功能 | 去向 |
|---|---|
| AI 概念生成、诊断、多方案、AI 修改历史 | 2.2 |
| 试聊、Prompt 完整预览、世界书/记忆命中调试 | 2.2 |
| 心语完整角色包（含 Live2D/音色/记忆） | 2.2 |
| 世界书共享库、多角色多对多绑定 | 2.3 |
| 记忆 3.0（关系事件/置信度/冲突） | 2.3 |
| 统一资产库、多立绘/服装、角色-Live2D 绑定 | 2.3 |
| 角色社区、云同步、插件 | 不做或长期后置 |

---

## 2. 数据模型（schema v17）

### 2.1 表变更

```text
characters
  + profile_json      TEXT NOT NULL DEFAULT '{}'   -- 扩展档案（本应用可编辑）
  + extensions_json   TEXT NOT NULL DEFAULT '{}'   -- 第三方扩展 + 未识别字段（只读保留）

lore_entries
  + source_json       TEXT NOT NULL DEFAULT '{}'   -- 导入时的完整条目原文，导出时合并

character_versions（新表）
  id               TEXT PRIMARY KEY
  character_id     TEXT NOT NULL
  snapshot_json    TEXT NOT NULL DEFAULT '{}'
  trigger          TEXT NOT NULL DEFAULT 'save'   -- save | manual | restore | import
  label            TEXT NOT NULL DEFAULT ''
  created_at_ms    INTEGER NOT NULL               -- 毫秒时间戳
索引：idx_character_versions_character (character_id, created_at_ms DESC)
```

### 2.2 迁移守卫（必须遵守）

`app_database.dart` 已有「`from<2` 时 createTable 按当前定义建表」的坑，v17 继续按同一规则写：

```dart
int get schemaVersion => 17;

if (from < 17) {
  // from<2 时 characters 已在上面按当前定义建出，不能再 addColumn。
  if (from >= 2) {
    await m.addColumn(characters, characters.profileJson);
    await m.addColumn(characters, characters.extensionsJson);
  }
  // lore_entries 在 from<15 时按当前定义建出，不能再 addColumn。
  if (from >= 15) {
    await m.addColumn(loreEntries, loreEntries.sourceJson);
  }
  await m.createTable(characterVersions);
  await _createCharacterVersionIndexes();
}
```

- `onCreate` 需补 `_createCharacterVersionIndexes()`。
- 迁移测试补：v8→v17、v14→v17、v15→v17、v16→v17；断言旧角色/世界书数据不丢。
- 迁移不重建表、不改旧列类型。

### 2.3 profile_json 结构

```json
{
  "v": 1,
  "basic": {
    "nickname": "", "age": "", "gender": "", "race": "", "identity": ""
  },
  "appearance": {
    "summary": "", "hair": "", "eyes": "", "outfit": "",
    "height": "", "body": "", "features": ""
  },
  "background": {
    "origin": "", "experiences": "", "keyEvents": "", "secrets": "", "goals": ""
  },
  "relationships": {
    "userRelation": "", "initialCloseness": "", "direction": "", "others": ""
  },
  "language": {
    "tone": "", "habits": "", "verbalTics": "", "commonPhrases": "", "taboos": ""
  },
  "interaction": {
    "replyLength": "", "initiative": "", "emotionExpression": "", "behaviorTendency": ""
  },
  "creator": {
    "author": "", "version": "", "tags": [], "notes": "", "copyright": ""
  },
  "runConfig": {
    "systemPrompt": "", "postHistoryInstructions": ""
  }
}
```

原则：

- 已知字段强类型解析；未知字段保留在域对象的 `extra`，重新编码时写回，避免降级丢字段。
- 坏 JSON / 类型不符：该节按空值处理，不阻塞角色读取；不删除原始字符串之外的数据（原始列仍在）。
- 单字段上限 8000 字符；`creator.notes` 上限 4000；`runConfig` 两项各由提示词层再限长。
- `name`、`description`、`personality`、`scenario`、`firstMessage`、`exampleDialogue` 仍是列，`basic.nickname` 不替代 `name`。

### 2.4 extensions_json 结构

```json
{
  "v": 1,
  "st_extensions": { "原 data.extensions 对象": "原样保留" },
  "unknown_data": { "未识别的 data 字段": "原样保留" },
  "unknown_root": { "未识别的根字段": "原样保留" }
}
```

- 导入时按 V2/V3 已知字段清单比对，其余全部进 `unknown_data` / `unknown_root`。
- 导出时先放回未知字段，再写已知字段，保证第三方数据往返不丢。
- UI 只读展示（高级页签），不提供手改入口，避免破坏 JSON。

### 2.5 版本快照

`snapshot_json` 内容：

```json
{
  "name": "", "description": "", "personality": "", "scenario": "",
  "firstMessage": "", "exampleDialogue": "",
  "alternateGreetings": [],
  "profile": {},
  "extensions": {},
  "source": "manual|st_v2|st_v3"
}
```

规则：

- `CharacterRepository.save()` 在覆盖前读取旧行；新旧内容相同（仅 updatedAt 变化）不写快照；旧快照与上一条版本不同才写入，`trigger='save'`。
- `created_at_ms` 用毫秒存储：Drift 的 `dateTime()` 按秒落库，同秒连续保存无法稳定排序。
- 每角色保留 20 条，超出删除最旧；恢复前先把当前状态存一条 `trigger='restore'`。
- **立绘不参与版本回滚**：头像文件按角色 id 固定路径，回滚只恢复文本档案；高级页签明确提示。
- 删除角色级联删除版本；版本页可查看单条差异摘要（字段名 + 是否变化），不做逐字 diff。

---

## 3. 档案进入提示词

### 3.1 注入顺序

在 `PromptAssembler.assembleDetailed` 中，人设之后、时间之前插入：

```text
1. system 人设（名字/描述/性格）                 —— 现状
2. system 角色档案补充（basic/appearance/...）   —— 新增，按节拼接，空节跳过
3. system 角色卡系统提示（runConfig.systemPrompt）—— 新增，≤2000 字符
4. system 当前时间                               —— 现状
5. system 场景                                   —— 现状
6. system 长期事实 / 记忆 / 跨会话 / 用户画像     —— 现状
7. system 对话示例                               —— 现状
8. system 输出格式规范                           —— 现状（仍保持在历史之前的最后一条）
9. 历史消息
10. 世界书 after
11. system 历史后置指令（postHistoryInstructions）—— 新增，≤1000 字符
```

### 3.2 拼接格式

```text
【角色档案补充设定】（按设定扮演，不要逐条复述）
身份：...
外貌：...
背景：...
与用户的关系：...
语言风格：...
互动方式：...
```

- 只注入 `basic/appearance/background/relationships/language/interaction`。
- `creator` 与 `extensions` 是创作/元数据，不进提示词。
- 单节超过预算时按 `truncateToTokens` 截断；整体上限 = 窗口 12%（最少 300 token，最多 1200 token）。
- `runConfig.systemPrompt` 与 `postHistoryInstructions` 单独成条，不与档案块混在一起。

### 3.3 冲突规则

- 角色卡系统提示不得覆盖输出格式规范：格式规范仍是历史前最后一条 system，并在卡内提示前加一句「在不违反输出格式规范的前提下遵循」。
- 卡内提示超长直接截断并保留尾部（指令通常在尾部）。
- 用户手动编辑 `runConfig` 优先于导入值，导入只填不覆盖已有内容（新建角色除外）。

### 3.4 用量展示

`PromptUsage` 新增：

- `profileTokens`：档案补充块。
- `cardPromptTokens`：systemPrompt + postHistoryInstructions。

`usedTokens` 计入两者；聊天页用量弹层新增「角色档案」「卡内提示」两行（为 0 时不显示）。现有 416 项测试中涉及 `PromptUsage` 的断言不得回退。

---

## 4. ST 导入升级

### 4.1 字段映射

| ST 字段 | 心语落点 |
|---|---|
| `name` | `characters.name` |
| `description` / `personality` / `scenario` | 对应列 |
| `first_mes` | `firstMessage` |
| `mes_example` | `exampleDialogue` |
| `alternate_greetings` | `alternateGreetings` |
| `nickname` | `profile.basic.nickname` |
| `creator` | `profile.creator.author` |
| `character_version` | `profile.creator.version` |
| `creator_notes` | `profile.creator.notes` |
| `tags` | `profile.creator.tags` |
| `system_prompt` | `profile.runConfig.systemPrompt` |
| `post_history_instructions` | `profile.runConfig.postHistoryInstructions` |
| `character_book` | `lore_entries`（默认禁用，现状保留） |
| `extensions` | `extensions_json.st_extensions` |
| 未识别字段 | `extensions_json.unknown_data` / `unknown_root` |
| `spec` / `spec_version` | 只记录在导入结果与 `source`，不写库 |

- V1 扁平结构、V2 `data` 包装、V3 `data` 包装统一走同一条解析路径。
- PNG 卡：`ccv3` 优先、`chara` 兜底（现状），两者都保留时以 `ccv3` 为准。
- `source` 扩展为 `manual | st_v1 | st_v2 | st_v3`；现有 `st_v2` 数据不迁移，按 `st_v2` 展示。

### 4.2 世界书条目保真

- `LoreDraft` 增加原始条目 JSON；落库时写 `source_json`。
- 仍默认禁用，交由用户逐条确认。
- 导出时以 `source_json` 为底，覆盖 `keys/content/position/depth/priority/enabled` 的当前值；未编辑过的条目可完整往返。
- 现有 `LoreEntry` 域模型不增加大量字段，避免 2.1 扩散到世界书重构（2.3 再做共享库）。

### 4.3 导入结果

新增 `CharacterImportResult`：

```dart
class CharacterImportResult {
  final Character character;
  final String format;          // v1 | v2 | v3
  final int loreCount;
  final int preservedKeyCount;  // 保留的未知字段数
  final List<String> warnings;  // 例如「世界书条目已导入但默认禁用」
}
```

导入完成后弹结果卡片：映射了哪些字段、保留了多少未知字段、导入了多少世界书、有哪些警告。**不静默丢弃**。

---

## 5. 导出

### 5.1 格式

| 格式 | 内容 | 入口 |
|---|---|---|
| V2 JSON | `{spec:"chara_card_v2", spec_version:"2.0", data:{...}}` | 编辑页 → 导出 |
| V3 JSON | `{spec:"chara_card_v3", spec_version:"3.0", data:{...}}` | 编辑页 → 导出 |
| PNG 角色卡 | 原立绘 + `tEXt` 块 `chara`(V2) / `ccv3`(V3) | 编辑页 → 导出 |

- PNG 导出要求已有立绘；非 PNG 立绘先用 `image` 包转 PNG；无立绘时禁用该选项并提示。
- PNG 写入器新建 `lib/core/utils/png_text.dart`：解析块、插入 `tEXt`、CRC32、写回；必须用现有 `SillyTavernImporter` 反向解析做测试。
- 文件名：`{角色名}-v2.json` / `{角色名}-v3.json` / `{角色名}.png`，非法字符替换为 `_`。
- 落临时目录后走 `share_plus` 分享（复用 `export_utils.dart` 的模式）。

### 5.2 导出映射

- 已知字段取当前值；`profile.creator` / `runConfig` 写回 ST 字段。
- `extensions`：先写 `st_extensions`，再合并 `unknown_*`；可选写入 `xinyu` 扩展（隐私/兼容提示见 5.3）。
- `character_book`：条目转回 ST 结构：
  - `keys`、`content`
  - `position`：before → `"before_char"`，after → `"after_char"`
  - `insertion_order` ← `priority`
  - `depth`
  - `enabled` ← 当前启停
  - 其余字段从 `source_json` 合并
- `alternate_greetings`、`tags`、`creator`、`character_version`、`creator_notes` 全部输出。

### 5.3 损失提示

导出前弹确认，列出目标格式**不包含**的心语数据：

- 跨会话记忆、长期事实、用户画像
- 音色配置、自定义音色
- Live2D/桌宠绑定、表情包
- 角色版本历史、AI 修改历史（2.2 才有）
- 档案中 ST 无对应字段的内容（写入 `extensions.xinyu` 可保留，但第三方软件可能忽略）

默认勾选「写入心语扩展（便于导回心语）」；取消后只导出 ST 标准字段。

---

## 6. 编辑器改造

### 6.1 三页签

`CharacterEditPage` 改为 `DefaultTabController(length: 3)`：

| 页签 | 内容 |
|---|---|
| 基础 | 立绘、名字、基础身份（昵称/年龄/性别/种族/身份）、描述、性格、场景、主开场白、多开场白列表、对话示例、标签 |
| 档案 | 外貌、背景、关系、语言风格、互动方式（5 个可折叠卡片） |
| 高级 | 创作者信息、卡内系统提示、历史后置指令、档案 Token 估算、未知扩展只读查看、版本历史入口、导出入口 |

- 记忆 / 世界书 / 表情包库入口保留在基础页顶部（现状位置）。
- 多开场白从「只导入不可编辑」升级为可增删改列表；空值不保存。
- 每节显示字符数 / 估算 Token；总档案 Token 超过窗口 12% 时提示「聊天时会截断」。
- 保存前校验：名字非空；单字段超长直接拦下并定位到对应页签。
- 离开时若有未保存改动，二次确认。

### 6.2 AI 改写

- 2.1 仍只对 6 个核心字段提供「AI 改写」。
- 扩展档案字段的 AI 辅助、多方案、诊断全部留到 2.2，避免服务白名单与提示词同时扩散。

### 6.3 版本历史

- 高级页签进入 `CharacterVersionPage`：时间倒序列表，显示触发方式与字段变化摘要。
- 单条可查看快照 JSON 的可读摘要；「恢复此版本」需二次确认。
- 恢复后自动回到编辑页并刷新控制器内容；立绘不恢复（界面明示）。

---

## 7. 导航与资产页

### 7.1 四栏

`app.dart` 改为：

```text
聊天（ConversationListPage）
工坊（CharacterWorkshopHomePage）
资产（AssetsPage）
设置（SettingsPage）
```

- 「会话」文案改「聊天」；`PetPage` 从底栏移除，改为资产页子页面。
- 工坊首页：顶部「AI 创作角色」卡片 + 「我的角色」列表（复用现有 `CharacterListPage` 内容）+ 导入入口。
- 不新增第五栏；设置页结构不动。

### 7.2 资产页

`AssetsPage` 四个入口：

| 入口 | 行为 |
|---|---|
| 桌宠模型 | 打开现有 `PetPage`（模型导入/切换/预览） |
| 角色立绘 | 角色头像网格，点按进入角色编辑 |
| 表情包 | 先选角色，再进 `StickerLibraryPage` |
| 音色 | 打开语音设置页（TTS 配置 / 音色工坊入口） |

- 2.1 只做聚合入口，不做统一资产表、不做多立绘/服装、不做角色-Live2D 绑定。
- 后续 2.3 再把资产页升级成真正的资产库。

---

## 8. 里程碑

| 里程碑 | 内容 | 主要文件 | 估时 |
|---|---|---|---|
| M0 | 提交 v1.8–v2.0 改动；确认 416 项基线；建 v2.1 分支/回退点 | — | 0.5d |
| M1 | schema v17、`character_versions`、`CharacterProfile`/`CharacterExtensions` 编解码、仓储读写与快照 | `tables.dart`、`app_database.dart`、`character.dart`、`character_profile.dart`、`character_repository.dart`、`migration_test.dart` | 2d |
| M2 | 导入升级：V1/V2/V3 字段、未知字段保留、世界书 `source_json`、导入结果 | `silly_tavern_importer.dart`、`character_import_result.dart`、导入 UI、fixtures | 2d |
| M3 | 提示词注入与用量：档案块、卡内提示、`PromptUsage` 新字段、用量弹层 | `prompt_assembler.dart`、`context_usage_chip.dart`、`chat_controller.dart`、`prompt_assembler_test.dart` | 1.5d |
| M4 | 导出：V2/V3 JSON、PNG `tEXt` 写入器、损失提示、分享 | `character_card_exporter.dart`、`png_text.dart`、编辑页导出 sheet、导出测试 | 2.5d |
| M5 | 编辑器三页签、多开场白编辑、档案字段、Token 估算、版本历史页 | `character_edit_page.dart`、`character_version_page.dart`、`character_profile_section.dart` | 2.5d |
| M6 | 四栏导航、工坊首页、资产页、桌宠入口迁移 | `app.dart`、`workshop_home_page.dart`、`assets_page.dart`、`widget_test.dart` | 1.5d |
| M7 | 全量测试、真机回归、版本号 2.1.0+15、README/release notes | 全局 | 1.5d |

依赖：M1 → M2/M3/M4；M5 依赖 M1/M2/M4；M6 可并行；M7 最后。

总估时约 14 个工作日，不含真机问题排查与 ST 真实卡兼容返工。

---

## 9. 门禁与验收

### G0 数据门禁

- [ ] v16→v17 迁移正常；v8/v14/v15 旧库升级不丢角色、世界书、会话。
- [ ] `from<2` / `from<15` 的 createTable 守卫存在，无 duplicate column。
- [ ] 删除角色级联删除版本；恢复版本不产生孤儿数据。

### G1 保真门禁

- [ ] V1/V2/V3 真实卡 fixture 导入：已知字段全部落位。
- [ ] 未知 `extensions` 与未知 data 字段导入→导出→再导入不丢。
- [ ] 世界书条目导入→导出后 `keys/content/position/depth/priority` 与未编辑扩展字段一致。
- [ ] PNG 导出后能被现有导入器重新解析出 V2/V3 数据。
- [ ] 导入结果卡片明确列出保留字段数与警告，不静默丢弃。

### G2 提示词门禁

- [ ] 空档案不产生任何额外 system 消息。
- [ ] 档案块按节拼接、空节跳过、超预算截断。
- [ ] 卡内系统提示 ≤2000 字符、历史后置指令 ≤1000 字符。
- [ ] `PromptUsage.usedTokens` 计入新分类；用量弹层显示正确。
- [ ] 原有 416 项测试不回退；新增测试覆盖新字段默认值。

### G3 人工门禁

- [ ] 保存、恢复版本、导出均有明确用户动作；无后台静默写入。
- [ ] 恢复版本、覆盖导入均二次确认。
- [ ] AI 改写仍只改输入框，保存才落库（现状不回退）。

### G4 质量门禁

- [ ] `flutter analyze --no-pub` 0 issue。
- [ ] 全量 `flutter test` 不低于 416 项，新增用例全过。
- [ ] 真机：导入 V3 卡 → 编辑档案 → 聊天验证档案生效 → 导出 PNG → 重新导入 → 字段一致。
- [ ] 真机：版本保存/恢复；四栏导航与资产页入口可用。

### G5 发布门禁

- [ ] 版本号 2.1.0+15；README、release notes、宣传页下载版本同步。
- [ ] APK 体积与启动时间无明显回退（目标 ≤ 82MB）。
- [ ] 旧用户升级路径实机验证（保留数据安装，`adb install -r`）。

---

## 10. 风险与对策

| 风险 | 对策 |
|---|---|
| 档案块导致上下文膨胀 | 12% 窗口上限、分节截断、用量弹层可见、单字段 8000 字符上限 |
| 卡内 `system_prompt` 与输出格式冲突 | 格式规范保持历史前最后一条；卡内提示加从属声明并限长 |
| ST V3 字段持续演进 | 只识别已知字段，其余全部原样保留；用真实卡做 fixture，不猜字段 |
| PNG `tEXt`/CRC 写错 | 独立纯函数 + 现有导入器反向解析测试；真机导出后用 ST/心语各读一次 |
| 版本快照占空间 | 每角色 20 条、文本快照、裁剪最旧；不复制立绘 |
| 迁移 duplicate column | 严格沿用 `from>=2` / `from>=15` 守卫；迁移测试覆盖多起点 |
| 导出丢失心语专有数据 | 导出前损失清单 + `extensions.xinyu` 可选写入 |
| 四栏改动影响现有测试 | 单独 M6 提交；先改导航与资产页，再跑全量 widget 测试 |

---

## 11. 后续版本（方向）

### 2.2

- AI 工坊深化：概念→完整档案、分字段多方案、角色诊断、AI 修改历史。
- 试聊工作台：不保存角色即可试聊、Prompt 完整预览、Token 分类明细、记忆/世界书命中调试。
- 角色库：标签筛选、搜索、收藏、最近编辑、批量导入导出。
- 心语完整角色包：档案 + 立绘 + 表情包 + 音色 + 桌宠绑定（不含会话记忆）。

### 2.3

- 世界书共享库与多角色多对多绑定。
- 记忆 3.0：关系事件、来源追踪、置信度、编辑与冲突检测。
- 统一资产库、多立绘/服装、角色-Live2D 绑定。

### 长期

- 多角色群聊深化（已有基础）、剧情/场景状态、角色分享（不做社区前先做本地导出）。

---

## 12. 实施清单

- [ ] 提交 v1.8–v2.0 未提交改动，建立 v2.1 回退点。
- [ ] v17 迁移 + 表 + 索引 + 迁移测试。
- [ ] `CharacterProfile` / `CharacterExtensions` 编解码与容错。
- [ ] 仓储：读写档案、保存前快照、20 条裁剪、恢复、级联删除。
- [ ] 导入：V1/V2/V3 映射、未知字段保留、世界书原文、导入结果。
- [ ] 提示词：档案块、卡内提示、后置指令、预算与用量。
- [ ] 导出：V2/V3 JSON、PNG tEXt、损失提示、分享。
- [ ] 编辑器三页签 + 多开场白 + 档案字段 + Token 估算。
- [ ] 版本历史页 + 恢复确认。
- [ ] 四栏导航 + 工坊首页 + 资产页。
- [ ] 全量测试、真机回归、版本号与发布物料。

---

## 13. 实施记录

### M1（2026-11-27）

- schema v17：`characters.profile_json/extensions_json`、`lore_entries.source_json`、`character_versions`（毫秒时间戳 + 索引）。
- 新增 `CharacterProfile`（8 分区、容错编解码、未知顶层键保留、`promptText`）、`CharacterExtensions`、`CharacterVersion`。
- 仓储：档案/扩展读写；保存前比对内容，变化才快照旧状态；每角色 20 条；手动版本、恢复、级联删除；坏快照拒绝恢复。
- 迁移守卫：`from>=2` / `from>=15`，避免 createTable 与 addColumn 撞列。
- 验证：`flutter analyze` 0；全量 **432 项**通过。

### M2（2026-11-27）

- 导入器识别 V1 扁平 / V2 / V3（`spec` 与 PNG `ccv3` 关键字双重判定）。
- 字段映射：`nickname/creator/character_version/creator_notes/tags/system_prompt/post_history_instructions` 进入 `CharacterProfile`；`extensions` 进入 `stExtensions`；未识别 data/root 字段进入 `unknownData/unknownRoot`。
- 世界书：条目原文写入 `source_json`，书籍级元数据（name/scan_depth 等）写入 `extensions.book_meta`；条目仍默认禁用。
- `importCard` 返回 `CharacterImportResult`（格式、世界书数、保留字段数、警告）；`importFromBytes` 保留为兼容入口。
- 导入 UI：结果底部卡片展示格式/角色/世界书/保留字段/警告，可跳转查看角色；来源文案区分 ST V1/V2/V3。
- 验证：`flutter analyze` 0；全量 **440 项**通过。

### M3（2026-11-27）

- 提示词顺序：人设 → 角色档案块 → 卡内系统提示 → 时间 → 场景 → 记忆/事实/跨会话/画像 → 示例 → 输出格式规范 → 历史 → 世界书 after → 历史后置指令。
- 档案块只注入 `basic/appearance/background/relationships/language/interaction`；`creator` 与 `runConfig` 不进入档案块。
- 档案块预算：窗口 12%，最少 300 / 最多 1200 token；超长截断。
- 卡内系统提示 ≤2000 字符、历史后置指令 ≤1000 字符，均保留尾部。
- `PromptUsage` 新增 `profileTokens` / `cardPromptTokens`，计入 `usedTokens`；用量弹层新增「角色档案」「卡内提示」两行（为 0 时不显示）。
- 验证：`flutter analyze` 0；全量 **446 项**通过（M2 后 440，新增 6）。

### M4（2026-11-27）

- 新增 `lib/core/utils/png_text.dart`：PNG tEXt 读写、CRC32、同名块替换、IEND 前插入。
- 新增 `lib/features/characters/data/character_card_exporter.dart`：V2/V3 JSON、PNG 角色卡、文件名清洗、非 PNG 立绘转 PNG、损失提示。
- 导出映射：核心字段 + creator/tags/system_prompt/post_history + alternate_greetings；`unknownData` 合并回 data、`unknownRoot` 合并回根；世界书按 `source_json` 合并当前值；书籍元数据保留。
- `extensions.xinyu`（可选）携带完整 `profile`；导入器回读并合并，ST 标准字段覆盖非空值，保证导出→再导入不丢档案。
- 导出 UI：编辑页「导出角色卡」菜单（V2/V3/PNG）+ 损失提示 + 「写入心语扩展」开关 + 分享。
- 验证：`flutter analyze` 0；全量 **461 项**通过（M3 后 446，新增 15）。

### M5（2026-11-27）

- 编辑页改为「基础 / 档案 / 高级」三页签：基础含立绘、核心字段、多开场白、标签；档案含外貌/背景/关系/语言/互动 5 个分区；高级含创作者信息、卡内提示、档案用量、第三方扩展、版本历史、导出入口。
- 档案字段 36 个输入框按 `分区.字段` 索引管理；保存时组装 `CharacterProfile` 并保留未知 `extra` 键。
- 备用开场白可增删改；标签可增删；档案 Token / 字符用量随输入实时更新。
- 新增 [character_version_page.dart](lib/features/characters/presentation/character_version_page.dart)：版本列表、变更摘要、快照查看、恢复、删除。
- 离开页面前有未保存改动会二次确认（PopScope）；版本恢复后编辑页自动重载。
- 验证：`flutter analyze` 0；全量 **465 项**通过（M4 后 461，新增 4）。

### M6（2026-11-27）

- 底部导航改为「聊天 / 工坊 / 资产 / 设置」；聊天页标题改为「聊天」。
- 角色列表页升级为工坊首页：顶部「AI 创作角色」卡片 + 「我的角色」列表 + 导入/新建入口。
- 新增 `lib/features/assets/presentation/assets_page.dart`：桌宠模型、角色立绘、表情包、音色四个入口；立绘/表情包先选角色再进子页；桌宠从底栏移入资产页。
- 新增 `CharacterRepository.listCharacters()` 一次性查询，避免 UI 在 widget 测试的 FakeAsync 下等待 drift watch 首帧挂死。
- 验证：`flutter analyze` 0；全量 **466 项**通过（M5 后 465，新增 1）。

### M7（2026-11-27）

- 版本号 `2.1.0+15`；数据库 schema v17。
- README 中英文、`docs/release-v2.1.md` 更新到 v2.1。
- `flutter analyze` 0；全量 **466 项**通过。
- `flutter build apk --release` 成功：`app-release.apk` **78.7 MB**（82,566,727 bytes）。
- 构建中遇到 Windows 文件锁（`app_icon_web.png` 无法删除），用 `flutter clean` 后重建解决；注意 `flutter clean` 会清空 `build/` 下的辅助文件。
- 真机验收待执行：构建时 `adb devices` 无连接设备；站点/Release 发布未执行。
