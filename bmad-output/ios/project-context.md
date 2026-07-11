# Project Context — Mindful Keyboard — iOS

> Bản **hiến pháp** của đội iOS. Mọi skill BMAD kế hoạch nạp file này để cùng một nền
> sự thật. Giữ gọn, cập nhật, có thẩm quyền. Khi một quyết định lớn đổi phạm vi → sửa
> file này + ghi thêm vào `decision-log.md`.
>
> ⚖️ **Luật tối cao vẫn là HIẾN CHƯƠNG** `docs/AGENT-BRIEF.md` (không đèn đỏ/xanh cảm xúc ·
> không emoji chấm điểm · không gamification · không copy khiển trách · nhận diện = con sóng
> `~` trung tính, "mô tả không phán xét" · GPL v3, giữ credit Mai Vũ Tuyên · mơ hồ chạm nhận
> diện/pháp lý → hỏi chủ dự án). File này chỉ là ngữ cảnh riêng đội iOS, không ghi đè hiến chương.

- **Track:** quick-flow  _(quick-flow | bmad-method | enterprise)_
- **Created:** 2026-07-10T09:43:36Z

---

## Project Goal

Đưa bộ gõ tiếng Việt chánh niệm sang iOS dưới dạng **keyboard extension**: chứng minh
`core/engine` (bộ não C++ dùng chung) build và chạy gọn được trong sandbox iOS (trần RAM
~48–60MB), gõ Telex có dấu chuẩn ngay trong bàn phím. "Xong và thành công" của **Round 1** =
cài được bàn phím, gõ ra tiếng Việt có dấu trong Notes và Zalo, engine **không sửa một dòng nào**.

## Primary Users

Người Việt gõ tiếng Việt trên iPhone/iPad muốn một bộ gõ tôn trọng sự chú tâm — riêng tư mặc
định (on-device 100%, không gửi nội dung gõ đi đâu), không phán xét, không gamify. Round 1 phục
vụ nhu cầu nền: gõ Telex có dấu mượt trong keyboard extension.

## Scope

Track **Quick Flow** — chỉ tech-spec, không PRD/architecture đầy đủ. Round 1 = walking skeleton:
- Keyboard extension iOS gõ Telex qua `core/engine` nguyên vẹn (không fork logic gõ).
- Onboarding trong container app: kích hoạt bàn phím + xin **Full Access**, giải thích rõ vì sao.
- Build cả app iOS lẫn extension từ **một** `platforms/apple/project.yml` chung (XcodeGen).
- **Nhịp 0:** rút phần dùng-chung-được giữa vỏ macOS và iOS ra `platforms/apple/shared/`.

## Core Constraints

- `core/` **đóng băng** — chỉ tiêu thụ qua API sẵn có (`core/engine`, `core/mood`), không sửa để
  vá lỗi riêng iOS. Đổi `core/` phải qua đội core.
- Đội iOS chỉ được sửa `platforms/apple/ios/**` và `platforms/apple/shared/**`.
- On-device 100%, chưa dùng mạng ở Round 1.
- `core/engine` phải nạp gọn dưới trần RAM (~48–60MB) của iOS keyboard extension.
- Phần "gửi ký tự" của `OpenKey.mm` (macOS dùng CGEventTap) **phải viết lại hoàn toàn** cho
  `UITextDocumentProxy` — khác biệt kiến trúc thật, không phải chi tiết vặt (verify trong tech-spec).

## Non-Goals

- Sóng `~` nhận diện cảm xúc trên thanh gợi ý → **Round 2**.
- **Gác cổng/nhịp thở trước khi gửi — kể cả bản "nhắc"** → Round 2+. iOS sandbox không thấy nút
  Gửi/host app nên Feature #1 macOS không port thẳng được (mandate chốt 2026-07-10,
  `MOBILE-UX-ANALYSIS.md` §3). Đây là ranh giới cố ý, không phải thiếu sót.
- Nhật ký cảm xúc on-device, portal, thanh toán, kho theme → Round 3+.

## Key Stakeholders / Roles

Chủ dự án (kiêm trưởng nhóm iOS, người chốt mọi việc chạm nhận diện/pháp lý). Xây: `ios-shell-agent`
(vỏ iOS) qua skill `ios-keyboard-extension`. `core/` do đội core sở hữu (đóng băng với iOS).

## Glossary

- **Round 1 / walking skeleton** — lát cắt mỏng chứng minh engine chạy trong extension, chưa có
  tính năng cảm xúc.
- **Nhịp 0** — bước rút code dùng chung macOS↔iOS ra `platforms/apple/shared/` trước khi phân nhánh.
- **Full Access** — quyền iOS cho phép keyboard extension truy cập ngoài sandbox tối thiểu; Round 1
  cần giải thích minh bạch vì sao xin.
- **core/engine** — bộ não C++ thuần dùng chung mọi OS (Telex/VNI, gõ tắt, macro).

---

## Decision Thread

Quyết định đang chạy nằm ở [`decision-log.md`](./decision-log.md) (log **riêng đội iOS**, tách
khỏi `../decision-log.md` ở root dành cho quyết định xuyên đội). Tra trước khi ra quyết định có
thể mâu thuẫn cái cũ.

## Planning Status (count-based)

- **Track:** quick-flow
- **Artifacts đã có:** SPEC.md · tech-spec.md · DESIGN.md · EXPERIENCE.md · DESIGN-PROMPT.md
- **Stories defined:** _(cập nhật bởi sprint-planning / story creation)_
- **Stories remaining:** _(count-based — không điểm, không velocity)_

_File này lo phần kế hoạch. Việc code giao cho dev tool ngoài qua story ready-for-dev; plugin
kế hoạch không bao giờ viết/test code ứng dụng._
