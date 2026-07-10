# SPEC — mindful-key · iOS Round 1 (Walking Skeleton)

> **This is the kernel.** Five fields. Keep it lean.
> Downstream skills (PRD, tech-spec, architecture) expand each field.
> Do not add sections. If something doesn't fit, put it in the PRD.

**Created:** 2026-07-10
**Source:** Kernel Round 1 do chủ dự án cung cấp trực tiếp (vai trưởng nhóm iOS), đối chiếu `docs/AGENT-BRIEF.md` + `/Users/now/Projects/mindful-keyboard/docs/MOBILE-UX-ANALYSIS.md` (phân tích Laban Key, §3 — kết luận Feature #1 không port thẳng lên iOS được).
**Track:** quick-flow
**Status:** draft — chờ chủ dự án duyệt trước khi qua `bmad-tech-spec`

**Open item (không thuộc 5 field, cần chủ dự án làm rõ ở bước sau):** kernel gốc nhắc "mockup màn 01–02" cho onboarding kích hoạt bàn phím + xin Full Access — không tìm thấy file mockup cụ thể nào trong repo (`mindful-key/`, `mindful-keyboard/`) hay `ref-ux-ui-laban-key/` tại thời điểm viết SPEC này. `bmad-tech-spec` cần input này (file thật hoặc mô tả bằng lời) trước khi đặc tả 2 màn onboarding.

---

## Problem

mindful-keyboard hiện chỉ chạy trên macOS. `core/engine` (bộ não C++ dùng chung — Telex/VNI, gõ tắt, macro) chưa từng được build và chạy thử bên trong một iOS keyboard extension — môi trường sandbox riêng của Apple, trần RAM chỉ khoảng 48–60MB (hệ điều hành kill extension nếu vượt). Đây là rủi ro kỹ thuật lớn nhất chưa gỡ của việc mở rộng lên iOS: nếu `core/engine` không nạp gọn được trong giới hạn đó, cột trụ "1 bộ não dùng chung mọi OS" cho iOS phải xét lại trước khi đầu tư thêm bất kỳ UI hay tính năng cảm xúc nào.

---

## Capabilities

- Người dùng cài được bàn phím iOS và gõ tiếng Việt có dấu bằng Telex ngay trong keyboard extension, chạy qua `core/engine` hiện có nguyên vẹn (không fork logic gõ).
- Người dùng mới được dẫn qua onboarding kích hoạt bàn phím + xin quyền Full Access trong container app, giải thích rõ vì sao cần quyền đó (không xin quyền mập mờ).
- Dự án build được cả app iOS lẫn keyboard extension từ một `platforms/apple/project.yml` chung (XcodeGen) — không tạo project riêng lẻ ngoài quy trình build hiện có.
- Phần code dùng chung được giữa vỏ macOS và vỏ iOS được rút ra `platforms/apple/shared/` (Nhịp 0), thay vì mỗi vỏ tự viết lại từ đầu.

---

## Constraints

- `core/` đóng băng — chỉ tiêu thụ qua API sẵn có (`core/engine`, `core/mood`), không sửa để vá lỗi riêng iOS. Đổi `core/` phải qua đội core.
- Đội iOS chỉ được sửa `platforms/apple/ios/**` và `platforms/apple/shared/**`.
- On-device 100%, chưa dùng mạng ở Round 1.
- `core/engine` phải nạp gọn dưới trần RAM (~48–60MB) của iOS keyboard extension.

---

## Non-Goals

- Sóng `~` nhận diện cảm xúc trên thanh gợi ý (Round 2).
- Gác cổng/nhịp thở trước khi gửi — kể cả bản "nhắc" (Phương án A, `MOBILE-UX-ANALYSIS.md` §3.2/§3.6) — để Round 2, vì cần `MoodBuffer` + lexicon on-device, ngoài phạm vi walking skeleton.
- Nhật ký cảm xúc on-device, portal, thanh toán, kho theme (Round 3+).

---

## Success Metrics

- Cài được bàn phím và gõ ra đúng "tiếng Việt" có dấu bằng Telex trong Notes và Zalo (kiểm thủ công cả 2 app).
- Keyboard extension không bị hệ điều hành kill vì vượt RAM trong một phiên gõ thông thường.
- `git diff core/` rỗng tại thời điểm hoàn thành Round 1 — bằng chứng cụ thể là chưa đụng bộ não dùng chung.

---

<!-- SPEC END — anything else belongs in the PRD, tech-spec, or architecture doc. -->
