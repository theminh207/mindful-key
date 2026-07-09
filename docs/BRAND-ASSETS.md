# Brand Assets — NOW BRAND OS (GNH)

> Bộ nhận diện của mindful-keyboard. Sản phẩm là **cánh tay công nghệ của GNH — "Lan tỏa điều tử tế"**:
> gác cổng cảm xúc (chặn tin nhắn nóng giận trước khi gửi) = "sống tử tế ngay trên bàn phím".
> Mọi UI/agent (mood-layer, platform-shell) PHẢI theo file này — không tự chế màu.

## 1. Palette (khóa cứng)
| Vai trò | Tên | Hex |
|---|---|---|
| Thương hiệu chính (nền tin cậy, tiêu đề) | NOW Teal | `#1D7C91` |
| Teal nhạt (hover, nền phụ) | Teal Light | `#E8F2F4` |
| Điểm nhấn / CTA / **khoảnh khắc con người** | NOW Orange | `#FF7A1A` |
| Cam nhạt | Orange Light | `#FFF2E8` |
| Nền trang / Card | Soft White / White | `#F8F8F8` / `#FFFFFF` |
| Chữ chính / phụ | Charcoal / Muted | `#2A2A2A` / `#666666` |

**Quy tắc màu:** cam CHỈ dùng cho điểm nhấn/CTA và "khoảnh khắc con người" (hơi thở, cảnh báo, chuông đang mời). Ngọc bích là nền mặc định. **Không dùng đỏ, không xanh-lá, không mặt cười/mếu.**

- Font: **Montserrat** (heading, đậm/uppercase) + **Inter** (body).
  > TODO (chưa làm): chưa bundle file `.ttf`/giấy phép font vào `platforms/apple/Resources/` —
  > UI macOS hiện tại (`platforms/apple/macos/`) dùng system font mặc định (San Francisco) làm
  > fallback. Khi bundle font thật, nhớ khai báo `ATSApplicationFontsPath` trong Info.plist.
- Bo góc 16px (card/hero) · 8px (khối nhỏ). Bóng `0 8px 30px rgba(29,124,145,0.08)`. Không neon, không viền gắt.

## 2. Dấu ấn (mark)
**Dấu ngã `~` = làn thở / gợn sóng.** Vừa là dấu thanh tiếng Việt (báo "bộ gõ Việt"), vừa là làn nước lặng. Đặt trong các **vòng "lan tỏa"** (ADN mandala GNH rút gọn). Cam = hơi thở; ngọc bích = vòng lan tỏa.

## 3. Nguồn & cách tái tạo
- SVG nguồn: `brand/svg/*.svg` (một nguồn, nhiều cỡ).
- Xuất: `bash brand/export.sh` → ghi PNG/`.icns` vào `Resources/`, preview vào `brand/png/`.
  Lần chạy đầu tự backup icon gốc vào `brand/backup-original/`.
- Yêu cầu: `rsvg-convert` (`brew install librsvg`), `iconutil`, `sips`.

## 4. Bộ asset (map vào ModernKey/Resources)
| File | Cỡ | Nội dung | Trạng thái |
|---|---|---|---|
| `Icon.icns` | 16→1024 | Squircle teal + vòng lan tỏa + dấu ngã cam | ✅ đã thay |
| `Status[@2x]` | 22/44 | Dấu ngã ngọc bích — VI đang bật | ✅ đã thay |
| `StatusEng[@2x]` | 22/44 | Nét thẳng xám — bộ gõ tắt ("nín thở") | ✅ đã thay |
| `StatusHighlighted[@2x]` | 22/44 | Dấu ngã trắng — khi menu mở | ✅ đã thay |
| `StatusHighlightedEng[@2x]` | 22/44 | Nét thẳng trắng — menu mở, ENG | ✅ đã thay |
| `StatusAlert[@2x]` | 22/44 | Sóng ngọc bích **biên độ cao** (không cam) — tâm đang động | ⚠️ asset MỚI, cần wire (xem §6) |
| `OK[@2x]` | 50/100 | Dấu tick ngọc bích | ✅ đã thay |
| `ThumbUp[@2x]` | 50/100 | **Trái tim** ngọc bích (tử tế/ủng hộ — đổi ý nghĩa từ "thumbs up") | ✅ đã thay |
| `StartConvert[@2x]` | 50/100 | Tam giác play cam (hành động chính) | ✅ đã thay |
| `ExitButton[@2x]` | 50/100 | Dấu ✕ xám chì (đóng — trung tính, không đỏ) | ✅ đã thay |

Preview chưa wire (dùng cho HUD/biểu đồ, `brand/png/`): `bell-idle`, `bell-ring`, `mood-1..5`.

## 5. Thang cảm xúc — "mặt hồ tâm" (tuân HIẾN CHƯƠNG 2.3)
**Tín hiệu CHÍNH = biên độ sóng.** Màu chỉ là một thang **trung tính không bão hòa** (xanh-nước → xám-đá), đậm dần theo mức — **mô tả, không phán xét**. KHÔNG cam/đỏ/xanh-lá làm "nóng = xấu". Đổi cả hình (biên độ) để mù màu / menu bar mono vẫn đọc được.

| Mức | Tên | Màu (desaturated) | Sóng | Ý nghĩa (mô tả) |
|---|---|---|---|---|
| 1 | An | `#9FB6BC` | phẳng + ripple thưa | mặt hồ lặng — **trạng thái "nhà"**, được tôn vinh |
| 2 | Nhẹ | `#86A2AA` | gợn êm | bình thường |
| 3 | Gợn | `#6E8E97` | chớm gợn | mặt hồ chớm động |
| 4 | Sóng | `#567A84` | biên độ cao | mặt hồ đang dậy sóng — chuông có thể ngân mời |
| 5 | Cuộn | `#3F646E` | biên độ rất cao + vòng | **kích hoạt lớp nhịp thở** (gác cổng) khi đang định gửi |

> Cam `#FF7A1A` KHÔNG xuất hiện trong thang này. Cam chỉ dành cho brand chrome + CTA + khoảnh khắc "hơi thở/mời" (nút trong lớp nhịp thở, chấm "chuông đang mời"), tức khoảnh khắc *con người*, không phải mã hóa *trạng thái cảm xúc*.

## 6. Việc còn lại (wiring — thuộc platform-shell / mood-layer)
1. **StatusAlert**: `AppDelegate.m` đổi `statusItem.button.image` sang `imageNamed:@"StatusAlert"` khi MoodWatcher báo mức 4–5, rồi lắng về `Status` sau vài giây.
2. **Bell / mood glyphs**: nhúng `bell-*`, `mood-*` vào màn chuông + biểu đồ cuối ngày (mood-layer quyết định mức; vỏ chỉ hiển thị).
3. **Nâng cấp tùy chọn**: chuyển menu bar sang **template image** (đơn sắc + alpha) để OS tự tô đen/trắng theo light/dark & highlight → có thể bỏ 8 file `StatusHighlighted*`. Đổi lại mất màu ngọc bích ở menu bar. Chưa làm để giữ code hiện tại.

## 7. Bốn nguyên tắc "giữ đúng tinh thần"
1. Không đỏ, không mặt mếu — trần cảm xúc dừng ở cam ấm; luôn *mời*, không *trách*.
2. Tôn vinh cái tĩnh — hiển thị chuỗi "lặng", không chỉ đếm lần "căng".
3. Không màu đơn độc — mọi mức đổi cả hình lẫn màu.
4. On-device — thang cảm xúc chạy tại chỗ, không rời máy.
