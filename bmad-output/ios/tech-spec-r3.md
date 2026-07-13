# Technical Specification — iOS Round 3 (nhật ký + soi lại + theme trung tính)

**Date:** 2026-07-13 · **Track:** Quick Flow (mở rộng) · **Status:** draft — 3 quyết định nhận diện đã chốt (Q4/Q5/Q6), sẵn sàng shard.
**Nguồn:** `analysis/ROADMAP.md` (R3, FR-A12/A13/A14), `EXPERIENCE.md` Future B2/B3, `decision-log.md` (2026-07-13 R3), tiền lệ macOS `MoodStoreMac.mm` + `ReflectionScreenMac.mm`, code R2 thật (`MoodBridge`, `NudgeCoordinatorIOS`, `BellReminderSettingsBridge`).

> ⚖️ Hiến chương tối cao. R3 chạm nhận diện + dữ liệu cảm xúc → mọi UI qua bài kiểm "mô tả không
> phán xét"; KHÔNG đỏ/xanh valence, KHÔNG biểu đồ/streak/điểm, KHÔNG copy khiển trách.
> `core/` ĐÓNG BĂNG (`git diff core/` rỗng). iOS chỉ sửa `platforms/apple/ios` + `platforms/apple/shared` + `tests/ios`.

---

## Quyết định nhận diện đã chốt (2026-07-13 — bake vào mọi story R3)
- **Q4 (nhật ký hiện gì):** câu phản chiếu là trọng tâm + **bối cảnh SỐ nhỏ** (số lần "mặt hồ gợn sóng" hôm nay + giờ dễ căng nhất), cỡ nhỏ, dưới câu hỏi. KHÔNG biểu đồ/streak/điểm.
- **Q5 (soi lại):** màn trong tab "Mặt hồ" **+ 1 thông báo đẩy nhẹ cuối ngày** — MẶC ĐỊNH TẮT, opt-in, ≤1 lần/ngày, giờ chỉnh được, tắt được.
- **Q6 (theme):** **vài preset trung tính chốt sẵn** (2–4 bảng màu palette NOW BRAND), live-preview, KHÔNG cho tự chọn màu tự do.
- **Còn mở (không chặn dev):** Q10b glyph/wordmark/giọng copy chính thức — placeholder đang chạy. Full Access (FRICTION-LOG) — R3 làm nặng ký hơn, chờ chủ dự án khẳng định.

---

## ⚠️ Kiến trúc kho nhật ký đã chốt (tối thiểu hóa dữ liệu + nhẹ RAM)

**Đã kiểm code thật:**
- `MoodStoreMac.mm` = tiền lệ: AES-256-CBC (CommonCrypto, IV ngẫu nhiên gắn đầu ciphertext) + khóa 32B trong Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`), consent gate (`HasConsent`/`SetConsent`/`AskConsentIfNeeded`), `DeleteAll` xóa cả file + khóa. Schema **không có cột văn bản gốc**. Dùng SQLite (decrypt→temp→ghi→re-encrypt).
- `MoodBridge.mm` (R2) tính send-risk trên serial queue riêng `g_moodQueue`, gọi `NudgeCoordinatorIOS_RegisterSentenceRisk(risk)` **ngay trong callback, SAU cổng ô-bảo-mật** (`g_secureFieldActive` return sớm) → đây là ĐÚNG điểm cắm ghi nhật ký.
- `platforms/apple/shared/` đã có pattern bridge Foundation-only host-testable (`BellReminderSettingsBridge`, `AppGroupBridge`, `AppGroupConstants`).
- 2 entitlements (`App/MindfulKeyiOS.entitlements`, `KeyboardExtension/KeyboardExtension.entitlements`) hiện **CHỈ có App Group `group.vn.gnh.mindfulkey`**, KHÔNG có `keychain-access-groups`.

**Chốt kiến trúc (khác macOS ở 3 điểm, có lý do):**
1. **CHỈ ghi "khoảnh khắc căng"** (send-risk ≥ ngưỡng chết ~0.3, tái dùng ngưỡng Q1/`NudgeCoordinatorIOS_TenseThreshold`) — KHÔNG ghi mọi câu. Mirror mô hình "sự kiện" macOS (log lúc gác cổng, không log liên tục), tối thiểu hóa dữ liệu. Schema chỉ `{ts:int64, sendRisk:double}` — **không văn bản gốc, không app id** (iOS sandbox không biết host app).
2. **KHÔNG SQLite** — extension chật RAM (~48–60MB jetsam), tránh link `sqlite3`. Dùng **file sự kiện mã hóa gọn**: mỗi event 16 byte (8B ts + 8B risk), append theo pattern macOS (giải mã blob → append → re-encrypt → ghi đè file `.enc` trong App Group container). Dữ liệu thưa (chỉ tense-event) nên re-encrypt cả file mỗi lần chấp nhận được.
3. **Vị trí:** kho ở `platforms/apple/shared/` (compile vào CẢ 2 target). **Extension GHI** (append event), **container ĐỌC** (fetch summary hôm nay). File `.enc` trong **App Group container** (dùng `AppGroupBridge` lấy URL), khóa AES trong **Keychain chia sẻ qua keychain-access-groups**.

Story 3.1 hiện thực kiến trúc này. Nếu chủ dự án muốn giữ SQLite cho đồng nhất macOS → đổi ở 3.1 (nhưng cân nhắc RAM).

---

## 🟢 TRACK A — Nền + công cụ (Sonnet viết; 3.1 Opus review kỹ vì crypto/riêng tư)

### Story 3.1 — Kho nhật ký cảm xúc on-device mã hóa + consent (FR-A13 nền)
- **Intent:** kho `MoodJournalStore` (mới, `platforms/apple/shared/`): append tense-event `{ts, sendRisk}` mã hóa AES-256 + khóa Keychain chia sẻ; consent gate; `DeleteAll`; fetch summary hôm nay (số lần gợn + giờ đỉnh). Wire GHI vào `MoodBridge.mm` (cạnh `NudgeCoordinatorIOS`, sau cổng ô-bảo-mật, chỉ khi consent + risk ≥ ngưỡng). Thêm `keychain-access-groups` vào 2 entitlements.
- **AC seed:** file trên đĩa CHỈ tồn tại dạng mã hóa (verify byte không đọc được plaintext); schema không có trường văn bản; không consent → không tạo file/không ghi; ô bảo mật → không ghi (thừa hưởng return sớm MoodBridge); `DeleteAll` xóa file + khóa; extension ghi ↔ container đọc cùng 1 file qua App Group; `git diff core/` rỗng.
- **Owned:** `platforms/apple/shared/MoodJournalStore.{h,mm}` (mới) · `platforms/apple/ios/KeyboardExtension/MoodBridge.mm` (thêm 1 call ghi) · 2 file `.entitlements` (thêm keychain group) · `tests/ios/mood_journal_store_test.mm` + build script (mới) · `Makefile` test-ios (thêm dòng). **Model:** Sonnet viết, **Opus review** (crypto + riêng tư + async).

### Story 3.2 — Theme preset trung tính + live preview (FR-A12)
- **Intent:** màn "Giao diện" trong Cài đặt container: 2–4 preset trung tính (palette NOW BRAND — vd "Hồ sáng"/"Hồ tối"/"Sương"), live-preview bàn phím, lưu lựa chọn qua App Group; extension đọc preset để tô nền/phím. KHÔNG color picker tự do. KHÔNG game hóa.
- **AC seed:** chọn preset → preview đổi ngay + persist App Group; extension áp đúng preset khi mở; mọi preset trung tính (không đỏ/xanh valence, qua brand-lint); segmented chọn = teal; a11y (contrast ≥ chuẩn DESIGN §3, VoiceOver nhãn).
- **Owned:** `platforms/apple/ios/App/**` (màn Giao diện) · `platforms/apple/shared/ThemeBridge.{h,mm}` (mới, đọc/ghi preset qua App Group) · `platforms/apple/ios/KeyboardExtension/KeyboardViewController.mm` (áp preset). **Model:** Sonnet.

## 🔴 TRACK B — Nhận diện (quyết định đã có → code được; Opus review kỹ)

### Story 3.3 — Màn soi lại cuối ngày trong tab "Mặt hồ" (FR-A14 màn)
- **Intent:** màn soi lại (tab "Mặt hồ", container): **câu hỏi phản chiếu là trọng tâm** (random 1 câu như `ReflectionScreenMac` `ReflectivePrompts`) + chip trả lời nhẹ ("Có, vài lần"/"Một chút"/"Khá lặng") + **bối cảnh số nhỏ (Q4):** số lần gợn sóng hôm nay + giờ dễ căng (đọc `MoodJournalStore` fetch summary) + câu quan sát + ghi chú "mọi ghi nhận ở lại trên máy này". Nếu chưa consent → trạng thái "chưa có gì để soi lại" (như macOS). Nền sóng ambient nhẹ (tái dùng `EmotionWaveAmplitude`), KHÔNG chart.
- **AC seed:** câu hỏi là phần nổi bật nhất (hierarchy); số liệu cỡ nhỏ, phụ; KHÔNG biểu đồ/timeline/streak/điểm; chưa consent → mời bật, không ép; Reduce Motion → sóng đứng yên; qua bài kiểm "mô tả không phán xét".
- **Owned:** `platforms/apple/ios/App/**` (VC tab Mặt hồ + soi lại). **Model:** Sonnet viết, **Opus review nhận diện trước commit.**

### Story 3.4 — Thông báo nhắc soi lại cuối ngày (opt-in, FR-A14 notification)
- **Intent:** theo **Q5** + rào FRICTION-LOG 2026-07-13: local notification (`UNUserNotificationCenter`) cuối ngày mời soi lại — **MẶC ĐỊNH TẮT**, toggle opt-in trong Cài đặt, ≤1 lần/ngày, giờ chỉnh được, tắt hủy lịch; chạm mở tab "Mặt hồ". Copy quan sát, không phán xét, CẤM "bạn bỏ lỡ N ngày"/đếm chuỗi.
- **AC seed:** mặc định TẮT (không xin quyền notification tới khi user bật); bật → xin quyền + đặt lịch đúng giờ; tắt → hủy hết pending; tối đa 1/ngày; đổi giờ → dời lịch; copy qua bài kiểm phán xét; chạm notification mở đúng màn soi lại.
- **Owned:** `platforms/apple/ios/App/**` (NotificationScheduler + toggle Cài đặt) · `platforms/apple/shared/` (khóa settings giờ + on/off, mở rộng pattern `BellReminderSettingsBridge`). **Model:** Sonnet viết, **Opus review** (nới lỏng mandate "thụ động").

---

## Thứ tự (chuỗi phụ thuộc)
```
3.1 (kho + consent) ──▶ 3.3 (soi lại, đọc summary) ──▶ 3.4 (notification mở màn soi lại)
3.2 (theme) — độc lập, song song
```
Track A 3.1 làm TRƯỚC (nền cho soi lại) — Opus review xong mới sang 3.3. 3.2 chạy song song bất cứ lúc nào.

## Định nghĩa HOÀN THÀNH R3 (SC3)
- Gõ vài câu căng → kho ghi tense-event mã hóa (verify file không đọc được plaintext, không văn bản gốc).
- Mở tab "Mặt hồ" → câu phản chiếu nổi bật + số liệu nhỏ phụ; chưa consent → mời bật không ép.
- Nút "Xóa tất cả" 2 bước (không nút đỏ) hoạt động; tắt consent → xóa sạch.
- Theme: đổi preset → bàn phím đổi ngay, mọi preset trung tính (qua brand-lint).
- Notification mặc định TẮT; bật thì đúng rào (1/ngày, tắt được, copy không phán xét).
- `git diff core/` rỗng · `make test-core` + `make test-ios` xanh · `make build` macOS xanh · `make brand-lint` 0 vi phạm · qua bài kiểm "mô tả không phán xét" mọi màn.
- Device-manual (device-only, ngoài CI): đo RAM extension với kho nạp (< jetsam) trên iPhone thật.

---
*Kế tiếp: shard Epic 3 (4 story) → giao Sonnet cày Track A (3.1 → Opus review → 3.2), rồi Track B (3.3/3.4) Opus review nhận diện. Sau khi chốt UI, chạy lại `bmad-ux` (Update) nâng B2/B3 thành screen inventory đầy đủ.*
