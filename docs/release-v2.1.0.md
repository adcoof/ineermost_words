# 心语 v2.1.0

> 2026-11-27 · `2.1.0+15` · schema v17 · 471 项测试通过

## 下载

- 安装包：`app-release.apk`
- 大小：78.8 MB（82,582,859 bytes）
- SHA-256：`0E64F7E9AC008D66BB310D70FB8CA41833779EF05A72C376B5EB1610A6B6EEDA`
- 要求：Android 7.0（API 24）及以上；覆盖安装即可保留数据

## 亮点

### 完整角色档案

- 基础身份、外貌、背景、关系、语言风格、互动方式、创作者信息、卡内系统提示。
- 编辑页「基础 / 档案 / 高级」三页签；核心字段保留 AI 改写。
- 档案按窗口 12%（300–1200 token）注入；创作者信息不进提示词。

### 角色卡导入导出

- 导入 SillyTavern V1/V2/V3 JSON 与 PNG；映射 nickname / creator / tags / system_prompt / post_history_instructions / character_book。
- 未知 data/根字段与第三方 extensions 原样保留；世界书随卡往返。
- 导出 V2/V3 JSON 或 PNG 角色卡；默认写入 `extensions.xinyu` 承载完整档案，导回心语不丢字段。
- 导出前展示心语专有数据损失清单。

### 版本与编辑器

- 保存时自动快照旧状态，每角色最多 20 条；可查看差异、恢复、删除。
- 多开场白可增删改；标签管理；档案 token 与卡内提示字符用量；离开前未保存确认。

### 导航与资产

- 底部导航：聊天 / 工坊 / 资产 / 设置。
- 工坊首页：AI 创作角色 + 我的角色列表。
- 资产页聚合桌宠、立绘、表情包、音色。

### 体验修复

- 360dp 窄屏：顶栏动作收进更多菜单，上下文 chip 常驻；桌宠按屏宽缩放；标题优先显示角色名。
- 打开会话即预计算上下文用量，不再等到首次发送。
- 聊天 / TTS / ASR 可分别选择 API 供应商；聊天用 DeepSeek 时，TTS/ASR 仍可指向 MiMo。
- 私聊/群聊消息气泡显示角色与用户头像；群聊按当前发言者取头像。

## 升级说明

- 建议 `adb install -r` 覆盖安装，不要卸载，避免清空本地数据。
- 数据库从 v16 升级到 v17：只新增列与表，不重建旧表。
- 旧角色升级后档案为空；原有 6 个字段、立绘、记忆、世界书保持不变。
- v1.8 起通用 Agent 已移除；v2.1 不再包含 Agent、Shizuku、无障碍或文件/命令工具。

## 已知限制

- 群聊仍是每轮一位角色轮转；暂无成员面板、静音、Force Talk、Natural/Pooled 策略与多角色连发（已列入后续计划）。
- 用户头像当前为通用占位，尚未支持 Persona 自定义头像。
- 档案字段暂无 AI 改写、诊断与多方案生成。
- 世界书仍是角色内条目，尚无共享库/多角色多对多绑定。
- 真实 V3 卡导入 → PNG 导出 → 再导入、第三方 SillyTavern 阅读器兼容性尚未逐项真机验收。

## 链接

- 宣传页：https://ineermostwords.sigborn.xyz/
- GitHub Releases：https://github.com/adcoof/ineermost_words/releases
- Gitee 镜像：https://gitee.com/phantexdream/ineermost_words/releases
