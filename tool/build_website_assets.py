"""Generate promo-site image assets from the app branding sources."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "website" / "assets" / "img"
OUT.mkdir(parents=True, exist_ok=True)

ICON = ROOT / "assets" / "branding" / "app_icon.png"
LOGO = ROOT / "assets" / "branding" / "sigborn_logo.png"

FONT_DIR = Path("C:/Windows/Fonts")


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_DIR / name), size)


def rounded(img: Image.Image, radius_ratio: float = 0.22) -> Image.Image:
    img = img.convert("RGBA")
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    radius = int(min(img.size) * radius_ratio)
    draw.rounded_rectangle((0, 0, img.size[0] - 1, img.size[1] - 1), radius, fill=255)
    img.putalpha(mask)
    return img


def save(img: Image.Image, name: str) -> None:
    path = OUT / name
    img.save(path, optimize=True)
    print(f"{name}: {img.size[0]}x{img.size[1]} {path.stat().st_size / 1024:.0f} KB")


icon = Image.open(ICON).convert("RGBA")
for size in (512, 192, 180, 64):
    target = icon.resize((size, size), Image.LANCZOS)
    if size >= 192:
        target = rounded(target, 0.22)
    save(target, "icon-512.png" if size == 512 else f"icon-{size}.png")

# Studio logo for the footer (页面只显示 52px，按 3x 存 156²).
logo = Image.open(LOGO).convert("RGBA")
logo.thumbnail((156, 156), Image.LANCZOS)
save(logo, "studio-logo.png")

# Open Graph / social card.
W, H = 1200, 630
card = Image.new("RGB", (W, H), (7, 6, 15))
px = card.load()
for y in range(H):
    for x in range(0, W, 1):
        t = (x / W) * 0.55 + (y / H) * 0.45
        r = int(13 + 26 * t)
        g = int(11 + 14 * t)
        b = int(30 + 46 * t)
        px[x, y] = (r, g, b)

glow = Image.new("RGB", (W, H), (0, 0, 0))
gdraw = ImageDraw.Draw(glow)
gdraw.ellipse((-260, -220, 620, 660), fill=(96, 74, 220))
gdraw.ellipse((720, 220, 1500, 940), fill=(26, 130, 190))
glow = glow.filter(ImageFilter.GaussianBlur(180))
card = Image.blend(card, glow, 0.62)

draw = ImageDraw.Draw(card, "RGBA")

# Fine grid.
for x in range(0, W, 48):
    draw.line((x, 0, x, H), fill=(255, 255, 255, 7))
for y in range(0, H, 48):
    draw.line((0, y, W, y), fill=(255, 255, 255, 7))

badge_icon = rounded(icon.resize((252, 252), Image.LANCZOS), 0.22)
halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
halo_draw = ImageDraw.Draw(halo)
halo_draw.rounded_rectangle((78, 178, 350, 450), 62, fill=(142, 124, 255, 90))
halo = halo.filter(ImageFilter.GaussianBlur(46))
card = Image.alpha_composite(card.convert("RGBA"), halo)
card.paste(badge_icon, (106, 206), badge_icon)
draw = ImageDraw.Draw(card, "RGBA")
draw.rounded_rectangle((106, 206, 358, 458), 56, outline=(255, 255, 255, 40), width=2)

title_font = font("msyhbd.ttc", 104)
sub_font = font("msyh.ttc", 34)
en_font = font("segoeuib.ttf", 30)
chip_font = font("msyh.ttc", 25)

draw.text((410, 170), "心语", font=title_font, fill=(244, 242, 255))
draw.text((412, 300), "让每一次对话，都怦然心动", font=sub_font, fill=(180, 172, 220))
draw.text((412, 356), "ineermost_words", font=en_font, fill=(142, 124, 255))

chips = ["AI 角色扮演", "Live2D 桌宠", "双向语音", "开源免费"]
x = 412
for label in chips:
    tw = draw.textlength(label, font=chip_font)
    w = int(tw) + 44
    draw.rounded_rectangle((x, 430, x + w, 480), 25, fill=(255, 255, 255, 14),
                           outline=(255, 255, 255, 34), width=1)
    draw.text((x + 22, 440), label, font=chip_font, fill=(226, 220, 250))
    x += w + 14

draw.text((412, 536), "奇点重现工作室 · sigborn.xyz", font=chip_font, fill=(150, 142, 190))

card.convert("RGB").save(OUT / "og.png", quality=90, optimize=True)
print(f"og.png: {W}x{H} {(OUT / 'og.png').stat().st_size / 1024:.0f} KB")
