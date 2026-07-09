# Sharding Context — Epic 1: Bảng điều khiển macOS (dùng chung cho mọi story-author)

> Mọi agent biên dịch story ĐỌC file này trước. Track: BMad Method. Sizing: ~1 dev-day/story.
> Ngôn ngữ: định danh/tên component/token = tiếng Anh; chữ hiển thị UI + văn xuôi = tiếng Việt.

## Nguồn spec (thay vai trò PRD/architecture — dự án chưa có prd.md/architecture.md)
- `bmad-output/DESIGN-macos-control-panel.md` — token, spec 7 component, WCAG (§3), ràng buộc hiến chương (§5), bản đồ component↔code (§6).
- `bmad-output/EXPERIENCE-macos-control-panel.md` — 4 journey, screen states (§3), wireframe, decision points (§4).
- `bmad-output/brainstorming-report-macos-control-panel.md` — 18 ý tưởng, risks.
- `docs/AGENT-BRIEF.md` — HIẾN CHƯƠNG bất khả xâm phạm.
- Cite theo dạng `[Source: DESIGN-macos-control-panel.md#2.1]`, `[Source: EXPERIENCE-macos-control-panel.md#3.1]`. Suy luận riêng ghi `[Inference]`.

## Code thật (Owned Scope bám theo đây)
| Vùng | File thật | Chuyên gia |
|------|-----------|-----------|
| Panel/card/wiring | `platforms/apple/macos/ViewController.m` + `platforms/apple/Resources/Base.lproj/Main.storyboard` | platform-shell |
| Brand color token có sẵn | `platforms/apple/macos/BrandColors.h/.m` | platform-shell |
| Chuông (hardcode âm ở `BellMac.mm:51`) | `platforms/apple/macos/BellMac.mm/.h` | mood-layer + platform-shell |
| Nhắc + ngưỡng câu căng | `platforms/apple/macos/NudgeCoordinatorMac.mm/.h` | mood-layer |
| Đọc biên độ cảm xúc | `platforms/apple/macos/MoodWatchMac.mm/.h` | mood-layer |
| Màn soi lại | `platforms/apple/macos/ReflectionScreenMac.mm/.h` | mood-layer |
| Glyph sóng nguồn | `brand/svg/` | brand |

## RÀNG BUỘC BẤT KHẢ XÂM PHẠM (mỗi story PHẢI nhúng vào Dev Notes + ít nhất 1 Acceptance Criterion)
1. KHÔNG đèn đỏ/xanh cảm xúc, KHÔNG mặt cười/mếu (cấm SF Symbol `face.*`, `exclamationmark.triangle`), KHÔNG emoji chấm điểm, KHÔNG gamification/progress-bar/streak cho ngưỡng-mood.
2. Trạng thái cảm xúc CHỈ = sóng `~` **1 hue đổi biên độ** (teal↔stone), mặc định **thu gọn**.
3. Cam `#FF7A1A` CHỈ dùng cho CTA + link active; **CTA dùng chữ TỐI `#2A2A2A`** (chữ trắng trượt WCAG AA = 2.61:1; chữ tối = 5.50:1 — đã verify).
4. Feature #1 (gác cổng, `SendGatekeeperMac`) luôn card **trên cùng, full-width, nổi bật nhất** — không xếp ngang hàng chuông/mood.
5. Riêng tư trong UI: KHÔNG render nội dung gõ thật, KHÔNG lịch sử chi tiết theo dòng (timestamp/tên app), KHÔNG biểu đồ theo thời gian, KHÔNG so sánh xã hội.
6. **Gate "mô tả hay phán xét?"** là 1 acceptance criterion BẮT BUỘC cho mọi story chạm copy trạng thái.
7. Giờ yên lặng thủ công; toggle đồng bộ Focus Mode mặc định OFF (opt-in có giải thích quyền).
8. NSSwitch/toggle liên quan mood override tint về **teal**, không xanh-lá hệ thống.

## Token nhanh (chi tiết ở DESIGN §1)
- teal `#1D7C91`, tealLight `#E8F2F4`, orange CTA `#FF7A1A`, bg `#F8F8F8`, card `#FFFFFF`, text `#2A2A2A`/`#666666`, stone `#8A9BA0`, divider `#E5E7E8`.
- Font: Montserrat (heading) + Inter (body). Radius: card 16px, control 8px, pill 999px. Panel rộng 360px, cuộn dọc.

## Testing strategy chung (dự án C++/ObjC, KHÔNG unit-test UI)
- `make test` (engine regression) phải XANH — chứng minh không phá bộ não dùng chung (story UI không đụng engine).
- `make build` sạch: 0 error, KHÔNG thêm warning compiler mới.
- Verify thủ công theo screen states trong EXPERIENCE §3 (default/loading/empty/error/consent/tắt).
- KHÔNG chạy test trong lúc viết story — chỉ ghi STRATEGY (đây là planning artifact).

## Owned Scope waves (chống đụng file)
- **Wave 1 (song song):** 1.1 `BrandControls.*` · 1.2 `EmotionWaveView.*` — file mới, rời hẳn.
- **Wave 2:** 1.3 (`ViewController.m`+storyboard) · 1.4 `GatekeeperCardView.*` · 1.5 `BellSettingsView.*`+`BellMac.mm`+`NudgeCoordinatorMac.mm`.
- **Wave 3:** 1.6 (`ViewController.m`+storyboard — nối tiếp sau 1.3).
- File tranh chấp DUY NHẤT: `ViewController.m` + `Main.storyboard` (1.3 → 1.6). Mọi story khác disjoint.

## Dev Agent Record: để TRỐNG (dev tool ngoài điền sau).
