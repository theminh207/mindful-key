# Technical Specification — iOS Round 2 (lõi Laban + lớp cảm xúc)

**Date:** 2026-07-13 · **Track:** Quick Flow (mở rộng) · **Status:** draft — 4 quyết định nhận diện đã chốt (Q1/Q2/Q3/Q11), sẵn sàng shard.
**Nguồn:** `analysis/ROADMAP.md` (R2), `analysis/07-functional-requirements/_index.md` (FR-A08/A09/A10/A11/A15a), `EXPERIENCE.md` Future B1, `MOBILE-UX-ANALYSIS.md` §3.2, `decision-log.md` (2026-07-13), tiền lệ macOS `BellMac`/`NudgeCoordinator`/`MoodWatchMac`.

> ⚖️ Hiến chương tối cao. R2 chạm nhận diện → mọi UI qua bài kiểm "mô tả không phán xét";
> KHÔNG màu đỏ/xanh valence, KHÔNG gamify. `core/` ĐÓNG BĂNG (`git diff core/` rỗng).

---

## Quyết định nhận diện đã chốt (2026-07-13 — bake vào mọi story Track B)
- **Q1 (biên độ sóng):** ngưỡng chết + dâng mượt. `send-risk < ~0.3` → biên độ 0 (mặt hồ phẳng). Trên ngưỡng → biên độ dâng **mượt** (hàm liên tục, không bậc thang) tới max ở risk=1.
- **Q2 (câu quan sát):** CHỈ con sóng, KHÔNG chữ. Không hiện câu quan sát nào.
- **Q3 (chuông):** chuông **nhắc nghỉ sau N câu căng liên tiếp** (mô hình `NudgeCoordinator` macOS + cooldown), KHÔNG phải âm-khi-gõ. Tùy chọn bật/tắt.
- **Q11 (model):** lexicon on-device trước (PhoBERT sau). Nhẹ RAM.
- **Còn mở (không chặn):** Q10b glyph/wordmark/giọng copy — placeholder đang chạy.

---

## ⚠️ Dependency đã VERIFY (2026-07-13) + quyết định kiến trúc
**Đã kiểm code thật:** `core/mood/MoodBuffer.h` tự ghi *"platform-neutral; Win/macOS shells decide
how to analyze"* → `MoodBuffer` CHỈ gom từ→câu, KHÔNG tính risk. Lexicon `send-risk` nằm ở
**`platforms/apple/macos/MoodWatchMac.mm` (vỏ macOS)**, KHÔNG ở `core/`. `core/mood/BreathingPause`
chỉ NHẬN `sendRisk` (double) từ vỏ, không tự tính.

**Hệ quả:** iOS không thể mượn qua `core/` (không có ở đó + `core/` đóng băng với iOS).

**Quyết định (khuyến nghị B — cần chủ dự án xác nhận vì chạm cột trụ "1 bộ não"):**
- **B (khuyến nghị):** iOS implement analyzer lexicon ở **`platforms/apple/shared/`**, TÁI DÙNG
  bảng lexicon rút từ `MoodWatchMac.mm` (không viết từ đầu). iOS unblocked, KHÔNG đụng `core/`.
  Chấp nhận tạm 2 bản (macOS + Apple-shared) → **ghi FRICTION-LOG: hợp nhất analyzer vào `core/mood`
  sau (việc đội core)** để đúng "1 bộ não". Bảng lexicon là DỮ LIỆU thuần, tách được.
- A (proper nhưng chậm): đội core đưa analyzer vào `core/mood` (C++ chung) → iOS gọi qua bridge như
  engine. Đúng "1 bộ não" nhất nhưng cross-team + re-wire macOS, ngoài phạm vi iOS R2.
- C (rẻ nhất): lexicon tối giản riêng iOS (`platforms/apple/ios/`) cho R2 MVP — rủi ro lệch macOS.

Story 2.2 dùng **B** trừ khi chủ dự án đổi.

---

## 🟢 TRACK A — Nền kỹ thuật (làm ngay, giao Sonnet + Opus review nhẹ)

### Story 2.1 — Lõi bàn phím đầy đủ + thanh gợi ý (surface cho sóng)
- **Intent:** VNI toggle (Telex/VNI), gợi ý từ + sửa lỗi (engine đã có), và **dựng thanh gợi ý ~40pt phía trên hàng phím** — hiện TRỐNG ở story này, là bề mặt để story 2.5 thả con sóng vào.
- **AC seed:** đổi Telex↔VNI (config engine `vInputType`); thanh gợi ý hiển thị (trống/gợi ý từ), không đẩy vỡ layout bàn phím (giữ ≤ trần RAM); qua bridge, `git diff core/` rỗng.
- **Owned:** `platforms/apple/ios/KeyboardExtension/KeyboardViewController.mm` (+ file suggestion-bar view mới). **Model:** Sonnet.

### Story 2.2 — MoodBridge: gom câu → tính send-risk (TÍNH, chưa render)
- **Intent:** set `vOnWordCommitted` → `core/mood` `MoodBuffer` gom từ→câu → tính `send-risk 0..1` **on-device, lexicon, bất đồng bộ cuối câu (debounce), bỏ qua ô mật khẩu** (`mk_isSecureField`, story 1.4). Phơi ra giá trị risk cho story 2.5/2.6 tiêu thụ. **Chưa hiển thị gì.**
- **AC seed:** giải dependency ở trên trước; `vOnWordCommitted` chạy async không tăng độ trễ gõ (NFR-02); chỉ khi bộ gõ bật + tiếng Việt + không secure field; risk expose qua callback/property; `git diff core/` rỗng.
- **Owned:** `platforms/apple/ios/KeyboardExtension/*` (MoodBridge mới) + có thể `platforms/apple/shared/` (nếu lexicon phải để shared). **Model:** Sonnet, **Opus review** (chạm riêng tư + async correctness).

### Story 2.3 — Cài đặt + preview sống + slider
- **Intent:** màn Cài đặt bàn phím: segmented Telex/VNI, slider chiều cao, preview bàn phím cập nhật realtime (kế thừa Laban, bỏ game hóa).
- **AC seed:** chỉnh → preview đổi ngay; segmented chọn = teal (không xanh hệ thống); đọc/ghi App Group; a11y.
- **Owned:** `platforms/apple/ios/App/**` (màn Settings mới). **Model:** Sonnet.

### Story 2.4 — Gõ tắt (macro chữ, FR-A15a)
- **Intent:** người dùng định nghĩa gõ tắt (`vn`→`Việt Nam`), engine `Macro.cpp` bung. Màn quản lý macro trong container.
- **AC seed:** thêm/sửa/xóa macro; bung đúng khi gõ; lưu App Group; giữ macro rỗng mặc định (RAM).
- **Owned:** `platforms/apple/ios/App/**` + KeyboardExtension (wire `initMacroMap`). **Model:** Sonnet.

## 🔴 TRACK B — Nhận diện (quyết định đã có → code được; Opus review kỹ)

### Story 2.5 — Con sóng `~` ambient trên thanh gợi ý (FR-A08)
- **Intent:** thả con sóng vào thanh gợi ý (story 2.1) biến hình theo `send-risk` (story 2.2) theo **Q1**: biên độ 0 dưới ~0.3, dâng mượt trên đó. **Q2: không chữ.** Màu teal trung tính, KHÔNG đỏ/cam cảnh báo (NFR-04/11). Reduce Motion → sóng đứng yên ở biên độ tương ứng. Ambient, KHÔNG chặn gì.
- **AC seed:** biên độ khớp đường cong Q1 (test vài mốc risk); Reduce Motion tôn trọng; secure field → không sóng; cần Full Access, không có thì thanh ở trạng thái R1; qua bài kiểm "mô tả không phán xét".
- **Owned:** suggestion-bar view (từ 2.1) + wiring risk (từ 2.2). **Model:** Sonnet viết, **Opus review nhận diện trước commit.**

### Story 2.6 — Chuông nhắc nghỉ (FR-A10)
- **Intent:** theo **Q3**: đếm "N câu căng liên tiếp" (send-risk cao streak, ngưỡng như macOS), rung/âm nhẹ + **cooldown** chống dồn dập; tùy chọn bật/tắt + "tạm hoãn" trong Cài đặt. Không phần thưởng/không gamify.
- **AC seed:** kêu sau N câu căng liên tiếp (không phải mỗi câu); cooldown; tắt được; không dồn dập; copy quan sát.
- **Owned:** KeyboardExtension/App (NudgeCoordinator-iOS mới) + Settings. **Model:** Sonnet viết, **Opus review.**

---

## Thứ tự (chuỗi phụ thuộc)
```
2.1 (surface) ─┬─▶ 2.5 (sóng, cần 2.1 + 2.2)
2.2 (risk) ────┘
2.2 ──────────────▶ 2.6 (chuông, cần risk streak)
2.3 (settings) ───▶ (2.5/2.6 gắn toggle vào đây)
2.4 (macro) — độc lập
```
Track A (2.1→2.4) làm trước/song song → khi xong, Track B (2.5/2.6) thả vào bề mặt sẵn sàng.

## Định nghĩa HOÀN THÀNH R2 (SC2)
- Gõ câu căng → con sóng gợn (biên độ theo Q1); gõ câu bình thường → mặt hồ phẳng.
- Chuông kêu sau N câu căng liên tiếp, tắt/hoãn được.
- `git diff core/` rỗng · `make test-*` xanh · `make build` macOS xanh · qua bài kiểm "mô tả không phán xét" mọi màn · secure field không sóng/không chuông.
- Device-manual: đo RAM với lexicon nạp (< jetsam) trên máy thật.

---
*Kế tiếp: `bmad-epics-and-stories` shard Epic 2 (6 story) → giao Sonnet cày Track A, Opus review Track B.*
