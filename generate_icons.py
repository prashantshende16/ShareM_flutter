import os, math
from PIL import Image, ImageDraw, ImageFilter

def draw_rounded_rect(draw, box, radius, fill):
    x0, y0, x1, y1 = box
    r = min(radius, (x1 - x0) // 2, (y1 - y0) // 2)
    if r <= 0:
        draw.rectangle(box, fill=fill)
        return
    draw.rectangle([x0 + r, y0, x1 - r, y1], fill=fill)
    draw.rectangle([x0, y0 + r, x1, y1 - r], fill=fill)
    draw.pieslice([x0, y0, x0 + 2*r, y0 + 2*r], 180, 270, fill=fill)
    draw.pieslice([x1 - 2*r, y0, x1, y0 + 2*r], 270, 360, fill=fill)
    draw.pieslice([x0, y1 - 2*r, x0 + 2*r, y1], 90, 180, fill=fill)
    draw.pieslice([x1 - 2*r, y1 - 2*r, x1, y1], 0, 90, fill=fill)

def render_emblem(size, emblem_r):
    cx, cy = size // 2, size // 2
    emblem_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # 1. Glow behind emblem
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glow)
    g_draw.ellipse([cx - emblem_r - 20, cy - emblem_r - 20, cx + emblem_r + 20, cy + emblem_r + 20], fill=(16, 185, 129, 120))
    glow = glow.filter(ImageFilter.GaussianBlur(int(size * 0.035)))
    emblem_layer = Image.alpha_composite(emblem_layer, glow)

    # 2. Disc with diagonal gradient
    # Fast rendering: create gradient at 256x256, mask with circle, resize
    disc = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d_draw = ImageDraw.Draw(disc)
    for y in range(256):
        for x in range(256):
            diag = (x + y) / (256 * 2)
            # Emerald (#10B981) to Oceanic Cyan (#0284C7)
            r = int(16 * (1 - diag) + 2 * diag)
            g = int(185 * (1 - diag) + 132 * diag)
            b = int(129 * (1 - diag) + 199 * diag)
            d_draw.point((x, y), fill=(r, g, b, 255))
            
    # Circular mask
    mask = Image.new("L", (256, 256), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.ellipse([0, 0, 255, 255], fill=255)
    
    disc_scaled = disc.resize((emblem_r * 2, emblem_r * 2), Image.LANCZOS)
    mask_scaled = mask.resize((emblem_r * 2, emblem_r * 2), Image.LANCZOS)
    
    disc_final = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    disc_final.paste(disc_scaled, (cx - emblem_r, cy - emblem_r), mask_scaled)
    
    # Inner gloss ring
    df_draw = ImageDraw.Draw(disc_final)
    gloss_w = max(2, int(size * 0.008))
    df_draw.ellipse([cx - emblem_r + gloss_w, cy - emblem_r + gloss_w, cx + emblem_r - gloss_w, cy + emblem_r - gloss_w],
                    outline=(255, 255, 255, 75), width=gloss_w)
    
    emblem_layer = Image.alpha_composite(emblem_layer, disc_final)

    # 3. Candlesticks
    cand = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    c_draw = ImageDraw.Draw(cand)

    wick_w = max(2, int(size * 0.016))
    body_w = int(emblem_r * 0.30)
    corner_r = int(size * 0.018)

    # Candle 1 (Left: Bullish base)
    c1_x = int(cx - emblem_r * 0.36)
    c1_top_wick = int(cy - emblem_r * 0.65)
    c1_bot_wick = int(cy + emblem_r * 0.65)
    c1_body_top = int(cy - emblem_r * 0.06)
    c1_body_bot = int(cy + emblem_r * 0.48)

    # Candle 2 (Right: Taller Bullish Surge)
    c2_x = int(cx + emblem_r * 0.36)
    c2_top_wick = int(cy - emblem_r * 0.82)
    c2_bot_wick = int(cy + emblem_r * 0.44)
    c2_body_top = int(cy - emblem_r * 0.54)
    c2_body_bot = int(cy + emblem_r * 0.12)

    # Candlestick drop shadows
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.line([(c1_x+3, c1_top_wick+4), (c1_x+3, c1_bot_wick+4)], fill=(0, 0, 0, 95), width=wick_w)
    draw_rounded_rect(s_draw, [c1_x - body_w//2 + 3, c1_body_top + 4, c1_x + body_w//2 + 3, c1_body_bot + 4], corner_r, (0, 0, 0, 95))
    s_draw.line([(c2_x+3, c2_top_wick+4), (c2_x+3, c2_bot_wick+4)], fill=(0, 0, 0, 95), width=wick_w)
    draw_rounded_rect(s_draw, [c2_x - body_w//2 + 3, c2_body_top + 4, c2_x + body_w//2 + 3, c2_body_bot + 4], corner_r, (0, 0, 0, 95))
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(2, int(size * 0.007))))
    emblem_layer = Image.alpha_composite(emblem_layer, shadow)

    # Candlesticks crisp white
    c_draw.line([(c1_x, c1_top_wick), (c1_x, c1_bot_wick)], fill=(255, 255, 255, 255), width=wick_w)
    draw_rounded_rect(c_draw, [c1_x - body_w//2, c1_body_top, c1_x + body_w//2, c1_body_bot], corner_r, (255, 255, 255, 255))

    c_draw.line([(c2_x, c2_top_wick), (c2_x, c2_bot_wick)], fill=(255, 255, 255, 255), width=wick_w)
    draw_rounded_rect(c_draw, [c2_x - body_w//2, c2_body_top, c2_x + body_w//2, c2_body_bot], corner_r, (255, 255, 255, 255))

    emblem_layer = Image.alpha_composite(emblem_layer, cand)
    return emblem_layer

def generate_legacy_icon(size):
    # Full icon with dark container and glowing rim
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)

    cx, cy = size // 2, size // 2
    outer_r = int(size * 0.46)
    for r in range(outer_r, 0, -2):
        t = r / outer_r
        cr = int(6 + (20 - 6) * (1 - t)**1.2)
        cg = int(9 + (30 - 9) * (1 - t)**1.2)
        cb = int(18 + (50 - 18) * (1 - t)**1.2)
        bg_draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(cr, cg, cb, 255))

    border_w = max(2, int(size * 0.016))
    for deg in range(360):
        rad = math.radians(deg)
        t = (math.sin(rad - math.pi/4) + 1) / 2
        er = int(16 * (1 - t) + 6 * t)
        eg = int(185 * (1 - t) + 182 * t)
        eb = int(129 * (1 - t) + 212 * t)
        bg_draw.arc([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r],
                    start=deg, end=deg+2, fill=(er, eg, eb, 230), width=border_w)

    img = Image.alpha_composite(img, bg)
    emblem = render_emblem(size, int(size * 0.33))
    img = Image.alpha_composite(img, emblem)
    return img

def generate_adaptive_foreground(size):
    # 108dp base canvas. The safe circle zone has diameter 72dp (~66.6% of canvas).
    # We place the emblem with radius ~ 0.28 * size (diameter 56% of canvas, comfortably safe inside 66%).
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    emblem = render_emblem(size, int(size * 0.28))
    img = Image.alpha_composite(img, emblem)
    return img

# Generate Master 1024x1024
print("Rendering Master 1024x1024 icon...")
master_icon = generate_legacy_icon(1024)
master_foreground = generate_adaptive_foreground(1024)

# Android Densities
DENSITIES = {
    "mdpi": {"legacy": 48, "foreground": 108},
    "hdpi": {"legacy": 72, "foreground": 162},
    "xhdpi": {"legacy": 96, "foreground": 216},
    "xxhdpi": {"legacy": 144, "foreground": 324},
    "xxxhdpi": {"legacy": 192, "foreground": 432},
}

res_dir = "/home/dev04/development/shareM/flutter_app/android/app/src/main/res"

for density, sizes in DENSITIES.items():
    density_dir = os.path.join(res_dir, f"mipmap-{density}")
    os.makedirs(density_dir, exist_ok=True)
    
    # 1. ic_launcher.png
    leg_size = sizes["legacy"]
    icon_img = master_icon.resize((leg_size, leg_size), Image.LANCZOS)
    icon_path = os.path.join(density_dir, "ic_launcher.png")
    icon_img.save(icon_path, "PNG")
    
    # 2. ic_launcher_round.png
    round_path = os.path.join(density_dir, "ic_launcher_round.png")
    icon_img.save(round_path, "PNG")
    
    # 3. ic_launcher_foreground.png (Adaptive icon foreground)
    fg_size = sizes["foreground"]
    fg_img = master_foreground.resize((fg_size, fg_size), Image.LANCZOS)
    fg_path = os.path.join(density_dir, "ic_launcher_foreground.png")
    fg_img.save(fg_path, "PNG")
    
    print(f"Saved {density}: legacy={leg_size}x{leg_size}, foreground={fg_size}x{fg_size}")

# Web icons
web_dir = "/home/dev04/development/shareM/flutter_app/web"
web_icons_dir = os.path.join(web_dir, "icons")
os.makedirs(web_icons_dir, exist_ok=True)

fav = master_icon.resize((64, 64), Image.LANCZOS)
fav.save(os.path.join(web_dir, "favicon.png"), "PNG")

icon_192 = master_icon.resize((192, 192), Image.LANCZOS)
icon_192.save(os.path.join(web_icons_dir, "Icon-192.png"), "PNG")
icon_192.save(os.path.join(web_icons_dir, "Icon-maskable-192.png"), "PNG")

icon_512 = master_icon.resize((512, 512), Image.LANCZOS)
icon_512.save(os.path.join(web_icons_dir, "Icon-512.png"), "PNG")
icon_512.save(os.path.join(web_icons_dir, "Icon-maskable-512.png"), "PNG")

# Also save master app asset
os.makedirs("/home/dev04/development/shareM/flutter_app/assets/icon", exist_ok=True)
master_icon.save("/home/dev04/development/shareM/flutter_app/assets/icon/app_icon.png", "PNG")

print("All app icons generated successfully!")
