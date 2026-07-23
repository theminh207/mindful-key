#!/usr/bin/env python3
# [MINDFUL] D1 — đồng bộ version cho vỏ Windows từ nguồn DUY NHẤT `version.env`.
#
# Trước đây `MindfulKey.rc` hardcode FILEVERSION/PRODUCTVERSION nên file .exe khai version cũ dù
# `version.env` đã bump (vd .exe ghi 0.4.13 khi thật là 0.4.15) — người dùng xem Properties thấy sai.
# Script này chạy TRƯỚC msbuild (trong CI) để ghi đè 4 dòng version trong .rc cho khớp version.env.
#
# Chạy tay:  python3 scripts/sync-win-version.py
# Idempotent: chạy nhiều lần cho cùng kết quả; chỉ động đúng 4 dòng version, không đụng gì khác.

import os
import re
import sys

# [MINDFUL] stdout của Python trên runner Windows mặc định là cp1252 (không mã hoá nổi tiếng Việt) →
# in chữ có dấu là crash `UnicodeEncodeError`. Ép UTF-8; mọi thông báo dưới cũng giữ ASCII cho chắc.
try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RC = os.path.join(ROOT, "platforms", "windows", "win32", "MindfulKey", "MindfulKey", "MindfulKey.rc")


def read_version():
    """Đọc VERSION=x.y.z từ version.env (nguồn phiên bản duy nhất)."""
    env = os.path.join(ROOT, "version.env")
    with open(env, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("VERSION="):
                v = line.split("=", 1)[1].strip()
                parts = v.split(".")
                if len(parts) != 3 or not all(p.isdigit() for p in parts):
                    sys.exit(f"version.env: VERSION not in x.y.z form: {v!r}")
                return parts  # ['0','4','15']
    sys.exit("version.env: no VERSION= line found")


def main():
    a, b, c = read_version()
    comma = f"{a},{b},{c},0"        # dạng FILEVERSION: 0,4,15,0
    dot = f"{a}.{b}.{c}.0"          # dạng chuỗi: "0.4.15.0"

    with open(RC, encoding="utf-8") as f:
        text = f.read()

    subs = [
        (r"(\bFILEVERSION\s+)\d+,\s*\d+,\s*\d+,\s*\d+", rf"\g<1>{comma}"),
        (r"(\bPRODUCTVERSION\s+)\d+,\s*\d+,\s*\d+,\s*\d+", rf"\g<1>{comma}"),
        (r'(VALUE\s+"FileVersion",\s+")[\d.]+(")', rf"\g<1>{dot}\g<2>"),
        (r'(VALUE\s+"ProductVersion",\s+")[\d.]+(")', rf"\g<1>{dot}\g<2>"),
    ]
    total = 0
    for pat, repl in subs:
        text, n = re.subn(pat, repl, text)
        total += n
        if n == 0:
            sys.exit(f"pattern not matched (did .rc structure change?): {pat}")

    with open(RC, "w", encoding="utf-8") as f:
        f.write(text)

    print(f"sync-win-version: .rc -> version {dot} ({total} fields written)")


if __name__ == "__main__":
    main()
