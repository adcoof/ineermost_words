# 心语 · 宣传页

`website/` 是一个零依赖的静态单页，直接双击 `index.html` 就能看。发布时整目录上传即可，不需要构建。

## 目录

```
website/
├─ index.html               # 全部内容：文案、图标 symbol、各区块
├─ assets/
│  ├─ css/style.css         # 设计系统 + 五套主题 + 响应式
│  ├─ js/main.js            # 主题切换、移动菜单、滚动入场、安卓下载提示
│  └─ img/
│     ├─ icon-512.png       # 图标（也用作 og:image 的主视觉来源）
│     ├─ icon-192/180/64.png
│     ├─ studio-logo.png    # 奇点重现工作室 logo（页脚，156²）
│     └─ og.png             # 社交分享封面 1200×630
└─ README.md
```

## 本地预览

```bash
cd website
python -m http.server 8000
# 打开 http://localhost:8000
```

直接 `file://` 打开也可以，页面没有任何网络请求（字体用系统字体），唯一的外链是下载地址。

## 上线

### GitHub Pages（已配好工作流）

`.github/workflows/pages.yml` 会在 `website/` 有改动并推到 `master` 后自动发布。

首次启用：

1. 仓库 **Settings → Pages → Build and deployment → Source** 选 **GitHub Actions**；
2. 推一次 `website/` 的改动，或到 **Actions** 手动跑「发布宣传页」；
3. 站点地址：`https://adcoof.github.io/ineermost_words/`。

> `index.html` 里的 `canonical`、`og:url` 目前按上面的地址写死，换域名或换部署位置时记得一起改。

#### 排错：workflow 报 `Get Pages site failed`

说明仓库还没启用 Pages。到 **Settings → Pages → Source** 选 **GitHub Actions** 保存，然后二选一重跑：

- **Actions → 发布宣传页 → Run workflow**（右上角按钮）；
- 或者再推一次 `website/` 的改动，workflow 会重新触发。


### Gitee Pages（国内镜像）

Gitee Pages 只部署仓库某个分支的**根目录**，所以要先把 `website/` 推成一个分支：

```bash
git push origin $(git subtree split --prefix website):refs/heads/pages --force
```

然后在 Gitee 仓库 **服务 → Gitee Pages**：

1. 部署分支选 `pages`，部署目录留空；
2. 勾选「强制使用 HTTPS」，点「启动」；
3. 以后每次更新内容，重跑上面的 push 命令，再回页面点一次「更新」。

> Gitee 免费版 Pages 每次都要手动点更新，且首次启动会要求实名认证。

### 自建服务器 / 其它托管

把 `website/` 里的文件整个丢到任意静态托管（Nginx、Cloudflare Pages、Vercel、OSS/COS）即可，`index.html` 在根目录。

## 版本号与下载链接

页面里 v1.3.5 与 APK 直链出现在以下位置，发新版时全局替换即可：

- `index.html` 顶部：`<title>`、`description`、`og:*`、`canonical`
- hero 主按钮：`releases/download/v1.3.5/app-release.apk`（GitHub）与同路径的 Gitee
- hero 徽标：`约 75 MB`（APK 大小变了记得改）
- `#download`：两张源卡片的版本徽标、`发行版说明`、`查看源码`
- `#changelog`：标题、日期、条目、`全部版本`
- 结尾 CTA：`v1.3.5 · 约 75 MB · Android 7.0+`

下载地址模板：

```
https://github.com/adcoof/ineermost_words/releases/download/vX.Y.Z/app-release.apk
https://gitee.com/phantexdream/ineermost_words/releases/download/vX.Y.Z/app-release.apk
```

## 图标 / 分享图重新生成

素材脚本在仓库根目录：`tool/build_website_assets.py`（Pillow）。

```bash
python tool/build_website_assets.py   # 读 assets/branding/，写 website/assets/img/
```

## 设计备注

- 默认深空紫，`:root` 里是全部色板变量；`data-theme="sakura|azure|mint|daylight"` 覆盖整套配色，切主题时整页（含背景光斑、气泡、按钮）一起变。
- 页面里没有产品截图：手机预览、聊天气泡都是纯 HTML/CSS 画的示意图，避免用旧版本截图误导。真要放截图，在 `#themes` 预览区把 `.phone` 换成 `<img>` 即可。
- 图标集是 `index.html` 顶部的内联 `<symbol>`，新增图标记得在 `#i-xxx` 里加 `<symbol>`，否则 `<use>` 会空白。
