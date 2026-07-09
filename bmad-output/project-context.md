# Project Context — Mindful Keyboard — Windows Port

> The project **constitution**. This document is loaded by every BMAD planning skill
> so they all share the same ground truth. Keep it tight, current, and authoritative.
> When a major decision changes scope, update this file and append the change to
> `decision-log.md`.

- **Track:** bmad-method  _(quick-flow | bmad-method | enterprise)_
- **Created:** 2026-07-09T05:20:40Z

---

## Project Goal

Đưa vòng lặp lõi **Sense → Pause → Remind → Reflect** (đã chạy trên macOS MVP) sang
Windows, dùng lại nguyên bộ não C++ dùng chung (`core/engine`, `core/mood`) — không
fork logic gõ. "Done" = người dùng Windows có trải nghiệm tương đương macOS: gõ tiếng
Việt bình thường qua low-level keyboard hook, tray icon thay menu-bar, gatekeeper chặn
mềm tin nhắn giận dữ trong app chat allow-list, chuông chánh niệm + màn soi lại cuối
ngày — chạy mượt, không khựng gõ, không rò rỉ dữ liệu ra ngoài máy.

## Primary Users

Giống macOS MVP: cộng đồng thực hành chánh niệm (thiền, mindfulness) đã có sẵn động
lực nội tại chấp nhận "chậm lại 1 nhịp" — nhưng đang dùng Windows nên chưa dùng được
sản phẩm. Không nhắm "mọi người gõ tiếng Việt" nói chung.

## Scope

- **Win32 keyboard hook** thay CGEventTap (macOS) — bắt phím low-level, gọi
  `vKeyHandleEvent()` (cửa duy nhất vào engine), không đổi logic gõ.
- **System tray** thay menu-bar app macOS.
- **Send-gatekeeper Windows** — port `SendGatekeeperMac` sang Windows: bắt
  Enter-không-Shift trong app chat allow-list (Zalo/Messenger/Telegram bản Windows),
  hiện panel nổi "Vẫn gửi"/"Đợi chút", vẫn là ma sát mềm — không khoá cứng nút Gửi.
  Feature #1, không ngang hàng các tính năng khác.
  cần xác nhận lại: driver-level hook có yêu cầu chữ ký/driver signing của Windows không.
- **Chuông chánh niệm + màn soi lại cuối ngày** — port `BellMac`/`ReflectionScreenMac`
  sang UI Windows tương đương.
- **Kho dữ liệu local mã hoá** — port `MoodStoreMac` (SQLite + AES-256, khoá lưu an
  toàn) sang cơ chế lưu khoá tương đương Windows (không có Keychain — cần quyết định
  trong architecture: DPAPI hay tương đương).
- **Đóng gói/phân phối** — installer Windows (MSI/EXE), có thể cần ký code
  (Authenticode) tương đương notarize trên macOS; chưa quyết định.

## Core Constraints

- **Không fork logic gõ** — Windows dùng lại `core/engine` nguyên vẹn; mọi khác biệt
  chỉ nằm ở vỏ (`platforms/windows/`), giống nguyên tắc "macOS → Windows → Linux, engine
  dùng chung" trong HIẾN CHƯƠNG (CLAUDE.md).
- **Riêng tư mặc định** — câu gõ gốc không rời máy; xử lý cảm xúc 100% on-device; zero
  network telemetry; kho dữ liệu local mã hoá at-rest; consent gate 1 lần lúc khởi động,
  không hỏi giữa lúc căng thẳng (theo `docs/PRIVACY-NOTE.md`).
- **GPL v3** — kế thừa OpenKey, giữ credit Mai Vũ Tuyên.
- **Ma sát mềm, không chặn cứng** — gatekeeper không bao giờ khoá nút Gửi.
- **Nhận diện trung tính** — sóng `~` biến hình theo biên độ, sắc độ trung tính không
  bão hoà; KHÔNG đèn đỏ/xanh-lá, KHÔNG mặt cười/mếu, KHÔNG gamification, KHÔNG copy
  khiển trách (bất khả xâm phạm — HIẾN CHƯƠNG §2.2/2.3). Mọi quyết định chạm nhận
  diện/pháp lý mà mơ hồ → hỏi chủ dự án, không tự quyết trong PRD/kiến trúc.
- Máy dev hiện tại là macOS — không thể build/test Windows tại chỗ; ảnh hưởng cách
  story được viết (cần rõ ràng hơn để build/test trên máy Windows hoặc CI riêng).

## Non-Goals

- Không đổi/thêm logic ghép vần, bỏ dấu, macro trong `core/engine` để phục vụ Windows
  — nếu Windows cần khả năng engine chưa có, đó là việc riêng của `engine-agent`, không
  phải phạm vi port này.
- Không nhắm Windows Store ở MVP này (mirror quyết định macOS: phân phối trực tiếp,
  không qua store) — có thể đổi sau, chưa quyết trong phạm vi này.
- Không thêm cảm xúc/phân loại mới ngoài send-risk 0–1 đã có.
- Không đụng Linux/Android/iOS — nằm ngoài phạm vi port Windows này.
- Không đặt mục tiêu tăng trưởng/marketing cho bản Windows — vẫn là validate vòng lặp
  lõi trên nền tảng mới, giống tinh thần macOS MVP.

## Key Stakeholders / Roles

Một người builder (chủ dự án) điều phối qua BMAD (lập kế hoạch) rồi giao việc thực thi
cho `platform-shell-agent` (vỏ Windows, qua skill `platform-porting`). Chạm tới engine
dùng chung → tham vấn `engine-agent`; chạm tới lớp cảm xúc/mood store → tham vấn
`mood-layer-agent`. Việc lớn, còn mơ hồ → BMAD lập kế hoạch trước; việc nhỏ rõ ràng →
gọi thẳng agent/skill chuyên biệt, bỏ qua BMAD.

## Glossary

- **Send-risk (0–1):** điểm rủi ro gửi tin duy nhất tính từ câu vừa gõ xong, thay cho
  phân loại nhiều cảm xúc.
- **Gatekeeper (Feature #1):** khoảng dừng chánh niệm trước khi gửi tin nhắn giận dữ
  trong app chat allow-list — ma sát mềm, không chặn cứng.
- **Ma sát mềm (soft friction):** nút Gửi không bao giờ bị khoá; quyết định cuối luôn
  thuộc người dùng.
- **HIẾN CHƯƠNG:** văn bản quản trị bất khả xâm phạm của dự án (`docs/AGENT-BRIEF.md`,
  trích ở `CLAUDE.md`).
- **Vỏ (shell):** lớp code riêng từng OS (win32/, macOS/) — đối lập với "bộ não"
  (`core/engine`) dùng chung.

---

## Decision Thread

Running decisions live in [`decision-log.md`](./decision-log.md). The first entry is
the track choice from initialization. Consult it before making decisions that might
contradict earlier ones.

## Planning Status (count-based)

- **Track:** bmad-method
- **Stories defined:** _(updated by sprint-planning / story creation)_
- **Stories remaining:** _(count-based delivery — no points, no velocity)_

_This document plans the work. Implementation is handed to external dev tools via
ready-for-dev story files; the planning plugin never writes or tests application code._
