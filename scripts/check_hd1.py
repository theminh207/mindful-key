#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cổng HĐ-1 — lớp nhịp gõ / chuông không được nhận nội dung.

Hiến chương §4.2 hứa "sản phẩm KHÔNG ĐỌC nội dung người dùng gõ". Lời hứa đó chỉ thật khi người
đọc code NHÌN THẤY ĐƯỢC rằng không có đường nào cho chữ đi vào — mà "nhìn thấy được" thì phụ
thuộc vào việc CÓ AI ĐỌC hay không. Script này biến nó thành thứ không phụ thuộc người.

Hợp đồng: docs/04-contracts.md HĐ-1.

────────────────────────────────────────────────────────────────────────────────────────────────
VÌ SAO LÀ ALLOWLIST, KHÔNG PHẢI DENYLIST

Hai bản trước của cổng này đều là denylist (liệt kê tên kiểu chuỗi bị cấm) và **cả hai đều thủng**:

  · Bản 1 — mẫu đòi kiểu chuỗi đứng TRƯỚC tên lớp trên cùng một dòng, nên
    `void TypingCadence_OnWord(const wstring&)` lọt.
  · Bản 2 — mẫu `string|String|char` bỏ sót `const wchar_t*`... rồi sau khi vá vẫn bỏ sót
    `Uint16` / `Uint32` / `Byte` — TYPEDEF CỦA CHÍNH REPO NÀY, và đúng là cách `core/engine`
    trao ký tự ra ngoài (`Engine.h`: `Uint32 getCharacterCode(const Uint32&)`). Tức hình dạng
    vi phạm DỄ XẢY RA NHẤT lại là hình dạng lọt.

Bài học: **denylist không bao giờ đủ** — nó chỉ chặn được những kiểu người viết đã NGHĨ TỚI, mà
vi phạm thật thường đến từ kiểu người ta không nghĩ tới. Nên đảo chiều: liệt kê thứ ĐƯỢC PHÉP.

API của lớp này cố ý bé và đóng băng (HĐ-3 gọi chữ ký là hợp đồng ổn định), nên allowlist là
khả thi. Thêm một kiểu mới vào API sẽ làm CI đỏ cho tới khi có người sửa file này — đó là **ma
sát có chủ đích**, đúng chỗ đáng có ma sát nhất trong toàn bộ dự án.
────────────────────────────────────────────────────────────────────────────────────────────────
"""

import os
import re
import sys

# Chỉ những kiểu này được phép xuất hiện trong tham số. Toàn số vô hướng — không kiểu nào
# trong đây chở nổi một ký tự.
ALLOWED_PARAM_TYPES = {"int64_t", "int", "double", "bool", "void"}

# Lưới thứ hai, quét TOÀN file (không chỉ tham số) để bắt biến thành viên / biến cục bộ chở nội
# dung. Vẫn là denylist nên KHÔNG đủ một mình — nó chỉ đứng sau allowlist.
BANNED_ANYWHERE = re.compile(
    r"(string|String|char|Uint8|Uint16|Uint32|Byte|TCHAR|LPSTR|LPWSTR|LPCSTR|LPCWSTR|LPTSTR|"
    r"BSTR|unichar|CFString|NSAttributed|\bid\b|uint8_t|uint16_t|filesystem|QString|jstring)"
)

FILES = [
    "core/mood/TypingCadence.h",
    "core/mood/TypingCadence.cpp",
    "core/mood/BellPolicy.h",
    "core/mood/BellPolicy.cpp",
]


def strip_comments(src: str) -> str:
    """Bỏ /* */ và // — thay bằng khoảng trắng để số dòng không đổi."""
    out = []
    i, n = 0, len(src)
    while i < n:
        if src.startswith("/*", i):
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append("".join(ch if ch == "\n" else " " for ch in src[i:j]))
            i = j
        elif src.startswith("//", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        else:
            out.append(src[i])
            i += 1
    return "".join(out)


def check_params(path: str, code: str):
    """Allowlist: mọi tham số phải là kiểu vô hướng được phép, KHÔNG con trỏ/tham chiếu/mảng.

    CHỈ chạy trên `.h`. Đó là nơi DUY NHẤT có mặt API — thứ nhận dữ liệu từ bên ngoài vào. Chạy
    cả trên `.cpp` thì regex bắt nhầm **danh sách khởi tạo constructor** (`_hasLast(false)`) và
    **nơi gọi hàm** (`keystrokesInWindow(nowMs)`) vì chúng cũng có dạng `ten(...)` — đã thử và
    đỏ oan 3 chỗ. `.cpp` vẫn được lưới denylist BANNED_ANYWHERE quét.
    """
    problems = []
    if not path.endswith(".h"):
        return problems
    # Chỉ nhìn khai báo hàm: `<kiểu trả về> ten(...)`. Đủ cho một header API bé.
    for m in re.finditer(r"\b([A-Za-z_]\w*)\s*\(([^;{)]*)\)", code):
        fname, params = m.group(1), m.group(2)
        if fname in ("if", "for", "while", "switch", "return", "sizeof"):
            continue
        line = code[: m.start()].count("\n") + 1
        for raw in params.split(","):
            p = raw.strip()
            if not p:
                continue
            if "*" in p or "&" in p or "[" in p:
                problems.append((line, fname, p, "con trỏ / tham chiếu / mảng — API này chỉ nhận số vô hướng"))
                continue
            toks = [t for t in re.findall(r"[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*", p) if t != "const"]
            if not toks:
                continue
            # Token cuối là TÊN tham số; mọi token trước nó là KIỂU.
            type_toks = toks[:-1] if len(toks) > 1 else toks
            for t in type_toks:
                if t not in ALLOWED_PARAM_TYPES:
                    problems.append((line, fname, p, "kiểu `%s` không nằm trong allowlist %s"
                                     % (t, sorted(ALLOWED_PARAM_TYPES))))
    return problems


def main() -> int:
    files = [f for f in FILES if os.path.exists(f)]
    if not files:
        print("::error::Cổng HĐ-1: không tìm thấy file nào của lớp nhịp gõ/chuông — "
              "cổng không soi được gì. Đổi tên file thì phải sửa FILES trong scripts/check_hd1.py.")
        return 1

    failed = False
    for path in files:
        with open(path, encoding="utf-8") as fh:
            code = strip_comments(fh.read())

        for line, fname, param, why in check_params(path, code):
            print("::error file=%s,line=%d::HĐ-1: tham số `%s` của `%s` — %s"
                  % (path, line, param, fname, why))
            failed = True

        for i, text in enumerate(code.splitlines(), 1):
            m = BANNED_ANYWHERE.search(text)
            if m:
                print("::error file=%s,line=%d::HĐ-1: gặp `%s` — kiểu chuỗi không được xuất hiện "
                      "trong lớp nhịp gõ/chuông, kể cả ở biến cục bộ. Dòng: %s"
                      % (path, i, m.group(1), text.strip()))
                failed = True

    if failed:
        print("::error::HĐ-1 vi phạm. Xem docs/04-contracts.md HĐ-1 — nhận chuỗi rồi chỉ dùng "
              ".length() VẪN là vi phạm.")
        return 1

    print("OK — HĐ-1 sạch: %d file, mọi tham số đều là số vô hướng, không kiểu chuỗi nào."
          % len(files))
    return 0


if __name__ == "__main__":
    sys.exit(main())
