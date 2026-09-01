#!/usr/bin/env python3
"""Stack 3 work-order banners vertically with time footer."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

IMAGE_FILES = [
    Path("/opt/cursor/artifacts/维修工单长图_首单.jpg"),
    Path("/opt/cursor/artifacts/维修工单长图_第二组.jpg"),
    Path("/opt/cursor/artifacts/维修工单长图_第二单8张.jpg"),
]

OUTPUT = Path("/opt/cursor/artifacts/维修工单长图_合并.jpg")
BG_COLOR = (245, 241, 232)
FONT_PATH = "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc"
RECEIVED_AT = datetime(2026, 8, 31, 12, 25, 0)
COMPLETED_AT = datetime(2026, 9, 1, 14, 0, 0)


def load_font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_PATH, size)


def format_cn_datetime(dt: datetime) -> str:
    return dt.strftime("%Y年%m月%d日 %H:%M:%S")


def format_duration(seconds: int) -> str:
    days, rem = divmod(seconds, 86400)
    hours, rem = divmod(rem, 3600)
    minutes, _ = divmod(rem, 60)
    if minutes >= 30:
        hours += 1
        if hours >= 24:
            days += 1
            hours -= 24
    if days and hours:
        return f"{days}天{hours}小时"
    if days:
        return f"{days}天"
    return f"{hours}小时"


def build_footer(width: int) -> Image.Image:
    duration_sec = int((COMPLETED_AT - RECEIVED_AT).total_seconds())
    lines = [
        f"收货时间：{format_cn_datetime(RECEIVED_AT)}",
        f"完成时间：{format_cn_datetime(COMPLETED_AT)}",
        f"耗时：{format_duration(duration_sec)}",
    ]
    font = load_font(42)
    probe = ImageDraw.Draw(Image.new("RGB", (10, 10)))

    def lh(text: str) -> int:
        bbox = probe.textbbox((0, 0), text, font=font)
        return bbox[3] - bbox[1]

    pad_x, pad_y, gap = 42, 34, 12
    height = pad_y * 2 + sum(lh(line) + gap for line in lines) - gap
    footer = Image.new("RGB", (width, height), BG_COLOR)
    draw = ImageDraw.Draw(footer)
    y = pad_y
    for line in lines:
        draw.text((pad_x, y), line, font=font, fill=(35, 35, 35))
        y += lh(line) + gap
    return footer


def main() -> None:
    images = [Image.open(path).convert("RGB") for path in IMAGE_FILES]
    width = images[0].width
    footer = build_footer(width)
    height = sum(img.height for img in images) + footer.height
    canvas = Image.new("RGB", (width, height), BG_COLOR)

    y = 0
    for img in images:
        canvas.paste(img, (0, y))
        y += img.height

    canvas.paste(footer, (0, y))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUTPUT, format="JPEG", quality=95, optimize=True)
    print(OUTPUT)
    print(canvas.size)
    print(f"duration={format_duration(int((COMPLETED_AT - RECEIVED_AT).total_seconds()))}")


if __name__ == "__main__":
    main()
