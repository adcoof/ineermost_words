# v1.5 Agent 权限扩展方案

状态：已完成（2026-11-24，真机验证通过；397 项测试）
用户需求（m02170）：「给agent得权限大一些，就像在电脑上得权限一样」
用户选择（m02176）：授权文件夹（SAF）；删除/移动/重命名、shell、HTTP；安全策略「像 DSH 一样：每步确认、自动审查、全自动」。

## 1. 权限模型

### 1.1 三种审批模式
| 模式 | 读/列目录 | 写文件 | 删除/移动/重命名 | shell | HTTP |
|---|---|---|---|---|---|
| 每步确认 `ask` | 确认 | 确认 | 确认 | 确认 | 确认 |
| 自动审查 `auto` | 自动 | 自动（根内、≤64k、非链接） | 确认 | 确认 | 确认 |
| 全自动 `full` | 自动 | 自动 | 自动 | 自动 | 自动 |

- 设置键 `agent_approval_mode`，默认 `ask`；旧 `agent_auto_write=true` 在 `ask` 下仅对写文件生效（兼容）。
- 全自动仍保留硬边界：只能访问工作区/已授权 SAF 根；shell 禁 `su`；HTTP 禁 localhost/私网/非 80/443 端口（可配置）；所有工具输出截断。

### 1.2 风险分级
`AgentToolRisk { read, write, destructive, shell, network }`
- read：list_roots/list_files/read_file
- write：write_file
- destructive：delete_file/move_file/rename
- shell：run_command
- network：http_request

确认卡统一为 `AgentPendingAction{tool, title, detail, risk}`；拒绝时回填 `{"ok":false,"error":"用户拒绝执行"}`。

## 2. 文件根
- `工作区`：`getApplicationSupportDirectory()/agent_workspace`（现有 AgentWorkspace）。
- SAF 授权根：用户通过系统目录选择器添加，存 settings KV `agent_granted_folders`（JSON `[{uri,name}]`），持久化 `takePersistableUriPermission`。
- 工具参数：`root`（缺省「工作区」）+ `path`（相对路径）。
- `list_roots` 返回 `[{name,kind:"workspace"|"saf",uri?}]`。
- SAF 能力：list/read/write/delete/rename/move（同根内 copy+delete）；路径逐段解析，禁止 `..`/绝对路径。
- 根名冲突时显示 `name (2)`。

## 3. 新工具
- `list_roots`：无参数。
- `delete_file(root, path)`。
- `move_file(root, from, to)`（同根；覆盖前确认）。
- `rename(root, path, new_name)`。
- `run_command(command, timeout_ms?)`：`/system/bin/sh -c`，cwd=工作区，超时 15s，stdout/stderr 各截 8000 字符，禁 `su`。
- `http_request(url, method=GET, headers?, body?)`：Dio，仅 http/https，禁 localhost/私网/链路本地，超时 20s，响应截 256KB；返回 status/headers/body。

## 4. 原生 SAF 通道
`MainActivity.kt`（当前空 FlutterActivity）新增 `MethodChannel("xinyu/saf")`：
- `pickDirectory` → ActivityResultContracts.OpenDocumentTree，takePersistableUriPermission，返回 `{uri,name}`。
- `list(uri, path)` → `{entries:[{name,isDir,size,modified}]}`。
- `read(uri, path, maxBytes)` → bytes（Dart 侧 UTF-8 解码/分页）。
- `write(uri, path, content)` → 逐段建目录，存在则 truncate 写，否则 createDocument。
- `delete(uri, path)`、`rename(uri, path, newName)`、`move(uri, from, to)`。
所有 I/O 在后台线程，异常回 `error(code,message)`。

## 5. UI
- 设置 → Agent 权限：
  - 模式单选（每步确认/自动审查/全自动，带风险说明）。
  - 授权文件夹列表：添加（SAF 选择器）、移除；显示根名。
  - 提示：全自动风险自负；shell/HTTP 默认仍需确认。
- Agent 对话页确认卡：标题按工具类型、详情（路径/命令/URL/大小/预览）、拒绝/允许。
- 系统提示更新：说明可用根、工具、审批模式。

## 6. 测试
- 审批矩阵：三模式 × 五风险，确认/自动/拒绝。
- 工具：delete/move/rename 路径安全、shell 超时与截断、HTTP 私网拒绝。
- SAF 网关 fake：root 解析、路径穿越拒绝、写覆盖。
- 设置：mode 缺省/持久化、授权列表增删。
- 真机：SAF 选 Download 子目录、list/read/write/delete；shell `ls`；HTTP 请求 example.com；三模式各验一次。

## 7. 里程碑
1. 设置 + 审批模型（0.5d）
2. 工具层（delete/move/rename/shell/http + 根抽象）（1d）
3. 原生 SAF + Dart 网关（1d）
4. 控制器/UI（1d）
5. 测试与真机（0.5d）

## 8. 完成记录（2026-11-24）

- 实现：9 个工具（list_roots/list_files/read_file/write_file/delete_file/move_file/rename/run_command/http_request）；三种审批模式；SAF 原生 MethodChannel；设置页「Agent 权限」；通用确认卡；系统提示说明可用根与风险。
- 真机（MuMu / Android 15）：
  - 授权 `Download/agent_test`，`list_roots` 返回「工作区」+「agent_test」；`list_files`、`write_file`、`read_file` 正常。
  - `rename test.txt → note.txt` 成功；`delete_file` 成功；`run_command echo` 返回 exit 0；`http_request https://example.com` 返回 200。
  - 自动审查：删除/shell/HTTP 均弹确认；全自动：shell 直接执行、无确认。
- 修复：
  - `contentResolver.getType(source)` 对 SAF 文件误判为目录，导致 move 走 `copyDirectory` 递归 `note.txt/note.txt/...`，并把 `/sdcard` 访问卡死。改为 query `Document.COLUMN_MIME_TYPE`；`write` 拒绝同名目录。
  - move 优先 `DocumentsContract.moveDocument`，同目录用 `renameDocument`；`copyDirectory` 加 32 层深度上限。
  - Agent 空态文案改为「工作区与授权文件夹」。
- 验证：`flutter analyze` 无问题；`flutter test` 397 项全过。
- 遗留：v1.4 的 M1 mock 四场景仍属可选验收；SAF 根被系统/用户移除时需重新授权（已有错误提示）。

## 9. v1.6 增量（2026-11-24）

- 会话级权限：`agent_sessions` 增 `approvalMode`、`grantedFoldersJson`（schema v11，`from >= 10` 守卫）；Agent 会话右上角盾牌可单独覆盖审批模式与授权文件夹，设置页保留为「新会话默认」。
- Agent 上下文：`agent_context_window_tokens`（默认 4096，1024–32768），`AgentUsage` + 会话标题栏 chip + 用量弹层；工具步数 `agent_max_steps`（1–12）可在设置页与权限 sheet 调整。
- 联网搜索：新增 `web_search`（Bing RSS → Bing HTML → DDG HTML 回退，IPv4 连接、20s/30s 超时）；国内网络对 DDG/Bing 仍可能超时，失败会如实回退到 `http_request`。
- 导出到下载：新增原生 `xinyu/files` 的 `saveToDownloads`（Android 10+ MediaStore，`Download/心语Agent`；<10 公共目录 + WRITE_EXTERNAL_STORAGE maxSdk 28），工作区文件行加「保存到下载」。
- 版本：`1.6.0+10`；`flutter analyze` 0；`flutter test` 406 项全过；release APK 79.4MB 安装后验证设置 sheet 与下载导出。
- 未完成：安卓「操作手机」需要用户选择授权路线（Shizuku / 无障碍 / 全文件 / root），详见对话。

## 10. v1.6.1 手机控制（Shizuku + 无障碍，2026-11-24）

用户选择「Shizuku + 无障碍」；普通 App 无真正绕过，只能用户显式授权。

- 原生：
  - `MainActivity` 新增 `xinyu/device` 通道：`status`（Shizuku 可用/已授权、无障碍是否连接）、`requestShizuku`（`Shizuku.requestPermission(2001)`）、`shell`（Shizuku 身份执行 `sh -c`，20s 超时、stdout/stderr 截 8000）、`uiText`/`clickText`（无障碍）、`openAccessibilitySettings`。
  - Shizuku API 13 的 `Shizuku.newProcess` 为 private → 用反射调用（失败提示「Shizuku shell 不可用」）。
  - `XinyuAccessibilityService`：`screenText()` 去重最多 200 行；`clickText()` 精确/包含匹配后向上找可点击父节点；深度上限 40。
  - Manifest：`moe.shizuku.manager.permission.API_V23`、`ShizukuProvider`（`${applicationId}.shizuku`）、无障碍服务与 `res/xml/xinyu_accessibility.xml`。
- Dart：
  - `DeviceGateway`（`lib/features/agent/data/device_gateway.dart`）+ `deviceGatewayProvider`。
  - 新增工具 `device_status`、`device_shell`、`device_click_text`、`device_ui_text`（共 14 个工具）；风险：read/read/shell/destructive。
  - 控制器系统提示加入手机操作规则（禁 su/reboot/清数据）。
  - 设置页「Agent 默认权限」sheet 增「手机控制」：Shizuku 状态/授权按钮、无障碍状态/去开启。
- 验证（2026-11-24，MuMu Android 15）：
  - 无障碍开启后 `device_status` 返回 `accessibilityEnabled=true`；`device_ui_text` 成功读出当前屏幕文本；`device_click_text` 点击「上下文」返回 `{"ok":true}` 并触发对应 UI。
  - Shizuku 未安装/未运行，`device_shell` 未做真机验证；单元测试用 fake gateway 覆盖已授权/未授权/无障碍关闭矩阵。
- 测试：`flutter analyze` 0；`flutter test` **411 项全过**；release APK 构建并安装成功（79.4MB）。
- 后续（可选）：在真机安装 Shizuku 后验证 `input/am/screencap`；无障碍点击后增加界面变化确认，避免模型重复点击。

## 11. v1.6.1 补丁：web_search 可用 + convert_file（2026-11-24）

- `web_search` 多源顺序改为 **360 移动 → 百度 → Bing RSS → Bing HTML → DuckDuckGo**；新增 `_parseSoResults`（解 `m.so.com/jump?u=`、`data-mdurl`）、`_parseBaiduResults`。
- 根因：`_fetchWeb` 注入的 **IPv4 `IOHttpClientAdapter`** 会让 360 返回 HTTP 400；移除 adapter 后真机 `{"ok":true,"source":"360","count":5}`。Bing/DDG 在模拟器仍被 reset/超时，仅作回退。
- 文件转换：`pubspec.yaml` 增 `markdown ^7.3.0`、`pdf ^3.11.1`（`archive`/`image` 已有）；新增工具 `convert_file`（md→html、csv→json、json→csv、html→txt），工具总数 15。PDF 仅装依赖，尚未接二进制写入。
- 验证：`flutter analyze` 0；`flutter test` **416 项全过**；release APK 安装后真机 `note.md → note.html` 成功（`<h1>Hello</h1>` + 两条 `<li>`），`web_search` 成功（360，5 条）。
- 事故记录：`Set-Content -Encoding utf8` 两次改坏源码/测试（`agent_controller.dart`、`agent_tool_executor_test.dart`），均从 Dart kernel（`app.dill` / `test_cache/*.dill.track.dill`）提取嵌入源码恢复；后续一律用 `edit`。

## 12. 上下文压缩改进（2026-11-24）

- `_historyLimit`：历史预算 = `窗口 × 90% - 系统提示 - 工具定义`，下限 160 token，避免 system+tools 把窗口挤爆。
- `_buildHistory` 返回 `(messages, summary)`；每轮工具循环开始前重新 `_trimToBudget`，多步工具结果不会累积超窗。
- 被裁掉的旧消息生成 ≤800 字机械摘要（不额外调模型），以 `【更早对话摘要（自动压缩，仅保留要点）】` 追加到 system；摘要后再按新预算二次裁剪。
- `_clip` 改为「头 60% + 尾 40%」，长工具结果保留结尾结论。
- 验证：`flutter analyze` 0；`flutter test` **417 项全过**（新增「历史预算扣除系统提示与工具定义」用例，断言摘要出现且 used ≤ 90% 窗口）。

## 13. 会话打开滚动 + 图片转 PNG（2026-11-24）

- 会话滚动：`agent_chat_page.dart` 的 `ListView.builder` 改为 `reverse: true`，`itemBuilder` 用 `messages.length - 1 - index`；`_scrollToBottom()` 改为 `animateTo(0)`。reverse 列表初始 offset 0 即最新，避免首次 post-frame 时 `maxScrollExtent == 0` 导致停在顶部。
- 图片转 PNG：
  - `AgentFileRoot` 新增 `readBytes/writeBytes`；`AgentWorkspace` 新增 `readEntryBytes`（≤10MB）/`writeEntryBytes`（≤10MB）；`WorkspaceRoot`、`SafRoot` 实现委托。
  - `SafGateway` 新增 `writeBytes`；`MethodChannelSafGateway` 调 `xinyu/saf` 的 `writeBytes`。
  - Kotlin `MainActivity` 新增 `writeBytes` 通道；`write` 改为复用 `writeBytesInternal`，按扩展名映射 MIME（png/jpg/webp/gif/bmp/pdf 等），上限 10MB。
  - `convert_file` 支持 `format: png`：jpg/jpeg/webp/gif/bmp → `image.decodeImage` + `encodePng`，输出同目录 `.png`；源已是 png 时报错。
- 验证：`flutter analyze` 0；`flutter test` **418 项全过**（新增「图片转 PNG」用例）；真机打开长会话直接停在最新消息；真机 `test.jpg`（64×48）→ `test.png`（64×48 RGB）成功。



