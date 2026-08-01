#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cổng HĐ-1 — lớp nhịp gõ / chuông không được nhận nội dung.

Hiến chương §4.2 hứa "sản phẩm KHÔNG ĐỌC nội dung người dùng gõ". Lời hứa đó chỉ thật khi người
đọc code NHÌN THẤY ĐƯỢC rằng không có đường nào cho chữ đi vào — mà "nhìn thấy được" thì phụ
thuộc vào việc CÓ AI ĐỌC hay không. Script này biến nó thành thứ không phụ thuộc người.

Hợp đồng: docs/04-contracts.md HĐ-1.  ·  Chạy tại chỗ: python3 scripts/check_hd1.py

────────────────────────────────────────────────────────────────────────────────────────────────
VÌ SAO LÀ ALLOWLIST, KHÔNG PHẢI DENYLIST

Cổng này đã thủng BA LẦN, mỗi lần một kiểu, tất cả đều khi còn là denylist:

  1. Mẫu đòi kiểu chuỗi đứng TRƯỚC tên lớp trên cùng một dòng
     → `void TypingCadence_OnWord(const wstring&)` lọt.
  2. Mẫu `string|String|char` bỏ sót `const wchar_t*`.
  3. Sau khi vá (2) vẫn bỏ sót `Uint16` / `Uint32` / `Byte` — TYPEDEF CỦA CHÍNH REPO NÀY, và
     đúng là cách core/engine trao ký tự ra ngoài (Engine.h: `Uint32 getCharacterCode(const
     Uint32&)`). Tức hình dạng vi phạm DỄ XẢY RA NHẤT lại là hình dạng lọt.

Bài học: **denylist không bao giờ đủ** — nó chỉ chặn được những kiểu người viết đã NGHĨ TỚI, mà
vi phạm thật thường đến từ kiểu người ta không nghĩ tới. Vá thêm tên kiểu là đuổi theo cái đuôi
của chính mình. Nên đảo chiều: liệt kê thứ ĐƯỢC PHÉP.

API của lớp này cố ý bé và đóng băng (HĐ-3 gọi chữ ký là hợp đồng ổn định), nên allowlist khả
thi. Thêm kiểu mới vào API sẽ làm CI đỏ cho tới khi có người sửa file này — **ma sát có chủ
đích**, đúng chỗ đáng có ma sát nhất trong dự án.

CÁCH KIỂM CỔNG NÀY (đừng bỏ qua): tiêm một khai báo vi phạm vào core/mood/TypingCadence.h, chạy
script, xem nó có ĐỎ không, rồi `git checkout` lại. Thấy cổng xanh trên code sạch KHÔNG chứng
minh được gì. Và hãy tiêm cả những hình dạng bạn CHƯA nghĩ tới — cả ba lần thủng ở trên đều lọt
đúng vào hình dạng người viết chưa nghĩ tới.

────────────────────────────────────────────────────────────────────────────────────────────────
BA LƯỚI, VÀ GIỚI HẠN THẬT CỦA CHÚNG

  1. Bản ghim bề mặt khai báo (PIN_FILE) — mạnh nhất. Mọi dòng khai báo trong header được soi
     phải khớp đúng bản ghim. Thêm BẤT KỲ tham số nào, kiểu gì, hay thêm một biến thành viên,
     đều làm đỏ cho tới khi có người chạy --update-pin và giải trình.
  2. Allowlist kiểu tham số — chỉ int64_t/int/double/bool/void, không con trỏ/tham chiếu/mảng.
  3. Denylist tên kiểu, quét cả .cpp — lưới thô, bắt biến cục bộ mang kiểu chuỗi.

GIỚI HẠN, nói thẳng để không ai tưởng cổng này kín tuyệt đối:

  · Lưới 2 KHÔNG chứng minh "không nội dung nào vào". `void noteChar(int codePoint)` đi qua
    allowlist xanh — `int` thừa sức chở một codepoint Unicode. Chính lưới 1 mới chặn nó.
  · Một vùng đệm cỡ `static int gTyped[4096];` trong .cpp thì cả ba lưới đều cho qua. Nhưng nó
    là **kho chứa trơ**: muốn đổ dữ liệu vào phải có đường nhận từ ngoài, mà mọi đường như thế
    đều nằm ở header và đã bị lưới 1 ghim. Nói cách khác cổng này bảo đảm **bề mặt NHẬN**, không
    bảo đảm từng byte bộ nhớ bên trong.
  · Macro định nghĩa ở file miễn trừ rồi dùng ở file được soi thì lách được. Đòi cố ý che giấu,
    không phải thứ ai vô tình viết ra — và danh sách miễn trừ đang co lại theo #12/#13.
────────────────────────────────────────────────────────────────────────────────────────────────
"""

import os
import re
import sys

# Máy dev của dự án là Windows, console cp1252 — thông điệp tiếng Việt dưới đây làm script chết
# bằng UnicodeEncodeError nếu không ép UTF-8. Điểm bán hàng của file này là "chạy được tại máy
# dev" (máy đó không có trình biên dịch nào, nhưng có python), nên nó phải chạy trơn ở đó.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Chỉ những kiểu này được phép làm tham số. Toàn số vô hướng — không kiểu nào chở nổi một ký tự.
ALLOWED_PARAM_TYPES = {"int64_t", "int", "double", "bool", "void"}

# Lưới THỨ HAI, quét toàn file (không chỉ tham số) để bắt biến thành viên / biến cục bộ chở nội
# dung. Vẫn là denylist nên KHÔNG đủ một mình — nó chỉ đứng sau allowlist.
#
# `\bchar\b` có ranh giới từ, KHÔNG phải `char` trần: đơn vị của chính lớp này là
# *characters*-per-minute, nên `charsPerMinute()` / `charCount()` là tên hợp lệ và từng bị bắt
# oan. Các kiểu ký tự khác phải liệt riêng.
#
# `uint32_t` từng THIẾU ở đây và đó là lỗ thật: `operator<<(const uint32_t*)` lọt cả allowlist
# (vì tên toán tử không khớp regex tên hàm) lẫn lưới này.
BANNED_ANYWHERE = re.compile(
    r"(string|String|\bchar\b|wchar_t|char16_t|char32_t|unichar|"
    r"\bUint8\b|\bUint16\b|\bUint32\b|\bByte\b|"
    r"uint8_t|uint16_t|uint32_t|\bunsigned\s+short\b|"
    r"TCHAR|LPSTR|LPWSTR|LPCSTR|LPCWSTR|LPTSTR|BSTR|CFString|NSAttributed|\bid\b|"
    r"filesystem|QString|jstring)"
)

MOOD_DIR = "core/mood"

# Bộ đuôi CỐ Ý RỘNG. Bản trước chỉ nhận `.h`/`.cpp`, nên `ContentTap.hpp` / `.hh` / `.inl` /
# `.mm` đi lọt — toàn đuôi hợp lệ, biên dịch bình thường, include bình thường.
SOURCE_EXTS = (".h", ".hpp", ".hh", ".inl", ".cpp", ".cc", ".cxx", ".mm", ".m")
HEADER_EXTS = (".h", ".hpp", ".hh", ".inl")

# Bản ghim bề mặt khai báo. HĐ-3 tuyên chữ ký của lớp này là hợp đồng ĐÓNG BĂNG — file kia biến
# lời tuyên đó thành thứ kiểm được bằng máy.
PIN_FILE = "scripts/hd1_pinned_api.txt"

# Phải tồn tại — nếu không thì cổng chẳng soi được gì và ta muốn ĐỎ, để không ai vô hiệu hoá
# cổng bằng cách đổi tên file.
REQUIRED = ["core/mood/TypingCadence.h", "core/mood/TypingCadence.cpp"]

# Miễn trừ CÓ THỜI HẠN: file của mô hình CŨ (đọc cảm xúc), đang chờ #12/#13 gỡ. Chúng có kiểu
# chuỗi một cách hợp pháp vì chúng *là* lớp đọc nội dung.
#
# Cố ý làm DANH SÁCH MIỄN TRỪ (co lại dần, và cạn khi #13 xong) thay vì danh sách file-được-soi
# (phải nhớ mà thêm). Bản trước liệt cứng 4 đường dẫn được soi, nên một file MỚI trong
# core/mood/ hoàn toàn VÔ HÌNH với cổng — thêm `ContentTap.h` chứa `const uint32_t*` thì cổng
# vẫn xanh. Lộ trình sắp tới có "kho ghi lần chuông" là file mới, sẽ dính ngay.
LEGACY_EXEMPT = {
    "core/mood/SendRiskAnalyzer.h",
    "core/mood/SendRiskAnalyzer.cpp",
    "core/mood/MoodBuffer.h",
    "core/mood/MoodBuffer.cpp",
    "core/mood/MoodPhrasing.h",
    "core/mood/MoodPhrasing.cpp",
    "core/mood/BreathingPause.h",
}

CONTROL_KEYWORDS = ("if", "for", "while", "switch", "return", "sizeof", "catch")


def strip_comments(src):
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


def check_params(path, code):
    """Allowlist: mọi tham số phải là kiểu vô hướng được phép, KHÔNG con trỏ/tham chiếu/mảng.

    CHỈ chạy trên `.h` — nơi duy nhất có mặt API, tức thứ nhận dữ liệu từ ngoài vào. Chạy cả
    trên `.cpp` thì regex bắt nhầm **danh sách khởi tạo constructor** (`_hasLast(false)`) và
    **nơi gọi hàm** (`keystrokesInWindow(nowMs)`) vì chúng cũng có dạng `ten(...)` — đã thử, đỏ
    oan 3 chỗ. `.cpp` vẫn được lưới BANNED_ANYWHERE quét.
    """
    problems = []
    if not path.endswith(HEADER_EXTS):
        return problems

    # Khớp cả tên thường LẪN toán tử ký hiệu. Bản trước chỉ có `[A-Za-z_]\w*`, nên
    # `void operator<<(const uint32_t*)` KHÔNG khớp gì cả (ngay trước `(` là `<<`) và cả danh
    # sách tham số đi lọt. Cùng lỗ đó áp cho `operator()`, `operator+=`, `operator[]`.
    for m in re.finditer(r"(operator\s*[^\s(]+|\b[A-Za-z_]\w*)\s*\(([^;{)]*)\)", code):
        fname = m.group(1).strip()
        params = m.group(2)
        if fname in CONTROL_KEYWORDS:
            continue
        line = code[: m.start()].count("\n") + 1

        for raw in params.split(","):
            p = raw.strip()
            if not p:
                continue
            if "*" in p or "&" in p or "[" in p:
                problems.append((line, fname, p,
                                 "con trỏ / tham chiếu / mảng — API này chỉ nhận số vô hướng"))
                continue
            # Cắt giá trị mặc định trước khi tách token: với `bool on = true` thì `true` không
            # phải kiểu, mà token cuối bị coi là TÊN nên `on` bị đẩy vào ô "kiểu" → đỏ oan.
            p = p.split("=", 1)[0].strip()
            toks = [t for t in re.findall(r"[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*", p) if t != "const"]
            if not toks:
                continue
            # Token cuối là TÊN tham số; mọi token trước nó là KIỂU.
            type_toks = toks[:-1] if len(toks) > 1 else toks
            for t in type_toks:
                if t not in ALLOWED_PARAM_TYPES:
                    problems.append((line, fname, p,
                                     "kiểu `%s` không nằm trong allowlist %s"
                                     % (t, sorted(ALLOWED_PARAM_TYPES))))
    return problems


def collect_files():
    """Mọi file nguồn trong core/mood/ **và thư mục con**, TRỪ danh sách miễn trừ.

    Dùng os.walk chứ KHÔNG os.listdir, và một bộ đuôi rộng chứ không chỉ `.h`/`.cpp` — bản trước
    chỉ quét top-level với đúng hai đuôi đó, nên `core/mood/tap/ContentTap.h` và
    `core/mood/ContentTap.hpp` đều **vô hình** với cổng. Cả hai đều là đường include hoàn toàn
    hợp lệ.
    """
    found = []
    for root, _dirs, names in os.walk(MOOD_DIR):
        for name in sorted(names):
            if not name.endswith(SOURCE_EXTS):
                continue
            rel = os.path.join(root, name).replace("\\", "/")
            if rel in LEGACY_EXEMPT:
                continue
            found.append(rel)
    return sorted(found)


def declaration_surface(path, code):
    """Mọi dòng KHAI BÁO trong một header, đã chuẩn hoá khoảng trắng.

    Đây là thứ được đem so với bản ghim. Gồm cả **biến thành viên** chứ không riêng hàm: một
    `int _typed[4096];` cũng là chỗ chứa nội dung.
    """
    if not path.endswith(HEADER_EXTS):
        return []
    out = []
    for raw in code.splitlines():
        t = " ".join(raw.split())
        if not t or t.startswith("#"):
            continue
        if t in ("{", "}", "};", "public:", "private:", "protected:"):
            continue
        if "(" in t or t.endswith(";"):
            out.append(path + " :: " + t)
    return out


def read_pin():
    if not os.path.exists(PIN_FILE):
        return None
    lines = []
    with open(PIN_FILE, encoding="utf-8") as fh:
        for raw in fh:
            t = raw.rstrip("\n")
            if t.strip() and not t.startswith("#"):
                lines.append(t)
    return lines


def main():
    if not os.path.isdir(MOOD_DIR):
        print("::error::Cổng HĐ-1: không thấy thư mục %s — cổng không soi được gì." % MOOD_DIR)
        return 1

    missing = [f for f in REQUIRED if not os.path.exists(f)]
    if missing:
        print("::error::Cổng HĐ-1: thiếu file bắt buộc %s. Đổi tên/gỡ file thì phải sửa "
              "REQUIRED trong scripts/check_hd1.py — đừng để cổng im lặng không soi gì."
              % ", ".join(missing))
        return 1

    # Miễn trừ đã cạn thì phải dọn, không để danh sách mục ruỗng. Khi #13 gỡ xong lớp đọc cảm
    # xúc, bước này sẽ đỏ đúng một lần để nhắc xoá dòng tương ứng.
    stale = sorted(p for p in LEGACY_EXEMPT if not os.path.exists(p))
    if stale:
        print("::error::Cổng HĐ-1: LEGACY_EXEMPT còn trỏ tới file không còn tồn tại: %s. "
              "Gỡ khỏi scripts/check_hd1.py — danh sách miễn trừ phải co lại theo #12/#13."
              % ", ".join(stale))
        return 1

    files = collect_files()

    # ── Lưới THỨ BA: bản ghim bề mặt khai báo ────────────────────────────────────────────────
    # Allowlist kiểu chỉ chứng minh "không có kiểu HÌNH DẠNG CHUỖI", KHÔNG chứng minh "không nội
    # dung nào vào": `void noteChar(int codePoint)` đi qua allowlist XANH, mà `int` thừa sức chở
    # một codepoint Unicode. Ghim chữ ký đóng đường đó — thêm BẤT KỲ tham số nào, kiểu gì, hay
    # thêm một biến thành viên, cũng phải sửa bản ghim: một hành vi hiện rõ trong diff.
    surface = []
    for path in files:
        with open(path, encoding="utf-8") as fh:
            surface.extend(declaration_surface(path, strip_comments(fh.read())))

    if "--update-pin" in sys.argv:
        with open(PIN_FILE, encoding="utf-8") as fh:
            head = [l for l in fh.read().splitlines() if l.startswith("#") or not l.strip()]
        with open(PIN_FILE, "w", encoding="utf-8", newline="\n") as fh:
            fh.write("\n".join(head).rstrip("\n") + "\n\n" + "\n".join(surface) + "\n")
        print("Đã ghim lại %d dòng khai báo vào %s. ĐỌC KỸ DIFF trước khi commit." %
              (len(surface), PIN_FILE))
        return 0

    pinned = read_pin()
    failed = False
    if pinned is None:
        print("::error::Cổng HĐ-1: thiếu %s — không có gì để đối chiếu." % PIN_FILE)
        failed = True
    else:
        added = [s for s in surface if s not in pinned]
        removed = [s for s in pinned if s not in surface]
        for s in added:
            print("::error::HĐ-1: khai báo MỚI chưa được ghim — `%s`. API lớp nhịp gõ là hợp đồng "
                  "đóng băng (HĐ-3). Nếu đổi có chủ đích: chạy `python3 scripts/check_hd1.py "
                  "--update-pin` rồi giải trình trong PR." % s)
            failed = True
        for s in removed:
            print("::error::HĐ-1: khai báo đã ghim nay BIẾN MẤT — `%s`. Gỡ API cũng phải cập nhật "
                  "bản ghim: `python3 scripts/check_hd1.py --update-pin`." % s)
            failed = True

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

    print("OK — HĐ-1 sạch: soi %d file trong %s (miễn trừ %d file mô hình cũ) · "
          "%d dòng khai báo khớp bản ghim · mọi tham số đều là số vô hướng."
          % (len(files), MOOD_DIR, len(LEGACY_EXEMPT), len(surface)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
