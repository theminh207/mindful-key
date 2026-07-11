---
name: mindful-test-design
description: Thiết kế/rà ca test cho bộ gõ chánh niệm — engine Telex/VNI (tests/core), lớp mood, vỏ macOS/iOS. Mang tinh thần Risk-Based Testing + Field-Level Validation về đúng bối cảnh bàn phím native. PHẢI dùng khi: thêm/sửa ca test cho core/engine hay core/mood; thiết kế test cho Mốc B (gõ Telex ra dấu); rà "đã test đủ ca biên chưa"; hoặc muốn checklist "test coi là xong khi nào". KHÔNG dùng để viết automation web/DOM (dự án không có browser) — đó là chuyện của qa-test-planner generic trong analysis/.
---

# Mindful Test Design

> Chắt lọc từ **Anh Tester — antigravity/claude-testing-kit** (MIT, giữ credit). Bỏ phần
> web/DOM/Playwright/Selenium/Jira (dự án native không dùng), giữ 4 giá trị đã dịch sang bối
> cảnh bàn phím tiếng Việt: **(1)** ma trận ca biên kiểu Field-Level Validation → Telex/VNI,
> **(2)** Risk-Based Testing theo rủi ro DỰ ÁN, **(3)** Definition of Done cho test, **(4)**
> "verify đừng đoán".
>
> ⚖️ Luật tối cao vẫn là HIẾN CHƯƠNG. Test cũng phải "mô tả không phán xét" — báo cáo test
> KHÔNG gamify (không điểm/streak/xếp hạng), KHÔNG mã màu đỏ-xanh cho cảm xúc.

## Khi nào dùng
- Thêm/sửa ca test engine ở [tests/core/test_engine.cpp](../../../tests/core/test_engine.cpp) (harness tự viết, case hard-code trong `main()` qua `runCase`).
- Thiết kế test cho **Mốc B** (nối `vKeyHandleEvent` → gõ Telex ra dấu) — việc lõi đang dở của Round 1.
- Rà "đã phủ đủ ca biên chưa" trước khi coi một thay đổi engine/mood là xong.
- Cần checklist "test xong khi nào" trước khi commit/push.

## Cửa an toàn (giữ theo harness dự án)
Nếu việc chạm **core/ (đóng băng)**, **riêng tư dữ liệu cảm xúc**, hoặc **nhận diện** → quy chiếu
hiến chương TRƯỚC, mơ hồ thì hỏi chủ dự án; ghi chỗ phải đoán vào `docs/FRICTION-LOG.md`.

---

## 1. Risk-Based Testing — theo rủi ro CỦA DỰ ÁN NÀY
Không phải app nghiệp vụ (tiền/RBAC) như kit gốc. Rủi ro ở đây xếp theo cột trụ dự án:

| Mức | Vùng | Vì sao | Test tới đâu |
|---|---|---|---|
| 🔴 **Cao** | `core/engine` (Telex/VNI/ghép vần/bỏ dấu, word-boundary, backspace) | Bộ não dùng chung mọi OS — sai 1 luật là sai mọi nền tảng | Kỹ nhất: nhiều ca biên (mục 2), đối chiếu output thật |
| 🔴 **Cao** | Riêng tư: ô mật khẩu không đọc/log/sóng · on-device (0 network) · `git diff core/` rỗng | Chạm cột trụ riêng tư + hiến chương M3/M4 | Test bất biến (invariant) — mục 3 |
| 🟠 **Vừa** | `core/mood` (MoodBuffer gom câu, send-risk), App Group (chỉ timestamp/bool), trần RAM ~48-60MB | Sai thì lệch cảm xúc / rò dữ liệu vận hành / bị iOS kill | Test wiring + đo thủ công (RAM) |
| 🟡 **Thấp** | UI polish, animation, copy | Sai thì xấu, không hại | Kiểm mắt + a11y, ít ca tự động |

Nguyên tắc kit gốc giữ nguyên: **Human Strategy (chủ dự án định rủi ro) → AI Execution (AI viết ca test + rà lỗ hổng) → Human Verification (chủ dự án duyệt)**.

## 2. Ma trận ca biên Telex/VNI
Xem **[references/telex-vni-edge-cases.md](references/telex-vni-edge-cases.md)** — đây là phần
"lấy về" cụ thể nhất (Field-Level Validation dịch sang bàn phím). Nguyên tắc: **mỗi loại nhập có
checklist riêng, cấm xài chung 1 bộ** (dấu ≠ nguyên âm biến hình ≠ backspace ≠ xen Anh-Việt).

## 3. Test bất biến hiến chương (cho R2+ khi có lớp mood)
Không chỉ test "gõ đúng" — test cả những điều **KHÔNG được xảy ra**:
- Ô mật khẩu (secure field) → KHÔNG đọc/log/hiện sóng (kể cả khi mood layer bật).
- KHÔNG network call nào mang nội dung gõ.
- App Group chỉ chứa timestamp/bool — assert nội dung gõ KHÔNG lọt vào.
- UI cảm xúc: KHÔNG có token màu đỏ/xanh semantic; nghĩa nằm ở nhãn chữ (test a11y use-of-color).
- `git diff core/` rỗng sau mọi thay đổi iOS.

## 4. Verify đừng đoán (luật cứng)
- Kỳ vọng của 1 ca Telex **phải** verify bằng chạy thật (`make test`) hoặc trích luật chính tả tiếng Việt — **CẤM** chép kỳ vọng từ trí nhớ.
- Ca mới phải đối chiếu 5 ca sẵn có trong `test_engine.cpp` (không mâu thuẫn cơ chế `runCase`/`decodeChar`).
- Test data **cụ thể**, không mơ hồ: ghi `"tieengs vieetj" → "tiếng việt"`, KHÔNG ghi "gõ chuỗi hợp lệ".

## 5. Definition of Done cho test
Xem **[references/test-done-checklist.md](references/test-done-checklist.md)** — "test coi là xong khi nào" (adapt từ DoD của kit sang `make test`/`xcodebuild`/CI + ca chập chờn iOS PASS 2 lần).

## Anti-pattern (❌ → ✅)
| ❌ | ✅ |
|---|---|
| Đoán kỳ vọng Telex từ trí nhớ | Chạy `make test` hoặc trích luật chính tả |
| Test data mơ hồ ("chuỗi hợp lệ") | Chuỗi cụ thể + output cụ thể |
| Chỉ happy path ("tôi đang vui") | Thêm ca biên: dấu đôi, backspace giữa âm, xen Anh-Việt |
| Gộp nhiều luật vào 1 ca | Mỗi luật/loại nhập 1 ca (Field-Level) |
| Vá lỗi riêng iOS bằng sửa `core/` | Sửa ở vỏ; giữ `git diff core/` rỗng |
| Sleep cứng chờ mood async | Chờ tín hiệu debounce hoàn tất, không delay cố định |
| Báo cáo test kiểu điểm số/streak | Báo cáo mô tả: PASS/FAIL/SKIP + lý do, không gamify |

## Quan hệ với skill khác
- Thiết kế ca **cho engine** → dùng skill này rồi sửa `tests/core/test_engine.cpp` (qua `openkey-engine` nếu đụng engine).
- Cần **tài liệu test-case generic / BA** → `analysis/qa-test-planner` (nhưng lọc phần web).
- Bằng chứng hành vi đã chạy → cập nhật `docs/TEST_MATRIX.md`.

---
*Chắt lọc từ Anh Tester testing-kit (MIT). Đã dịch sang bối cảnh mindful-key — không bê nguyên.*
