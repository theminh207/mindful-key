#!/usr/bin/env python3
"""Brand lint — ràng buộc nhận diện NOW BRAND OS (HIẾN CHƯƠNG §2.2/2.3).

Chặn CỨNG (exit 1) khi thấy trong UI/brand surfaces:
  - emoji mặt cười/mếu (chấm điểm cảm xúc)
  - từ khóa gamification (streak/badge/huy hiệu...)
  - màu đỏ/xanh-lá "đèn giao thông" mã hóa cảm xúc (trong file brand-critical)
Cảnh báo (không fail):
  - hardcode màu ngoài brand/tokens.json trong file brand-critical → nên dùng token
  - màu đỏ/xanh-lá ở file legacy (không chặn, chỉ nhắc)

Dùng:  brand_lint.py [file ...]   (không có file = quét toàn repo)
"""
import sys, os, re, json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def load_allowed():
    allowed = {"#FFFFFF", "#FFF", "#000000", "#000"}
    try:
        d = json.load(open(os.path.join(ROOT, "brand", "tokens.json")))
        for grp in ("color", "moodScale"):
            for v in d.get(grp, {}).values():
                if isinstance(v, str) and v.startswith("#"):
                    allowed.add(v.upper())
    except Exception:
        pass
    return allowed

ALLOWED = load_allowed()
FORBIDDEN_HEX = {
    "#FF0000": "đỏ", "#F00": "đỏ", "#FF3B30": "đỏ iOS", "#F44336": "đỏ", "#E53935": "đỏ",
    "#D32F2F": "đỏ", "#FF453A": "đỏ",
    "#00FF00": "xanh-lá", "#0F0": "xanh-lá", "#34C759": "xanh-lá iOS", "#4CAF50": "xanh-lá",
    "#43A047": "xanh-lá", "#388E3C": "xanh-lá", "#30D158": "xanh-lá",
}
EMOJI = re.compile("[\U0001F600-\U0001F64F☹☺]")
GAMIF = re.compile(r"\b(streak|badge|leaderboard|achievement|combo)\b|huy hiệu|bảng xếp hạng|điểm thưởng", re.I)
HEX = re.compile(r"#[0-9A-Fa-f]{6}\b|#[0-9A-Fa-f]{3}\b")
BRAND_CRITICAL = re.compile(r"(SendGatekeeper|Nudge|Bell|Reflection|MoodWatch|About|BrandColors|Onboarding|Breathing|Reflect)", re.I)
# NGUỒN DUY NHẤT cho câu hỏi "file nào là bề mặt nhận diện". `brand-guard.sh` (hook chặn agent)
# và `.githooks/pre-commit` KHÔNG được giữ danh sách riêng — chúng đưa file vào đây rồi để hàm
# is_ui_file() dưới quyết định. Trước 2026-07-17 mỗi nơi một danh sách chép tay và CẢ BA đều
# thiếu .cpp/.rc/.iss, nên toàn bộ vỏ Windows (15 file .cpp) lọt lưới dù CLAUDE.md mô tả
# brand-lint là ràng buộc CỨNG "chặn mọi tool/agent". Ba bản chép tay phải-tự-nhớ-giữ-khớp chính
# là mô hình đã đẻ ra bug lexicon (2 bản trôi lệch trong 3 ngày) — không lặp lại lần nữa.
#
# .cpp/.rc/.iss = UI vỏ Windows (dialog Win32, chuỗi hiển thị, bộ cài); UI Windows sắp viết
# (~6.000 dòng, xem docs/ROADMAP-WINDOWS.md) nằm gần hết trong .cpp. Cả 2 file .rc trong repo đã
# kiểm: UTF-8 đọc được, không phải UTF-16.
UI_EXT = {".m", ".mm", ".swift", ".h", ".cpp", ".rc", ".iss", ".svg",
          ".html", ".css", ".js", ".ts", ".tsx", ".kt", ".xml", ".storyboard", ".xib"}

def is_ui_file(path):
    return os.path.splitext(path)[1].lower() in UI_EXT
SKIP = ("/.git/", "/DerivedData/", "/backup-original/", "/node_modules/")

def walk_ui():
    out = []
    # `brand` thêm 2026-07-17: tài sản brand NGUỒN vốn nằm ngoài chính cái gác của nó — quét
    # `platforms`+`site` mà bỏ `brand` nghĩa là đèn đỏ/emoji/gamification lọt vào SVG nguồn thì
    # không ai bắt, rồi từ đó xuất thẳng ra .icns/.ico của mọi vỏ.
    # An toàn, không sinh nhiễu: dòng `not is_svg` bên dưới đã MIỄN cho .svg khỏi kiểm palette từ
    # trước, nên màu của truyền thông/wordmark/icon-nền-tảng (vốn tokens.json không có nghĩa vụ
    # phủ) không bị báo bừa. Đã thử: 46 file brand/svg -> 0 lỗi, 0 cảnh báo.
    for base in ("platforms", "site", "brand"):
        for dp, _, fs in os.walk(os.path.join(ROOT, base)):
            if any(s in dp + "/" for s in SKIP):
                continue
            for f in fs:
                if is_ui_file(f):
                    out.append(os.path.join(dp, f))
    return out

def lint(files):
    errors, warns = [], []
    for f in files:
        try:
            txt = open(f, encoding="utf-8", errors="ignore").read()
        except Exception:
            continue
        rel = os.path.relpath(f, ROOT)
        # Mọi thứ trong `brand/` là brand-critical THEO ĐỊNH NGHĨA — đó LÀ nhận diện, không phải
        # code tình cờ đụng tới nó. Không có dòng này thì `BRAND_CRITICAL` xét theo TÊN FILE, và
        # `Status.svg` (con sóng ~, dấu ấn của cả thương hiệu) không khớp tên nào -> đèn đỏ trong
        # chính nó chỉ là CẢNH BÁO và CI vẫn xanh. Đã đo: nhét #FF0000 vào Status.svg -> exit 0.
        # Ảnh hưởng DUY NHẤT là luật đỏ/xanh-lá: cảnh báo "hardcode màu" vẫn miễn cho .svg (dòng
        # dưới, `not is_svg`), nên màu truyền thông/wordmark không bị báo bừa.
        critical = bool(BRAND_CRITICAL.search(rel)) or rel.startswith("brand/")
        is_svg = f.lower().endswith(".svg")
        for i, line in enumerate(txt.splitlines(), 1):
            if EMOJI.search(line):
                errors.append((rel, i, "emoji mặt cười/mếu — chấm điểm cảm xúc (2.2)"))
            m = GAMIF.search(line)
            if m:
                errors.append((rel, i, f'gamification "{m.group().strip()}" (2.2)'))
            for h in HEX.findall(line):
                H = h.upper()
                if H in FORBIDDEN_HEX:
                    msg = f"màu {h}={FORBIDDEN_HEX[H]} mã hóa cảm xúc (2.2/2.3)"
                    (errors if critical else warns).append((rel, i, msg))
                elif critical and not is_svg and H not in ALLOWED:
                    warns.append((rel, i, f"hardcode màu {h} — nên dùng brand/tokens.json"))
    return errors, warns

def main():
    args = sys.argv[1:]
    if args:
        # Lọc ngay TẠI ĐÂY, để script gọi (hook, pre-commit) cứ ném cả nắm file vào mà không cần
        # tự biết đuôi nào là UI. CỐ Ý dùng if/else chứ KHÔNG `[...] or walk_ui()`: danh sách rỗng
        # là falsy, nên caller đưa toàn file không-UI (vd hook vừa sửa 1 file .png) sẽ âm thầm rơi
        # vào quét TOÀN REPO — chậm và sai ngữ cảnh.
        files = [os.path.abspath(a) for a in args if is_ui_file(a)]
    else:
        files = walk_ui()
    errors, warns = lint(files)
    for rel, i, msg in warns:
        print(f"⚠️  {rel}:{i} — {msg}")
    for rel, i, msg in errors:
        print(f"❌ {rel}:{i} — {msg}")
    if errors:
        print(f"\nBRAND-LINT: {len(errors)} vi phạm CỨNG. Xem docs/AGENT-BRIEF.md §2 + brand/tokens.json.")
        return 1
    print(f"✅ brand-lint OK — {len(files)} file, {len(warns)} cảnh báo.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
