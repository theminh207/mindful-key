#!/usr/bin/env python3
"""Sinh bảng màu cho MỌI vỏ từ brand/tokens.json — nguồn màu DUY NHẤT.

VÌ SAO CÓ FILE NÀY (chủ dự án chốt 2026-07-17): trước đó màu tồn tại ở BỐN dạng chép tay —
tokens.json (nguồn), 9 file .colorset (macOS đọc qua NSColor colorNamed:), shared/BrandPalette.h
(iOS đọc; header của nó tự thú "rút từ BrandColors.h"), và comment hex trong BrandColors.h.
Không nơi nào sinh tự động. Vỏ Windows sắp thành bản chép thứ NĂM.

Đó đúng là mô hình đã đẻ ra bug lexicon tuần này: 2 bản chép tay trôi lệch trong 3 ngày, làm iOS
mù với câu có dấu chấm. Đổi 1 màu mà quên 1 chỗ = các vỏ hiển thị lệch nhau, im lặng.

Nay: sửa màu ở tokens.json -> chạy script này -> mọi vỏ đổi theo. CI (.github/workflows/
brand-lint.yml) chạy lại script rồi `git diff --exit-code`, nên sửa tay file sinh ra sẽ ĐỎ.

Dùng:  python3 brand/gen-palette.py [--check]
       --check = chỉ báo lệch, không ghi (dùng cho CI/local kiểm nhanh)
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOKENS = os.path.join(ROOT, "brand", "tokens.json")

BANNER = "TỰ SINH từ brand/tokens.json bởi brand/gen-palette.py — ĐỪNG SỬA TAY."

# tokens.json key -> tên .colorset mà macOS gọi qua [NSColor colorNamed:].
# CỐ Ý chỉ liệt kê 9 colorset ĐANG CÓ THẬT: `cardWhite` không có colorset (vỏ dùng màu trắng hệ
# thống), thêm mới = đẻ asset không ai gọi. Nó vẫn có #define trong header bên dưới.
COLORSET_NAMES = {
    "teal": "NOWTeal", "tealLight": "TealLight",
    "orange": "NOWOrange", "orangeLight": "OrangeLight",
    "softWhite": "SoftWhite", "charcoal": "Charcoal",
    "muted": "Muted", "divider": "Divider", "stone": "Stone",
}

# tokens.json key -> hậu tố hằng số trong header. moodScale đánh số 1..5 theo biên độ.
DEFINE_NAMES = {
    "teal": "Teal", "tealLight": "TealLight", "orange": "Orange", "orangeLight": "OrangeLight",
    "charcoal": "Charcoal", "muted": "Muted", "softWhite": "SoftWhite", "cardWhite": "CardWhite",
    "divider": "Divider", "stone": "Stone",
    "1_an": "Mood1", "2_nhe": "Mood2", "3_gon": "Mood3", "4_song": "Mood4", "5_cuon": "Mood5",
}


def load():
    d = json.load(open(TOKENS, encoding="utf-8"))
    colors = {k: v for k, v in d["color"].items() if isinstance(v, str) and v.startswith("#")}
    mood = {k: v for k, v in d["moodScale"].items() if isinstance(v, str) and v.startswith("#")}
    notes = {k: v for k, v in d.get("_notes", {}).items() if not k.startswith("_")}
    return colors, mood, notes


def defines_block(items, notes, width):
    """Cột #define căn thẳng, kèm chú thích lấy từ _notes.

    `width` truyền từ ngoài vào (không tự tính trong khối) để khối màu và khối moodScale căn
    THẲNG HÀNG VỚI NHAU — tính riêng từng khối thì tên moodScale ngắn hơn sẽ lệch cột.
    """
    rows = [(f"#define kBrandPalette{DEFINE_NAMES[k]}", f"0x{v.lstrip('#').upper()}", notes.get(k, ""))
            for k, v in items.items()]
    return "\n".join(
        f"{name.ljust(width)} {hexv}" + (f"   // {note}" if note else "")
        for name, hexv, note in rows
    )


def define_width(*groups):
    return max(len(f"#define kBrandPalette{DEFINE_NAMES[k]}") for g in groups for k in g)


def apple_header(colors, mood, notes):
    w = define_width(colors, mood)
    return f"""//
//  BrandPalette.h
//  mindful-key — shared (macOS + iOS)
//
//  {BANNER}
//
//  DATA thuần (hex, không phụ thuộc AppKit/UIKit) để mỗi vỏ tự bọc theo API màu riêng — NSColor
//  bên macOS, UIColor bên iOS — mà không lệch giá trị.
//
//  Nhận diện theo Hiến chương §2.3: đây là token thẩm mỹ trung tính (chữ, nền, CTA/nhịp thở) —
//  KHÔNG dùng bất kỳ màu nào ở đây để MÃ HOÁ trạng thái cảm xúc (đèn đỏ/xanh).

#ifndef BrandPalette_h
#define BrandPalette_h

{defines_block(colors, notes, w)}

// Thang "mặt hồ tâm" — biên độ sóng LÀ tín hiệu, màu chỉ là sắc độ trung tính đậm dần theo biên
// độ (KHÔNG đỏ/xanh-lá valence, KHÔNG chấm điểm — hiến chương §2.3).
{defines_block(mood, notes, w)}

#endif /* BrandPalette_h */
"""


def windows_header(colors, mood, notes):
    w = define_width(colors, mood)
    return f"""//
//  BrandPalette.h
//  mindful-key — vỏ Windows (Win32)
//
//  {BANNER}
//
//  Cùng giá trị hex với platforms/apple/shared/BrandPalette.h vì cùng sinh từ brand/tokens.json —
//  đó là điểm của việc sinh tự động: 3 vỏ không thể trôi lệch màu.
//
//  Nhận diện theo Hiến chương §2.3: token thẩm mỹ trung tính — KHÔNG dùng màu nào ở đây để MÃ HOÁ
//  trạng thái cảm xúc (đèn đỏ/xanh). Biên độ sóng mới là tín hiệu.

#ifndef BrandPalette_h
#define BrandPalette_h

// BẪY BYTE-ORDER: hex dưới đây là 0xRRGGBB (đọc như người). GDI của Win32 lại dùng COLORREF =
// 0x00BBGGRR — ĐẢO NGƯỢC. Truyền thẳng hằng số vào hàm nhận COLORREF là ra sai màu mà vẫn build
// sạch (teal #1D7C91 hoá thành #917C1D — cam đất). LUÔN đi qua 2 macro dưới.
#define MK_COLORREF(hex)  RGB((((hex) >> 16) & 0xFF), (((hex) >> 8) & 0xFF), ((hex) & 0xFF))
#define MK_ARGB(hex)      ((Gdiplus::ARGB)(0xFF000000 | (hex)))   // GDI+ dùng 0xAARRGGBB, đục

{defines_block(colors, notes, w)}

// Thang "mặt hồ tâm" — biên độ sóng LÀ tín hiệu, màu chỉ là sắc độ trung tính đậm dần theo biên
// độ (KHÔNG đỏ/xanh-lá valence, KHÔNG chấm điểm — hiến chương §2.3).
{defines_block(mood, notes, w)}

#endif /* BrandPalette_h */
"""


def colorset_json(hexv):
    h = hexv.lstrip("#")
    return json.dumps({
        "colors": [{
            "color": {
                "color-space": "srgb",
                "components": {
                    "alpha": "1.000",
                    "blue": f"0x{h[4:6].upper()}",
                    "green": f"0x{h[2:4].upper()}",
                    "red": f"0x{h[0:2].upper()}",
                },
            },
            "idiom": "universal",
        }],
        "info": {"author": "xcode", "version": 1},
    }, indent=2, separators=(",", " : "), ensure_ascii=False) + "\n"


def targets():
    colors, mood, notes = load()
    out = {
        os.path.join(ROOT, "platforms/apple/shared/BrandPalette.h"): apple_header(colors, mood, notes),
        os.path.join(ROOT, "platforms/windows/win32/OpenKey/OpenKey/BrandPalette.h"): windows_header(colors, mood, notes),
    }
    for key, name in COLORSET_NAMES.items():
        p = os.path.join(ROOT, "platforms/apple/Resources/Assets.xcassets", f"{name}.colorset", "Contents.json")
        out[p] = colorset_json(colors[key])
    return out


def main():
    check = "--check" in sys.argv
    stale = []
    for path, text in targets().items():
        cur = open(path, encoding="utf-8").read() if os.path.exists(path) else None
        if cur == text:
            continue
        stale.append(os.path.relpath(path, ROOT))
        if not check:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, "w", encoding="utf-8").write(text)

    if check and stale:
        print("❌ Bảng màu LỆCH brand/tokens.json — chạy `make brand-palette` rồi commit:")
        for s in stale:
            print(f"   - {s}")
        return 1
    if check:
        print("✅ Bảng màu khớp brand/tokens.json.")
        return 0
    print(f"✅ Sinh xong từ brand/tokens.json — {len(stale)} file đổi." if stale
          else "✅ Đã khớp sẵn, không file nào phải ghi lại.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
