# BMAD Readiness Report

**Date:** 2026-07-09
**Project:** mindful-key — Epic 1: Hiện đại hóa Bảng điều khiển macOS
**Track:** BMad Method
**Requirements doc:** _(không có PRD chính thức — dùng `DESIGN-macos-control-panel.md` + `EXPERIENCE-macos-control-panel.md` + `brainstorming-report-macos-control-panel.md` làm nguồn yêu cầu; bỏ PRD có chủ đích, ghi trong `decision-log.md`)_
**Architecture doc:** _(không có architecture.md chính thức — vai trò kiến trúc do `DESIGN §6` (bản đồ component↔code) + `context/sharding-context.md` + `decision-log.md` đảm nhận)_

---

## Verdict

**CONCERNS**

Kế hoạch **mạnh và nhất quán**: cả 3 mục tiêu, 7 component, mọi trạng thái màn hình và toàn bộ
ràng buộc hiến chương đều truy được về story + đã có Bảng Nghiệm Thu. Không có lỗ hổng chí mạng.
Xuống CONCERNS (không phải PASS sạch) vì 2 lý do có-thể-quản-lý: (1) corpus cố ý KHÔNG có PRD/
architecture chính thức — bù bằng DESIGN/EXPERIENCE, chấp nhận được cho epic UI nhỏ nhưng cần ghi
nhận; (2) có **4 điểm chưa chắc về code thật** (đã gắn cờ `[Inference]` trong story) phải xác nhận
lúc bắt tay Đợt 1/2 — đã có kế hoạch giảm thiểu, không chặn khởi công.

> **Script pre-flight báo FAIL** vì tìm đúng tên file `prd*`/`architecture*` không thấy. Verdict
> thật là **CONCERNS** sau khi chấm theo tinh thần cổng kiểm (nhất quán nội bộ + truy vết), coi
> DESIGN/EXPERIENCE là nguồn yêu cầu thay PRD — đúng quyết định đã chốt trong decision-log.

---

## Requirements Coverage

### Functional Requirements

Không có nhãn FR chính thức → coi 3 mục tiêu + spec component/journey là FR ngầm.

| Metric | Value |
|--------|-------|
| Total FRs identified | 7 |
| Covered in artifacts (explicit) | 7 |
| Implied / subject-matter coverage | 0 |
| Missing — no evidence of coverage | 0 |
| **Coverage %** (covered + implied) | **100 %** |

**Threshold:** PASS ≥ 90 % · CONCERNS 80–89 % · FAIL < 80 %

#### FR → Story map

| FR ngầm | Story phủ | Trạng thái |
|---------|-----------|-----------|
| FR-a · Panel hiện đại 1-trang thay 4-tab | 1.3 (+1.1 controls, 1.6 ráp) | Covered |
| FR-b · Chuông cấu hình được (âm/volume/độ nhạy/giờ) | 1.5 | Covered |
| FR-c · Trạng thái cảm xúc rõ (sóng, thu gọn) | 1.2, 1.4 | Covered |
| FR-d · Card gác cổng nổi bật nhất + lối tắt Soi lại | 1.4 | Covered |
| FR-e · Giữ nguyên mọi tính năng gõ OpenKey cũ | 1.3 (AC #6) | Covered |
| FR-f · Screen states (loading/empty/error/consent/off) | 1.6 | Covered |
| FR-g · Brand primitives đúng token (toggle/dot/CTA) | 1.1 | Covered |

**Missing FRs:** None — mọi mục tiêu đều có story phủ.

---

### Non-Functional Requirements

Coi các ràng buộc bất khả xâm phạm + chất lượng là NFR.

| Metric | Value |
|--------|-------|
| Total NFRs identified | 6 |
| Fully addressed | 6 |
| Partially addressed | 0 |
| Missing | 0 |
| **Coverage %** (addressed + partial) | **100 %** |

#### NFR Coverage Detail

| NFR | Status | Chiến lược | Ghi chú |
|-----|--------|-----------|---------|
| Riêng tư trong UI | Addressed | Không render chữ gõ thật/lịch sử/biểu đồ; footer cam kết; consent 1 lần | AC 1.2-7, 1.6-3/5/7, 1.3-5; test CH-9 |
| Nhận diện trung tính (hiến chương) | Addressed | Sóng 1-hue, không đèn đỏ/xanh/mặt cười/gamify | Mọi story + Cổng Hiến Chương 10 dòng |
| Accessibility (WCAG AA) | Addressed | Contrast đã verify số thật, focus 2px, keyboard, VoiceOver | DESIGN §3; AC 1.1-1, 1.2-5, 1.4-6 |
| Kỷ luật copy (mô tả không phán xét) | Addressed | Gate bắt buộc mỗi story + xác nhận Dev Agent Record | AC 1.2-6, 1.3-7, 1.4-2, 1.5-7, 1.6-7 |
| Không đụng "bộ não" engine | Addressed | Story UI không sửa core/; giữ `make test` xanh | sharding-context; Testing mỗi story |
| Feature #1 ưu tiên tuyệt đối | Addressed | Card gác cổng trên cùng, full-width, cấm ngang hàng | AC 1.4-1, 1.6-1; test CH-6 |

---

## Epic / Story Traceability

| Metric | Value |
|--------|-------|
| Total epics | 1 |
| Epics linked to a requirement | 1 |
| Orphan epics | 0 |
| Total story files found | 6 |

**Orphan Epics:** None. Epic 1 truy về 3 mục tiêu + DESIGN/EXPERIENCE. Cả 6 story ready-for-dev,
scope-conflict-check sạch (chỉ 1 overlap CÓ CHỦ ĐÍCH: 1.3↔1.6 serialize).

---

## Architecture Quality

**Score:** 90 % (9 / 10 checks)

**Threshold:** PASS ≥ 80 % · CONCERNS 70–79 % · FAIL < 70 %

| Check | Result | Ghi chú |
|-------|--------|---------|
| Architectural pattern stated | PASS | "1 bộ não + nhiều vỏ" (CLAUDE.md) + component↔code map (DESIGN §6) |
| Components / modules defined | PASS | 7 component có trách nhiệm + file sở hữu rõ (DESIGN §2) |
| API or service contracts described | PASS | Có, dạng tên hàm thật (`ReflectionScreenMac_Show`, `MoodWatchMac_LastSendRisk`, keys UserDefaults) — vài chỗ gắn cờ [Inference] cần xác nhận |
| Data model or entities specified | PASS | Keys UserDefaults liệt kê (1.5), cờ consent MoodStore (1.6) |
| Technology stack present | PASS | AppKit / Objective-C++ trên codebase sẵn |
| Technology choices justified | PASS | decision-log: CTA chữ tối (kèm số contrast), bỏ unit-test UI, Focus sync opt-in… |
| Security strategy addressed | PASS | On-device, mood store mã hoá sẵn, consent gate |
| Scalability / performance addressed | FAIL | Không nêu rõ ràng buộc "sóng chạy async, không chen mạch gõ" trong docs epic này (rủi ro thấp cho 1 panel cài đặt) |
| Trade-offs documented | PASS | decision-log: bỏ PRD/architecture/unit-test có chủ đích, serialize 1.3↔1.6 |
| Assumptions / constraints listed | PASS | sharding-context + cờ [Inference] + hiến chương |

---

## Issues Summary

### Blockers — phải xử trước khi code
**None (không có blocker chưa được giảm thiểu).** 4 điểm chưa chắc bên dưới đều đã có kế hoạch xử
(ghi trong Dev Notes story), không cái nào chặn việc bắt đầu Đợt 1.

### Concerns — mang theo khi làm story (đã nằm sẵn trong Dev Notes)
1. **API "biên độ" của EmotionWave chưa tồn tại** — `MoodWatchMac` chỉ lộ `MoodWatchMac_LastSendRisk()`
   (0–1), không có API biên độ. Story 1.2/1.4 phải xác nhận cách map risk→biên độ khi code. _(story 1.2, 1.4)_
2. **Ngưỡng "số câu căng" nằm ở `MoodWatchMac.mm:47`** (không phải BellMac như giả định đầu). Story
   1.5 dựng hạ tầng UserDefaults + getter; việc nối `MoodWatchMac` đọc getter là follow-up. _(story 1.5)_
3. **Chưa có cơ chế âm lượng thật** (`NSBeep`/`NSUserNotification` không hỗ trợ volume) → cần
   `NSSound`/`AVAudioPlayer`. _(story 1.5)_
4. **Bẫy "giờ yên lặng ngược"** — `vBellFrom`/`vBellTo` hiện nghĩa "giờ hoạt động"; map UI ngây thơ
   sẽ reo ngược. Đã có test-case TC-1.5-4 canh chỗ này. _(story 1.5)_

### Minor observations
- Không có PRD/architecture chính thức (cố ý). Nếu sau này epic phình to hoặc có người mới tham gia,
  nên cân nhắc bổ sung 1 tech-spec mỏng để họ khỏi phải đọc rải rác 3 file.
- "ready-for-dev" mang 2 nghĩa (cấp file vs cấp sprint) — đã chú thích trong sprint-status, nhưng là
  điểm dễ gây nhầm cho người mới đọc.
- Ràng buộc hiệu năng "sóng không chen mạch gõ" nên ghi 1 dòng vào Dev Notes story 1.2 cho chắc.

---

## Recommendations

1. **Cứ tiến hành Đợt 1 (1.1, 1.2)** — không bị chặn. Riêng story 1.2, việc đầu tiên khi code là
   xác nhận API lấy tín hiệu từ `MoodWatchMac` (concern #1) trước khi vẽ.
2. **Story 1.5 là story rủi ro nhất** — mang cả 3 concern (#2/#3/#4). Khi tới Đợt 2, đọc kỹ Dev Notes
   1.5 và chạy TC-1.5-4 (giờ yên lặng) cẩn thận.
3. **Thêm 1 dòng ràng buộc hiệu năng** vào Dev Notes 1.2 ("sóng animate async, tuyệt đối không chen
   mạch gõ phím") để bịt điểm FAIL duy nhất trong Architecture Quality.
4. **Giữ nguyên quyết định bỏ PRD/architecture** — hợp lý cho epic này; chỉ dựng tech-spec nếu có
   người mới join hoặc epic phình.
5. Khi cả 6 story done, chạy lại **toàn bộ Cổng Hiến Chương** trong TEST-PLAN như cổng release cuối.

---

## Gate Decision

**Verdict: CONCERNS**

**Rationale:** Mọi tiêu chí phủ (FR 100%, NFR 100%, epic traceability 100%, architecture quality 90%)
đều ở ngưỡng PASS; nhưng có các điểm chưa-chắc về code thật đã được giảm thiểu (ghi trong Dev Notes)
+ corpus cố ý thiếu PRD/architecture chính thức. Theo luật gate, "blocker có kế hoạch giảm thiểu" →
CONCERNS: lõi vững, **được tiến hành nhưng thận trọng**, mang concern theo làm Dev Note.

### CONCERNS — nghĩa là gì
Lập kế hoạch cốt lõi đã vững. Tiến hành thận trọng. Mang 4 concern ở trên theo làm Dev Note trong
story bị ảnh hưởng (chúng đã nằm sẵn đó) để agent thực thi có đủ ngữ cảnh. Xác nhận lại các API
[Inference] ngay khi bắt tay, trước khi vẽ/ghép.

---

## Next Step

Kế hoạch đã qua cổng ở mức CONCERNS — **được phép sang code**. Bắt đầu **Đợt 1 (story 1.1 + 1.2)**
qua skill `mindful-keyboard-harness` (platform-shell-agent cho 1.1, mood-layer-agent cho 1.2). Việc
ĐẦU TIÊN của story 1.2: xác nhận API tín hiệu từ `MoodWatchMac` (concern #1). Không cần chạy lại
readiness-check trừ khi phát sinh thay đổi lớn về yêu cầu.

---

_BMAD Planning & Orchestrator · Readiness Check · tracks `bmad-check-implementation-readiness` from the BMAD Method by the BMAD Code Organization_
