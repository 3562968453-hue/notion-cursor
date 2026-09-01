#!/usr/bin/env python3
"""Generate work-order banner matching reference style."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ASSETS = Path("/home/ubuntu/.cursor/projects/workspace/assets")
OUTPUT = Path("/opt/cursor/artifacts/维修工单长图_首单.jpg")

PHOTO_FILES = [
    "01a05c0e-05fc-7ee4-8818-f1daf8f67951.jpg",
    "01a05c0e-066d-73b4-bed8-791ec4200148.jpg",
    "01a05c0e-06ae-762d-b12a-2813e5ef7c7d.jpg",
    "01a05c0e-06e6-7b9a-ae37-aebe6a7dc92e.jpg",
    "01a05c0e-06fc-7974-a3f6-403dbb3377d5.jpg",
    "01a05c0e-0736-7613-889c-2071de23a148.jpg",
    "01a05c0e-0796-734e-a59e-8aab41956b93.jpg",
    "01a05c0e-07f9-7569-a1cd-0c62e6b2bc46.jpg",
    "01a05c0e-085f-704d-a73a-8d7afd464ba6.jpg",
]

CANVAS_W = 2400
PHOTO_H = 640
FOOTER_H = 180
DIVIDER_W = 2
BG_COLOR = (245, 241, 232)

FONT_PATH = "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc"
FEE_TEXT = "收费：20（首单）"
BRAND_LABEL = ""


def load_font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_PATH, size)


def strip_phone_ui(img: Image.Image) -> Image.Image:
    w, h = img.size
    top = int(h * 0.115)
    bottom = int(h * 0.175)
    return img.crop((0, top, w, h - bottom))


def center_square(img: Image.Image) -> Image.Image:
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return img.crop((left, top, left + side, top + side))


def prepare_photo(path: Path) -> Image.Image:
    img = Image.open(path).convert("RGB")
    if img.width / img.height < 0.55:
        img = strip_phone_ui(img)
    return center_square(img)


def fit_cover(img: Image.Image, w: int, h: int) -> Image.Image:
    src_w, src_h = img.size
    scale = max(w / src_w, h / src_h)
    nw, nh = int(src_w * scale), int(src_h * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - w) // 2
    top = (nh - h) // 2
    return resized.crop((left, top, left + w, top + h))


def draw_fee(draw: ImageDraw.ImageDraw, cell_w: int, cell_h: int) -> None:
    margin = 12
    max_w = cell_w - margin * 2
    font_size = 40
    font = load_font(font_size)
    bbox = draw.textbbox((0, 0), FEE_TEXT, font=font)
    tw = bbox[2] - bbox[0]
    while tw > max_w and font_size > 24:
        font_size -= 2
        font = load_font(font_size)
        bbox = draw.textbbox((0, 0), FEE_TEXT, font=font)
        tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = max(margin, cell_w - margin - tw)
    y = cell_h - margin - th
    draw.text((x, y), FEE_TEXT, font=font, fill=(220, 35, 30), stroke_width=2, stroke_fill=(255, 255, 255))


def draw_brand_label(canvas: Image.Image) -> None:
    if not BRAND_LABEL:
        return
    draw = ImageDraw.Draw(canvas)
    font = load_font(48)
    margin = 22
    draw.text(
        (margin, margin),
        BRAND_LABEL,
        font=font,
        fill=(255, 255, 255),
        stroke_width=2,
        stroke_fill=(30, 30, 30),
    )


def draw_footer(canvas: Image.Image) -> None:
    bless_lines = [
        "祝老板早日骑到300瓦！",
        "一路顺风，功率拉满，越骑越强！",
    ]

    bless_font = load_font(44)
    draw = ImageDraw.Draw(canvas)
    y0 = PHOTO_H + 42

    probe = draw.textbbox((0, 0), bless_lines[0], font=bless_font)
    line_h = probe[3] - probe[1]
    right_x = CANVAS_W - 42
    b_y = y0
    for line in bless_lines:
        bbox = draw.textbbox((0, 0), line, font=bless_font)
        tw = bbox[2] - bbox[0]
        draw.text((right_x - tw, b_y), line, font=bless_font, fill=(220, 35, 30))
        b_y += line_h + 18

    draw.text((right_x - 520, y0 + 2), "—··", font=load_font(36), fill=(220, 35, 30))
    draw.text((right_x - 110, y0 + 66), "··", font=load_font(36), fill=(220, 35, 30))


def main() -> None:
    n = len(PHOTO_FILES)
    cell_w = (CANVAS_W - DIVIDER_W * (n - 1)) // n

    canvas = Image.new("RGB", (CANVAS_W, PHOTO_H + FOOTER_H), BG_COLOR)

    x = 0
    for idx, name in enumerate(PHOTO_FILES):
        square = prepare_photo(ASSETS / name)
        cell = fit_cover(square, cell_w, PHOTO_H)
        if idx == n - 1:
            cell_draw = ImageDraw.Draw(cell)
            draw_fee(cell_draw, cell_w, PHOTO_H)
        canvas.paste(cell, (x, 0))
        x += cell_w
        if idx < n - 1:
            divider = Image.new("RGB", (DIVIDER_W, PHOTO_H), (255, 255, 255))
            canvas.paste(divider, (x, 0))
            x += DIVIDER_W

    draw_brand_label(canvas)
    draw_footer(canvas)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUTPUT, format="JPEG", quality=95, optimize=True)
    print(OUTPUT)
    print(canvas.size)


if __name__ == "__main__":
    main()
