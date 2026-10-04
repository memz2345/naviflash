#!/usr/bin/env python3
"""补齐 pub 缓存里老插件的 `jcenter()`。

背景：Gradle 9 移除了 `jcenter()`，而少数老 Flutter 插件仍在
`android/build.gradle` 里写 `jcenter()`（本项目命中 video_thumbnail）——
AGP 9 + Gradle 9 下会在配置阶段直接失败：

    Could not find method jcenter() for arguments []
    on repository container of type DefaultRepositoryHandler

jcenter 早已只读下线，这里统一换成 mavenCentral()（语义等价且仍可用）。

用法（在仓库根目录执行，改的是 pub 缓存，不随仓库提交）：

    python tool/patch_pub_jcenter.py            # 打补丁
    python tool/patch_pub_jcenter.py --check    # 只检查不修改

注意：`flutter pub cache repair` / 清缓存后需要重跑一次。
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

PUB_CACHE_CANDIDATES = [
    Path(os.environ.get("PUB_CACHE", "")) if os.environ.get("PUB_CACHE") else None,
    Path.home() / "AppData/Local/Pub/Cache",
    Path.home() / ".pub-cache",
]

HOSTED_DIRS = ("hosted/pub.flutter-io.cn", "hosted/pub.dev")
PATTERN = re.compile(r"\bjcenter\s*\(\s*\)")


def pub_caches() -> list[Path]:
    roots: list[Path] = []
    for base in PUB_CACHE_CANDIDATES:
        if base is None or not base.exists():
            continue
        for hosted in HOSTED_DIRS:
            d = base / hosted
            if d.exists():
                roots.append(d)
    return roots


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只报告，不修改")
    args = ap.parse_args()

    roots = pub_caches()
    if not roots:
        print("找不到 pub 缓存目录（检查 PUB_CACHE 环境变量）")
        return 1

    hits: list[Path] = []
    for root in roots:
        for gradle in root.glob("*/android/build.gradle"):
            try:
                text = gradle.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            if PATTERN.search(text):
                hits.append(gradle)

    if not hits:
        print("没有发现使用 jcenter() 的插件，无需处理")
        return 0

    for path in hits:
        if args.check:
            print(f"[需要补丁] {path}")
            continue
        text = path.read_text(encoding="utf-8")
        new = PATTERN.sub("mavenCentral()", text)
        if new != text:
            path.write_text(new, encoding="utf-8")
            print(f"[已修复] {path}")
        else:
            print(f"[跳过] {path}")

    if args.check and hits:
        print(f"\n共 {len(hits)} 个文件需要补丁，去掉 --check 即可执行")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
