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
UI_EXT = {".m", ".mm", ".swift", ".h", ".html", ".css", ".js", ".ts", ".tsx", ".kt", ".xml", ".storyboard", ".xib"}
SKIP = ("/.git/", "/DerivedData/", "/backup-original/", "/node_modules/")

def walk_ui():
    out = []
    for base in ("platforms", "site"):
        for dp, _, fs in os.walk(os.path.join(ROOT, base)):
            if any(s in dp + "/" for s in SKIP):
                continue
            for f in fs:
                if os.path.splitext(f)[1].lower() in UI_EXT:
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
        critical = bool(BRAND_CRITICAL.search(rel))
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
    files = [os.path.abspath(a) for a in sys.argv[1:]] or walk_ui()
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
