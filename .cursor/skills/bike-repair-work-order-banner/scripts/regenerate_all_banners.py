#!/usr/bin/env python3
"""Regenerate three labeled banners and merged long image."""

from __future__ import annotations

import importlib.util
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "gen",
    str(Path(__file__).parent / "generate_work_order_long_image.py"),
)
gen = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gen)

BANNERS = [
    {
        "output": Path("/opt/cursor/artifacts/维修工单长图_首单.jpg"),
        "label": "马吉斯high road",
        "fee": "收费：20（首单）",
        "photos": [
            "01a05c0e-05fc-7ee4-8818-f1daf8f67951.jpg",
            "01a05c0e-066d-73b4-bed8-791ec4200148.jpg",
            "01a05c0e-06ae-762d-b12a-2813e5ef7c7d.jpg",
            "01a05c0e-06e6-7b9a-ae37-aebe6a7dc92e.jpg",
            "01a05c0e-06fc-7974-a3f6-403dbb3377d5.jpg",
            "01a05c0e-0736-7613-889c-2071de23a148.jpg",
            "01a05c0e-0796-734e-a59e-8aab41956b93.jpg",
            "01a05c0e-07f9-7569-a1cd-0c62e6b2bc46.jpg",
            "01a05c0e-085f-704d-a73a-8d7afd464ba6.jpg",
        ],
    },
    {
        "output": Path("/opt/cursor/artifacts/维修工单长图_第二组.jpg"),
        "label": "cadex",
        "fee": "收费：25",
        "photos": [
            "01a05c05-9fee-711d-8877-37562d030187.jpg",
            "01a05c05-a05e-7cdc-82cc-0718f70e96a3.jpg",
            "01a05c05-a0bf-756b-8592-af29b544cc7b.jpg",
            "01a05c05-a126-7727-a1ce-ce0003f7c6b7.jpg",
            "01a05c05-a16a-72aa-bf82-c6c8f157471d.jpg",
            "01a05c05-a1a5-7bf1-aea5-1789cb0f3c10.jpg",
            "01a05c05-a1de-742c-9d3e-f92ced722d22.jpg",
        ],
    },
    {
        "output": Path("/opt/cursor/artifacts/维修工单长图_第二单8张.jpg"),
        "label": "倍耐力rs",
        "fee": "收费：25",
        "photos": [
            "01a05ba2-08c3-7026-9157-90b63542cc8d.jpg",
            "01a05ba2-0930-7c2d-b870-5f71b5d1fbae.jpg",
            "01a05ba2-0995-7e0a-a3c7-f19cc6eb02b3.jpg",
            "01a05ba2-0a03-7a8d-97d4-d24dee002484.jpg",
            "01a05ba2-0a69-799f-aef6-547476cf1f1d.jpg",
            "01a05ba2-0a9f-7ff6-a335-968155593bd1.jpg",
            "01a05ba2-0ad1-7d8e-819e-e09da176b393.jpg",
            "01a05ba2-0b03-7c28-8e52-f15416b6d8da.jpg",
        ],
    },
]


def main() -> None:
    for banner in BANNERS:
        gen.PHOTO_FILES = banner["photos"]
        gen.FEE_TEXT = banner["fee"]
        gen.BRAND_LABEL = banner["label"]
        gen.OUTPUT = banner["output"]
        gen.main()

    import importlib.util
    merge_spec = importlib.util.spec_from_file_location(
        "merge", str(Path(__file__).parent / "generate_merged_long_image.py")
    )
    merge = importlib.util.module_from_spec(merge_spec)
    merge_spec.loader.exec_module(merge)

    merge.main()


if __name__ == "__main__":
    main()
