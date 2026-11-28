# 心语 · 宣传海报

三比四竖版 + 一比一方版，从 HTML/CSS 渲染成图，改字改色都只需要编辑这两个文件再重新截图。

## 文件

| 文件 | 尺寸 | 用途 |
| --- | --- | --- |
| `out/xinyu-poster-vertical-1080.jpg` | 1080×1440 | 微信/QQ 聊天、朋友圈竖图 |
| `out/xinyu-poster-vertical-2160.jpg` | 2160×2880 | 印刷 / 高清投屏（约 180dpi） |
| `out/xinyu-poster-square-1080.jpg` | 1080×1080 | 朋友圈九宫格、QQ 空间封面 |
| `out/xinyu-poster-square-2160.jpg` | 2160×2160 | 高清方图 |
| `out/poster-1080.png` `out/poster-2160.png` | 同上 | 无损 PNG 母版 |

## 源文件

- `index.html`：三比四竖版（1080×1440）
- `square.html`：一比一方版（1080×1080）
- `assets/qr.png`：指向 `https://ineermostwords.sigborn.xyz/` 的二维码（`qrcode` 生成，容错级别 M，边距 2）

图标、配色、文案与官网 `website/` 共用同一套：颜色 `#8E7CFF` / `#4DC9FF`，英文名 `INEERMOST_WORDS`（网站导航里显示为大写，实际名 `ineermost_words`）。

## 重新出图

```powershell
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
# 竖版：2 倍截屏得到 2160×2880
& $edge --headless=new --disable-gpu --hide-scrollbars `
  --window-size=1080,1440 --force-device-scale-factor=2 `
  --virtual-time-budget=6000 `
  --screenshot="D:\AI_Chat_Project\poster\out\poster-2160.png" `
  "file:///D:/AI_Chat_Project/poster/index.html"
```

方版把 `--window-size` 换成 `1080,1080`、输出换成 `square-2160.png`、地址换成 `square.html`。

> 注意：直接 `&` 调用 msedge 不会等它退出，PowerShell 里建议用
> `Start-Process -FilePath $edge -ArgumentList @(...) -Wait -NoNewWindow`，
> 否则截图文件可能还没写完就被读取。

## 换二维码

```powershell
python -m pip install qrcode
python -c "import qrcode; qr=qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=12, border=2); qr.add_data('https://ineermostwords.sigborn.xyz/'); qr.make(fit=True); qr.make_image(fill_color=(16,12,30), back_color=(255,255,255)).save(r'poster/assets/qr.png')"
```

深色模块 + 白底，扫码兼容性最稳；不要做成浅色模块深色底。
