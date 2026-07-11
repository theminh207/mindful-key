# 07 — Non-Functional Requirements (Step 5) — Index

> **Pha 2/4 · problem-based-srs Step 5.** Thuộc tính chất lượng có tiêu chí đo được.
> **Thiết kế có chủ đích:** mỗi lằn ranh bất khả xâm phạm của hiến chương (M1–M6) đều có ít nhất
> **một NFR canh giữ** — để "đúng tinh thần" trở thành điều kiểm được, không chỉ là lời hứa. **2026-07-11.**

---

## Bảng tổng (NFR → loại → canh red-line nào → áp cho FR)

| NFR | Loại | Canh | Áp cho FR |
|---|---|---|---|
| NFR-01 | Performance | Trần RAM extension | mọi FR extension |
| NFR-02 | Performance | Độ trễ gõ | FR-A01, FR-A09 |
| NFR-03 | Security/Privacy | **M3** riêng tư | FR-A07, FR-A09, FR-A13 |
| NFR-04 | Charter | **M1** không màu cảm xúc | FR-A08 |
| NFR-05 | Charter | **M1** không gamification | FR-A11, FR-A12, FR-A13, FR-A14 |
| NFR-06 | Charter/Usability | **M2** copy quan sát + không phụ thuộc màu | FR-A04, FR-A05, FR-A08, FR-A13 |
| NFR-07 | Charter/Maintainability | **M4** core đóng băng | FR-A01, FR-A09 |
| NFR-08 | Charter/Maintainability | **M5** không vỡ macOS | mọi FR chạm `shared/` |
| NFR-09 | Accessibility | WCAG 2.1 AA | mọi FR có UI |
| NFR-10 | Compliance | Full Access minh bạch | FR-A05 |
| NFR-11 | Charter/Scope | **M6** iOS không chặn gửi tin | FR-A08 |

> ✅ **Phủ đủ red-line:** M1→NFR-04+NFR-05 · M2→NFR-06 · M3→NFR-03 · M4→NFR-07 · M5→NFR-08 · M6→NFR-11.

---

## Chi tiết NFR

### NFR-01 — Trần RAM extension · Performance
**Statement:** Keyboard extension *shall* giữ RAM runtime dưới trần jetsam (~48–60MB) trong một
phiên gõ thông thường, không bị iOS kill.
**Đo:** Xcode Debug Memory Graph / Instruments khi gõ liên tục trong Notes + Zalo.
**Ghi:** engine chỉ 198KB — rủi ro thật ở UIKit view + macro data. Giữ macro/smart-switch rỗng mặc định; UI nhẹ (không blur/ảnh nặng).

### NFR-02 — Độ trễ gõ · Performance
**Statement:** Phản hồi phím *shall* < ~80ms; model cảm xúc *shall* chạy bất đồng bộ cuối câu,
KHÔNG chen mạch gõ phím.
**Đo:** quan sát độ trễ ký tự; xác nhận `MoodBuffer`/send-risk trên hàng đợi nền.

### NFR-03 — Riêng tư on-device (canh M3) · Security
**Statement:** Hệ thống *shall* không gọi mạng với nội dung gõ; nhật ký cảm xúc *shall* mã hóa
at-rest (AES-256 + khóa Keychain) và không rời máy; App Group *shall* chỉ chứa dữ liệu vận hành
(timestamp/bool), không nội dung gõ.
**Đo:** review network calls = 0; kiểm nội dung App Group; secure field bị loại (FR-A07).

### NFR-04 — Không màu semantic cảm xúc (canh M1) · Charter
**Statement:** Không UI nào *shall* mã hóa cảm xúc bằng đèn đỏ/xanh-lá hay đổi thanh gợi ý sang
đỏ/cam để cảnh báo; lỗi hệ thống *shall* dùng `ink.primary` + copy, không tô đỏ.
**Đo:** rà mọi màn — 0 token semantic success/error kiểu web dùng cho cảm xúc.

### NFR-05 — Không gamification (canh M1) · Charter
**Statement:** Không tính năng nào *shall* có streak, điểm, huy hiệu, ví xu, đếm lượt tải, xếp
hạng, hay biểu đồ thành tích.
**Đo:** rà theme (FR-A12) + nhật ký (FR-A13) + soi lại (FR-A14) — 0 yếu tố game hóa.

### NFR-06 — Copy quan sát + nghĩa không phụ thuộc màu (canh M2) · Usability
**Statement:** Mọi copy *shall* qua bài kiểm *"mô tả hay phán xét?"* (phán xét thì bỏ); nghĩa của
trạng thái *shall* nằm ở nhãn chữ, không phụ thuộc riêng màu/hình (WCAG 1.4.1 use-of-color).
**Đo:** duyệt copy từng màn; cặp biên độ (sóng/đường phẳng) luôn kèm nhãn chữ.

### NFR-07 — core/ đóng băng (canh M4) · Maintainability
**Statement:** iOS *shall* tiêu thụ `core/` chỉ qua API sẵn có; `git diff core/` *shall* rỗng khi hoàn thành.
**Đo:** `git diff core/` = rỗng ở mọi mốc.

### NFR-08 — Không vỡ macOS (canh M5) · Maintainability
**Statement:** Mọi thay đổi `platforms/apple/shared/` *shall* chỉ THÊM file (không sửa file macOS
đang dùng); `make build` macOS *shall* vẫn xanh sau đó.
**Đo:** chạy `make build` macOS sau mỗi thay đổi `shared/`.

### NFR-09 — WCAG 2.1 AA · Accessibility
**Statement:** Mọi UI *shall* đạt WCAG 2.1 AA: contrast ≥ 4.5:1 (text thường)/3:1 (lớn & graphic),
VoiceOver đọc đúng thứ tự, Dynamic Type, Reduce Motion (sóng đứng yên), hit ≥ 44pt.
**Đo:** cặp màu theo `DESIGN.md §3` (đã verify contrast thật); test VoiceOver/Reduce Motion.

### NFR-10 — Full Access minh bạch · Compliance
**Statement:** Xin Full Access *shall* giải thích rõ mục đích (Apple Review 2.5.1) và luôn có lối "Để sau".
**Đo:** màn FR-A05 nêu lý do + nút "Để sau"; gõ cơ bản không đòi Full Access.

### NFR-11 — iOS không chặn gửi tin (canh M6) · Scope
**Statement:** Vỏ iOS *shall* KHÔNG chặn/nuốt hành vi gửi tin xuyên app; lớp cảm xúc chỉ biểu hiện
**ambient** (con sóng, chuông), tôn trọng giới hạn sandbox và mandate 2026-07-10.
**Đo:** không có code nuốt Enter/return theo semantic gửi; FR-A08 là "nhắc", không "chặn".

---
*Step 5 (NFR) xong. Kế tiếp: `08-traceability-matrix.md` → `validate` toàn chuỗi.*
