#!/usr/bin/env python3
"""
Gera a identidade visual do BrowserNro: icone NRO (JPEG 256x256, exigido pelo
nacptool do libnx) e um logotipo maior para documentacao/splash screen.

Conceito: um globo/rede estilizada (navegacao na internet) atras de uma janela
de navegador minimalista, em paleta propria (azul-marinho + ciano + laranja),
sem reproduzir cores, formas ou simbolos de navegadores existentes (Chrome,
Firefox, Edge, Safari) nem logotipos da Nintendo.
"""
import math
from PIL import Image, ImageDraw

W = 512  # master size; icon.jpg is downsampled to 256x256 for the NRO

BG_TOP = (10, 18, 32)       # navy
BG_BOTTOM = (18, 34, 56)
CYAN = (56, 217, 215)
CYAN_DIM = (34, 130, 132)
ORANGE = (255, 149, 64)
WHITE = (236, 244, 248)

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def make_base():
    img = Image.new("RGB", (W, W), BG_TOP)
    d = ImageDraw.Draw(img)
    for y in range(W):
        t = y / (W - 1)
        d.line([(0, y), (W, y)], fill=lerp(BG_TOP, BG_BOTTOM, t))
    return img, d

def draw_globe(d, cx, cy, r):
    # Outer ring
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=CYAN, width=6)
    # Latitude lines (ellipses getting thinner towards the poles)
    for frac in (0.35, 0.68):
        rw = r
        rh = r * frac
        d.ellipse([cx - rw, cy - rh, cx + rw, cy + rh], outline=CYAN_DIM, width=3)
    # Longitude lines (vertical-ish ellipses)
    for frac in (0.35, 0.68, 1.0):
        rw = r * frac
        d.ellipse([cx - rw, cy - r, cx + rw, cy + r], outline=CYAN_DIM, width=3)
    # Equator
    d.line([(cx - r, cy), (cx + r, cy)], fill=CYAN_DIM, width=3)
    # Network nodes on the globe surface (dots) connected by short arcs,
    # suggesting connectivity rather than literal continents.
    import random
    random.seed(7)
    pts = []
    for ang in range(0, 360, 40):
        rad = math.radians(ang)
        px = cx + math.cos(rad) * r * 0.78
        py = cy + math.sin(rad) * r * 0.5
        pts.append((px, py))
    for i, (px, py) in enumerate(pts):
        d.ellipse([px - 6, py - 6, px + 6, py + 6], fill=ORANGE)
    for i in range(len(pts)):
        a = pts[i]
        b = pts[(i + 2) % len(pts)]
        d.line([a, b], fill=(255, 149, 64, 120), width=2)

def draw_browser_window(d, cx, cy, w, h):
    r = 22
    x0, y0, x1, y1 = cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2
    # Window body (rounded rect) — solid, sits in front of the globe
    d.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=(14, 24, 40), outline=WHITE, width=5)
    # Title bar
    bar_h = int(h * 0.22)
    d.rounded_rectangle([x0, y0, x1, y0 + bar_h], radius=r, fill=(22, 36, 58))
    d.rectangle([x0, y0 + bar_h - r, x1, y0 + bar_h], fill=(22, 36, 58))
    # Three "window controls" dots
    dot_y = y0 + bar_h // 2
    for i, col in enumerate((ORANGE, CYAN, WHITE)):
        dx = x0 + 34 + i * 26
        d.ellipse([dx - 7, dot_y - 7, dx + 7, dot_y + 7], fill=col)
    # Address bar
    bar_x0 = x0 + 110
    bar_x1 = x1 - 24
    d.rounded_rectangle([bar_x0, dot_y - 12, bar_x1, dot_y + 12], radius=12, fill=(8, 14, 24))
    d.ellipse([bar_x0 + 12 - 6, dot_y - 6, bar_x0 + 12 + 6, dot_y + 6], outline=CYAN, width=2)
    # Page content area: a stylized upward arrow / compass needle (navigation)
    body_cx, body_cy = cx, y0 + bar_h + (h - bar_h) // 2
    needle_r = min(w, h) * 0.22
    p1 = (body_cx, body_cy - needle_r)
    p2 = (body_cx - needle_r * 0.55, body_cy + needle_r * 0.75)
    p3 = (body_cx + needle_r * 0.55, body_cy + needle_r * 0.75)
    d.polygon([p1, p2, (body_cx, body_cy + needle_r * 0.15), p3], fill=ORANGE)
    d.ellipse([body_cx - 8, body_cy - 8, body_cx + 8, body_cy + 8], fill=WHITE)

def build_icon():
    img, d = make_base()
    cx, cy = W // 2, W // 2
    draw_globe(d, cx, cy, int(W * 0.40))
    draw_browser_window(d, cx, cy + 6, int(W * 0.62), int(W * 0.50))
    return img

def build_wordmark(icon):
    # Horizontal logo: icon + "BrowserNro" wordmark, for README/docs.
    pad = 40
    icon_size = 180
    icon_small = icon.resize((icon_size, icon_size), Image.LANCZOS)
    from PIL import ImageFont
    canvas_w, canvas_h = 900, 260
    img = Image.new("RGB", (canvas_w, canvas_h), (10, 14, 22))
    d = ImageDraw.Draw(img)
    img.paste(icon_small, (pad, (canvas_h - icon_size) // 2))
    text_x = pad * 2 + icon_size
    try:
        font_big = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 72)
        font_small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 28)
    except Exception:
        font_big = ImageFont.load_default()
        font_small = ImageFont.load_default()
    d.text((text_x, 68), "BrowserNro", font=font_big, fill=WHITE)
    d.text((text_x + 4, 158), "navegador para Nintendo Switch", font=font_small, fill=CYAN)
    return img

if __name__ == "__main__":
    icon = build_icon()
    icon.resize((256, 256), Image.LANCZOS).convert("RGB").save(
        "C:/git/BrowserNro/assets/icon/icon.jpg", quality=95
    )
    icon.save("C:/git/BrowserNro/assets/logo/logo-1024.png")
    icon.resize((512, 512), Image.LANCZOS).save("C:/git/BrowserNro/assets/logo/logo-512.png")
    wordmark = build_wordmark(icon)
    wordmark.save("C:/git/BrowserNro/assets/logo/wordmark.png")
    print("OK: icon.jpg (256x256), logo-1024.png, logo-512.png, wordmark.png")
