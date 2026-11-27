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
│     ├─ icon-512.png       # 圆形图标（裁掉原图白边，不重画边缘）
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

正式地址：**https://ineermostwords.sigborn.xyz/**（自建服务器，HTTPS）
镜像地址：**https://adcoof.github.io/ineermost_words/**（GitHub Pages，每次推 `website/` 自动更新）

`index.html` 里的 `canonical`、`og:url`、`og:image` 都写死为正式域名；换域名或换部署位置时记得一起改。

### GitHub Pages（已配好工作流）

`.github/workflows/pages.yml` 会在 `website/` 有改动并推到 `master` 后自动发布。

首次启用：

1. 仓库 **Settings → Pages → Build and deployment → Source** 选 **GitHub Actions**；
2. 推一次 `website/` 的改动，或到 **Actions** 手动跑「发布宣传页」；
3. 站点地址：`https://adcoof.github.io/ineermost_words/`。

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

### 自建服务器（当前正式站点）

腾讯云 OpenCloudOS + 宝塔面板，nginx 1.30.4，Let's Encrypt 证书。

| 项目 | 位置 |
| --- | --- |
| 站点目录 | `/var/www/ineermostwords`（即 `website/` 的内容） |
| nginx 配置 | `/www/server/panel/vhost/nginx/ineermostwords.conf`（仓库内副本：`tool/deploy/ineermostwords.conf`） |
| 证书 | `/etc/letsencrypt/live/ineermostwords.sigborn.xyz/`，同步到 `/www/server/panel/vhost/ssl/ineermostwords.sigborn.xyz/` |
| 续期同步脚本 | `/etc/letsencrypt/renewal-hooks/deploy/ineermostwords-sync.sh` |

更新内容：

```bash
tar -C website -czf /tmp/site.tgz .
scp /tmp/site.tgz root@111.231.7.158:/tmp/site.tgz
ssh root@111.231.7.158 'rm -rf /var/www/ineermostwords/* && tar -xzf /tmp/site.tgz -C /var/www/ineermostwords && chown -R www:www /var/www/ineermostwords'
```

替换 `index.html` 或 CSS 后浏览器刷新即可（静态文件 30 天缓存，`index.html` 不缓存）。

首次给新域名签证书：

```bash
certbot certonly --webroot -w /var/www/ineermostwords -d ineermostwords.sigborn.xyz \
  --non-interactive --agree-tos --keep-until-expiring
```

然后把 `fullchain.pem` / `privkey.pem` 复制到 `/www/server/panel/vhost/ssl/<domain>/`，`nginx -t && systemctl reload nginx`。

> 坑：Windows 的 `ssh` 会把 heredoc 里的双引号剥掉，`$uri` 之类的变量也会被本地丢掉。改服务器配置请把文件先写成本地文件再 `scp`，别用 `ssh ... <<EOF`。

## 版本号与下载链接

当前版本 **v2.1.0**（约 79 MB）。页面里所有下载按钮都指向站内 `/dl/github`、`/dl/gitee`，由服务器 nginx 302 到对应仓库的 release 直链；页面本身不写带版本号的 APK 直链。发新版时改以下位置：

- **服务器 nginx**：`/dl/github` 与 `/dl/gitee` 的 302 目标 tag（仓库副本：`tool/deploy/ineermostwords.conf`）。这一步不改，页面显示新版但下载到的还是旧包。
- `index.html`：全局替换版本号 `v2.1.0` / `2.1.0`，共出现在 hero 主按钮、`#download` 小标题与两张源卡片徽标、`#changelog` 标题、结尾 CTA。
- `index.html` hero 徽标、两张源卡片、结尾 CTA、FAQ「我的手机能用吗」里的 `约 79 MB`（APK 大小变了记得改）。
- `index.html` `#changelog`：日期、条目、测试数。
- `<title>`、`description`、`og:*` 只在卖点变化时才需要动，不含版本号。

下载地址模板：

```
https://github.com/adcoof/ineermost_words/releases/download/vX.Y.Z/app-release.apk
https://gitee.com/phantexdream/ineermost_words/releases/download/vX.Y.Z/app-release.apk
```

发版顺序：先在 GitHub / Gitee 都发布好 release 并确认两边 APK 都能下载 → 改 nginx 跳转并 `nginx -t && systemctl reload nginx` → 再推 `website/`，避免页面先显示新版而包还没传完。

## 图标 / 分享图重新生成

素材脚本在仓库根目录：`tool/build_website_assets.py`（Pillow）。

```bash
python tool/build_website_assets.py   # 读 assets/branding/，写 website/assets/img/
```

图标源图是 `assets/branding/app_icon_web.png`（1254²，圆形 logo 居中、四周约 68px 白边）。脚本只做「裁掉白边 + 按等比缩放」，不重新画圆角、不做二次蒙版，避免边缘出现锯齿。换图标时替换这张源图即可。

## 设计备注

- 默认深空紫，`:root` 里是全部色板变量；`data-theme="sakura|azure|mint|daylight"` 覆盖整套配色，切主题时整页（含背景光斑、气泡、按钮）一起变。
- 页面里没有产品截图：手机预览、聊天气泡都是纯 HTML/CSS 画的示意图，避免用旧版本截图误导。真要放截图，在 `#themes` 预览区把 `.phone` 换成 `<img>` 即可。
- 图标集是 `index.html` 顶部的内联 `<symbol>`，新增图标记得在 `#i-xxx` 里加 `<symbol>`，否则 `<use>` 会空白。
