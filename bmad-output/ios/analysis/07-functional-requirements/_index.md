# 07 — Functional Requirements (Step 5 · HOW) — Index

> **Pha 2/4 · problem-based-srs Step 5.** Cú pháp: `The [System] shall [Verb] [Object]
> [Constraint] [Condition]`. Ưu tiên MoSCoW. **2026-07-11.**
>
> **Thích ứng định dạng:** skill gốc khuyên mỗi FR 1 file. Đây là **artifact phân tích** (không
> phải spec dev cuối — dev spec do BMAD `tech-spec.md` sở hữu), nên gộp FR thành các mục trong
> index này để dễ quét + giữ traceability. Khi hand-off dev có thể chẻ ra `FR-Ax.md` riêng.
>
> **Không gian số riêng `FR-Ax`** để không đụng `FR-001..005` của `tech-spec.md`. Cột "BMAD" map
> quan hệ: *=* trùng, *⊃* mở rộng, *mới* = chưa có trong tech-spec.

---

## Bảng tổng (FR → CN → nhóm → ưu tiên → BMAD → trạng thái)

| FR | Tên | ← CN | Nhóm | MoSCoW | BMAD | Trạng thái |
|---|---|---|---|---|---|---|
| FR-A01 | Gõ Telex/VNI ra dấu qua engine | CN-01 | F1 | Must | ⊃ FR-002 | 🟡 Mốc B chưa |
| FR-A02 | Điều khiển Shift/số/xóa/đổi bàn phím | CN-02 | F1 | Must | mới | 🟡 một phần |
| FR-A03 | Target iOS build từ project.yml chung | (nền F1) | F1 | Must | = FR-001 | ✅ có (verify generate) |
| FR-A04 | Onboarding kích hoạt bàn phím | CN-03 | F2 | Must | ⊃ FR-003 | ⬜ chưa |
| FR-A05 | Minh bạch Full Access + "Để sau" | CN-04 | F2 | Must | ⊃ FR-003 | ⬜ chưa |
| FR-A06 | App Group heartbeat detection | CN-05 | F2 | Should | = FR-004 | ⬜ chưa |
| FR-A07 | Loại ô mật khẩu + không log nội dung | CN-06 | F3 | Must | mới | ⬜ chưa |
| FR-A08 | Con sóng `~` ambient theo biên độ | CN-07 | F4 | Must(R2) | mới | ⬜ chưa |
| FR-A09 | MoodBridge gom câu → send-risk on-device | CN-07 | F4 | Must(R2) | mới | ⬜ chưa |
| FR-A10 | Tiếng chuông chánh niệm tùy chọn | CN-08 | F5 | Should | mới | ⬜ chưa |
| FR-A11 | Cài đặt + preview sống + slider | CN-09 | F6 | Should | mới | ⬜ chưa |
| FR-A12 | Theme trung tính (bỏ game hóa) | CN-09 | F6 | Could | mới | ⬜ chưa |
| FR-A13 | Nhật ký on-device mã hóa + câu phản chiếu | CN-10 | F7 | Should | mới | ⬜ chưa |
| FR-A14 | Soi lại cuối ngày | CN-11 | F7 | Could | mới | ⬜ chưa |
| FR-A15a | Gõ tắt (macro chữ) | CN-12 | F1/F6 | Should | mới | ⬜ Round 2 |
| FR-A15b | Vuốt phím (swipe-typing) | CN-12 | F8 | Won't (đợt này) | mới | ⬜ Round 4 |
| FR-A16 | Sync theme opt-in | CN-13 | F8 | Won't (đợt này) | mới | ⬜ hoãn |
| FR-A17 | `tests/ios` test thật (bridge + smoke) | CN-01(verify) | F1 | Must | = FR-005 | 🟡 no-op |

---

## Chi tiết FR

### FR-A01 — Gõ Telex/VNI ra dấu qua engine · Must · ←CN-01 · ⊃tech-spec FR-002
**Statement:** Hệ thống *shall* chuyển mỗi lần chạm phím thành lời gọi `vKeyHandleEvent()` và chèn
ký tự kết quả qua `UITextDocumentProxy`, cho ra tiếng Việt có dấu, trong mọi app host.
**AC:** ☐ "vieetj"→"việt" trong Notes · ☐ y hệt trong Zalo · ☐ `git diff core/` rỗng · ☐ thay
`insertText:letter` thô hiện tại (Mốc A) bằng đường qua bridge.

### FR-A02 — Điều khiển bàn phím · Must · ←CN-02
**Statement:** Hệ thống *shall* hỗ trợ Shift (một lần) / Caps (khóa), lớp số & ký hiệu, xóa lùi
(giữ để xóa nhanh), và nút đổi bàn phím 🌐.
**AC:** ☐ Shift một lần tự về sau 1 ký tự · ☐ double-tap = Caps · ☐ 123↔ABC đổi lớp · ☐ hit ≥44pt.

### FR-A03 — Target iOS build được · Must · ⊃ nền F1 · =tech-spec FR-001
**Statement:** Hệ thống *shall* build cả container app lẫn keyboard extension từ một
`project.yml` chung qua `xcodegen generate` + `xcodebuild`, không tạo `.xcodeproj` tay.
**AC:** ☐ `xcodegen generate` sạch, đủ scheme 2 target · ☐ target macOS vẫn build xanh · ☐ verify
`generate` thật (đóng rủi ro R5 tech-spec).

### FR-A04 — Onboarding kích hoạt · Must · ←CN-03 · ⊃tech-spec FR-003
**Statement:** Hệ thống *shall* dẫn người dùng bật bàn phím trong Cài đặt bằng bước đánh số +
nút "Mở Cài đặt" + fallback "Chưa thấy?".
**AC:** ☐ 3 bước đánh số đúng trình tự · ☐ deep link Cài đặt, hỏng thì hướng dẫn tĩnh (không tô đỏ) · ☐ giọng bình thản khi vướng.

### FR-A05 — Minh bạch Full Access · Must · ←CN-04 · ⊃tech-spec FR-003
**Statement:** Hệ thống *shall* giải thích Full Access dùng làm gì (đọc câu vừa gõ, on-device, cho
con sóng) trước khi iOS hỏi, dùng cặp biên độ, và luôn cho "Để sau".
**AC:** ☐ nêu rõ lý do · ☐ có nút "Để sau" về Home không nài · ☐ nghĩa ở nhãn chữ, không phụ thuộc màu (WCAG 1.4.1).

### FR-A06 — App Group heartbeat detection · Should · ←CN-05 · =tech-spec FR-004
**Statement:** Extension *shall* ghi timestamp heartbeat vào App Group `NSUserDefaults` mỗi khi
chạy; container *shall* đọc để hiển thị "đã kích hoạt".
**AC:** ☐ lần đầu chưa gõ → hiện hướng dẫn · ☐ sau khi gõ → "đã kích hoạt" · ☐ ghi rõ giới hạn: không phát hiện lúc TẮT.

### FR-A07 — Loại ô mật khẩu + không log nội dung · Must · ←CN-06
**Statement:** Hệ thống *shall* KHÔNG đọc/log/hiện sóng khi con trỏ ở secure text field, và KHÔNG
ghi nội dung gõ vào App Group (chỉ timestamp/bool).
**AC:** ☐ secure field: gõ chữ thường, không sóng kể cả R2 · ☐ App Group review sạch nội dung gõ · ☐ không network call.

### FR-A08 — Con sóng `~` ambient theo biên độ · Must (R2) · ←CN-07
**Statement:** Thanh gợi ý *shall* hiện con sóng `~` màu teal biến hình theo biên độ tương ứng
`send-risk`, ambient, **KHÔNG chặn**, **KHÔNG** đổi sang đỏ/cam cảnh báo.
**AC:** ☐ biên độ đổi theo send-risk (đường cong chờ Q1) · ☐ Reduce Motion → sóng đứng yên ở biên
độ đó · ☐ qua bài kiểm "mô tả không phán xét" · ☐ cần Full Access; không có thì thanh ở trạng thái R1.
**Note:** Đây là biểu hiện iOS của Feature #1 macOS — "nhắc", không "chặn" (mandate M6).

### FR-A09 — MoodBridge gom câu → send-risk · Must (R2) · ←CN-07
**Statement:** Hệ thống *shall* gọi `core/mood` `MoodBuffer` gom từ hoàn chỉnh thành câu và tính
`send-risk 0..1` on-device, **bất đồng bộ cuối câu** (debounce), không chen mạch gõ phím.
**AC:** ☐ set `vOnWordCommitted` (hiện Mốc A cố ý chưa set) · ☐ chạy async, không tăng độ trễ gõ · ☐ chỉ khi bộ gõ bật + tiếng Việt + không secure field.

### FR-A10 — Tiếng chuông chánh niệm · Should · ←CN-08
**Statement:** Hệ thống *shall* phát một tín hiệu chuông nhẹ như điểm dừng, bật/tắt được (nghĩa
cụ thể: preset âm khi gõ và/hoặc chuông nhắc nghỉ — chờ Q3).
**AC:** ☐ tùy chọn bật/tắt trong Cài đặt · ☐ không dồn dập (cooldown như `NudgeCoordinator` macOS) · ☐ không phần thưởng/không gamify.

### FR-A11 — Cài đặt + preview sống + slider · Should · ←CN-09
**Statement:** Container *shall* cho chỉnh chiều cao (slider), kiểu gõ (segmented Telex/VNI), và
hiện preview bàn phím cập nhật realtime.
**AC:** ☐ chỉnh slider → preview đổi ngay · ☐ segmented chọn = teal (KHÔNG xanh hệ thống) · ☐ đọc/ghi App Group.

### FR-A12 — Theme trung tính · Could · ←CN-09
**Statement:** Hệ thống *shall* cho chọn tông theme trong dải NOW BRAND trung tính, **không** ví
xu, **không** đếm tải, **không** đua cộng đồng.
**AC:** ☐ chỉ tông trung tính không bão hòa · ☐ không yếu tố game hóa nào · ☐ (tùy) live-preview như trình tạo theme Laban.

### FR-A13 — Nhật ký on-device mã hóa · Should · ←CN-10
**Statement:** Hệ thống *shall* lưu các khoảnh khắc cảm xúc vào nhật ký on-device mã hóa (AES +
khóa Keychain), trình bày **câu phản chiếu là trọng tâm**, số liệu là bối cảnh phụ.
**AC:** ☐ consent 1 lần (không hỏi giữa lúc căng) · ☐ có nút "Xóa tất cả" (xác nhận 2 bước, không nút đỏ) · ☐ KHÔNG biểu đồ/streak/điểm · ☐ nhật ký tuyệt đối không rời máy.

### FR-A14 — Soi lại cuối ngày · Could · ←CN-11
**Statement:** Hệ thống *shall* gợi mở một câu hỏi phản chiếu cuối ngày (màn hoặc thông báo — chờ Q6),
giọng quan sát.
**AC:** ☐ trọng tâm là câu hỏi, không con số · ☐ nếu notification: cân với "không hối thúc" · ☐ giờ cuối ngày chỉnh được.

### FR-A15a — Gõ tắt (macro chữ) · Should · Round 2 · ←CN-12
**Statement:** Hệ thống *shall* cho người dùng định nghĩa từ gõ tắt (vd `vn` → `Việt Nam`) và tự
bung khi gõ. (Tách khỏi FR-A15 cũ — chủ dự án chốt 2026-07-11: engine `core/engine/Macro.cpp` đã
có sẵn logic macro + cờ `vUseMacro`, nên đây là món RẺ, hợp mục tiêu R2 "đủ tiện như Laban".)
**AC:** ☐ 1 màn soạn/sửa danh sách từ tắt (Module 5) · ☐ danh sách đồng bộ container↔extension qua
App Group · ☐ cầu nối xử đúng nhánh `vReplaceMaro` (hiện Mốc B cố ý bỏ qua vì macro rỗng) · ☐ mặc
định danh sách RỖNG (tránh rủi ro RAM — xem tech-spec §NFR Performance).

### FR-A15b — Vuốt phím (swipe-typing) · Won't (đợt này) · Round 4 · ←CN-12
**Statement:** (Hoãn) Hệ thống *shall* hỗ trợ vuốt ngón qua các phím để nhập nguyên từ.
**AC:** — ghi để không rơi; đây là phần NẶNG (nhận diện quỹ đạo + đoán từ), đưa lại khi mở Round 4.

### FR-A16 — Sync theme opt-in · Won't (đợt này) · ←CN-13
**Statement:** (Hoãn) Hệ thống *shall* đồng bộ theme/cài đặt opt-in, **không bao giờ** sync nhật ký cảm xúc.
**AC:** — opt-in mặc định OFF khi làm.

### FR-A17 — `tests/ios` test thật · Must · ←CN-01(verify) · =tech-spec FR-005
**Statement:** Hệ thống *shall* có test bridge-layer + build-smoke, tái dùng bộ case Telex→Unicode
của `tests/core/test_engine.cpp`.
**AC:** ☐ `make test-ios` chạy test thật (không no-op) · ☐ dùng lại case có sẵn, không bịa · ☐ build-smoke extension sạch.

---
*Step 5 (FR). Kế tiếp: `07-non-functional/_index.md`.*
