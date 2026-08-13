#!/usr/bin/env python3
from pathlib import Path
import math
import re
import sys

from PIL import Image, ImageDraw

decoded = Path(sys.argv[1])
manifest = decoded / "AndroidManifest.xml"
if not manifest.exists():
    raise SystemExit("AndroidManifest.xml not found after decode")

text = manifest.read_text(encoding="utf-8", errors="ignore")
text = re.sub(r'android:label="[^"]*"', 'android:label="PVNetwork VPN"', text, count=1)
manifest.write_text(text, encoding="utf-8")

for path in (decoded / "res").rglob("*.xml"):
    try:
        current = path.read_text(encoding="utf-8")
    except Exception:
        continue
    updated = current.replace("Amnezia VPN", "PVNetwork VPN").replace(">Amnezia<", ">PVNetwork<")
    if updated != current:
        path.write_text(updated, encoding="utf-8")

def star_points(cx, cy, r1, r2, count=5):
    pts = []
    for i in range(count * 2):
        a = -math.pi / 2 + i * math.pi / count
        r = r1 if i % 2 == 0 else r2
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts

def make_icon(size):
    img = Image.new("RGBA", (size, size), (8, 8, 10, 255))
    d = ImageDraw.Draw(img)
    gold = (235, 170, 42, 255)
    gold2 = (255, 206, 77, 255)
    dark = (14, 14, 18, 255)
    m = size * 0.10
    d.ellipse((m, m * 1.25, size - m, size - m * 0.65), outline=gold, width=max(2, size // 28))
    d.polygon([(size*.50,size*.19),(size*.73,size*.29),(size*.69,size*.59),(size*.50,size*.79),(size*.31,size*.59),(size*.27,size*.29)], fill=gold)
    d.polygon([(size*.50,size*.25),(size*.66,size*.32),(size*.63,size*.55),(size*.50,size*.70),(size*.37,size*.55),(size*.34,size*.32)], fill=dark)
    r = size * .055
    cx, cy = size * .50, size * .44
    d.ellipse((cx-r, cy-r, cx+r, cy+r), fill=gold2)
    d.polygon([(cx-size*.035,cy+size*.02),(cx+size*.035,cy+size*.02),(cx+size*.065,cy+size*.18),(cx-size*.065,cy+size*.18)], fill=gold2)
    for x in (.39,.50,.61):
        d.polygon(star_points(size*x,size*.14,size*.035,size*.015), fill=gold2)
    return img

density_sizes = {"mipmap-ldpi":36,"mipmap-mdpi":48,"mipmap-hdpi":72,"mipmap-xhdpi":96,"mipmap-xxhdpi":144,"mipmap-xxxhdpi":192}
for density, size in density_sizes.items():
    directory = decoded / "res" / density
    if not directory.exists():
        continue
    generated = make_icon(size)
    for name in ("icon.png","icon_round.png","ic_launcher_foreground.png"):
        target = directory / name
        if target.exists():
            generated.save(target, "PNG", optimize=True)

print("PVNetwork V0.1 branding applied successfully")
