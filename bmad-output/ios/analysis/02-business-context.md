# 02 — Business Context (Step 0)

> **Pha 2/4 · problem-based-srs Step 0.** Nền business context cho toàn bộ chuỗi CP→CN→FR.
> Nguồn: hiến chương `docs/AGENT-BRIEF.md`, `project-context.md`, PRD macOS, MOBILE-UX-ANALYSIS,
> và Discovery `01-discovery-findings.md`. **2026-07-11.**

---

## 1. Project Identity

| Trường | Giá trị |
|---|---|
| **Tên** | Mindful Key — vỏ iOS (bàn phím tiếng Việt chánh niệm) |
| **Domain** | Bộ gõ tiếng Việt (input method) + lớp cảm xúc/chánh niệm on-device trên iOS |
| **Kiến trúc** | "1 bộ não + nhiều vỏ" — `core/engine`/`core/mood` (C++ dùng chung) + vỏ iOS (Custom Keyboard Extension + container app) |
| **Purpose** | Đưa lớp chánh niệm (sóng `~` + chuông + nhật ký) — vốn đã chứng minh trên macOS — sang iOS, trên nền một bàn phím gõ Telex/VNI quen tay như Laban |
| **Nguồn gốc** | Fork engine OpenKey (Mai Vũ Tuyên), **GPL v3**, giữ credit |

## 2. Business Principles

### Mandatory (bất khả xâm phạm — hiến chương §2.2/2.3)
- **M1** — KHÔNG đèn đỏ/xanh-lá mã hóa cảm xúc; KHÔNG emoji chấm điểm; KHÔNG gamification (streak/điểm/ví xu/đếm tải); KHÔNG copy khiển trách.
- **M2** — Nhận diện = con sóng `~` biến hình theo **biên độ**, sắc độ trung tính không bão hòa; copy "quan sát không phán xét". Mọi UI qua bài kiểm *"mô tả hay phán xét?"*.
- **M3** — Riêng tư mặc định: nội dung gõ **không rời máy**; on-device 100%; xin quyền minh bạch (Full Access nói thật làm gì, luôn có lối "Để sau").
- **M4** — `core/` đóng băng với iOS; chỉ sửa `platforms/apple/ios/**` + `platforms/apple/shared/**`; không fork logic gõ.
- **M5** — macOS là công dân hạng nhất; không làm loãng chất lượng macOS để chạy đua đa nền tảng.
- **M6** — Mandate iOS HẸP: **KHÔNG gác cổng gửi tin xuyên app** (sandbox chặn); iOS chỉ "quan sát + nhắc thụ động".

### Guiding (kim chỉ nam)
- **G1** — Kế thừa *mẫu UX* đã được kiểm chứng của Laban (onboarding kích hoạt, preview sống, slider trực tiếp) nhưng lột phần game hóa.
- **G2** — "Chánh niệm trước, tính năng sau" — ưu tiên đúng tinh thần hơn nhiều tính năng.
- **G3** — Chứng minh bằng chạy thật, không suy diễn (tiền lệ: thực nghiệm compile engine cho iOS).

### Aspirational (mong đợi xa)
- **AS1** — iOS ngang tầm macOS về lớp chánh niệm (sóng + chuông + nhật ký + soi lại cuối ngày).
- **AS2** — Về sau: Android, sync theme opt-in, model sentiment mạnh hơn (PhoBERT ONNX).

## 3. Stakeholders

| Vai | Ảnh hưởng | Quan tâm |
|---|---|---|
| **Chủ dự án** (kiêm trưởng nhóm iOS) | Quyết định cao nhất, đặc biệt mọi thứ chạm nhận diện/pháp lý | Sản phẩm đúng tinh thần, bài bản, không phạm hiến chương |
| **Người dùng cuối** | — | Gõ tiếng Việt mượt + một lớp chánh niệm không phán xét, riêng tư |
| **Đội core** | Sở hữu `core/` (đóng băng với iOS) | `core/` không bị sửa để vá riêng iOS |
| **Đội macOS** | Đồng sở hữu `platforms/apple/shared/` | Thay đổi `shared/` không vỡ build macOS |

## 4. Current Situation

- **Đã có (macOS, tham chiếu):** lớp chánh niệm đầy đủ — MoodWatch, SendGatekeeper (Feature #1), BellMac (chuông), MoodStore (nhật ký mã hóa), ReflectionScreen (soi lại cuối ngày).
- **Đã có (iOS):** Round 1 Mốc A — target iOS trong `project.yml`, skeleton bàn phím vẽ QWERTY, `KeyboardBridge_Init()` chứng minh engine sống trong extension. **Chi tiết ở `00-input-ledger.md`.**
- **Chưa có (iOS):** gõ Telex ra dấu qua engine (Mốc B), onboarding/Full Access UI, App Group detection, test thật, và **toàn bộ lớp chánh niệm** (sóng/chuông/nhật ký).
- **Pain thực tế:** kế hoạch iOS chỉ phủ Round 1 (quick-flow); chưa có lộ trình đa chặng cho sản phẩm đầy đủ.

## 5. Domain Boundaries

**Trong domain (đợt phân tích này):** vỏ iOS — keyboard extension (gõ + sóng cảm xúc + chuông) + container app (onboarding, cài đặt, theme trung tính, nhật ký).
**Ngoài domain:** `core/` (đội core); vỏ macOS/Windows/Android; sync cloud (chỉ nêu ở Aspirational); vuốt phím + macro (chủ dự án không chọn đợt này); phát hành App Store thật/notarize (round cuối).

## 6. Constraints (có đánh giá tác động)

| Ràng buộc | Loại | Tác động |
|---|---|---|
| Trần RAM extension ~48–60MB (iOS kill nếu vượt) | Kỹ thuật cứng | Cao — chi phối UI nhẹ, macro rỗng mặc định, chọn model sentiment |
| Sandbox extension không thấy host app | Nền tảng cứng | Cao — Feature #1 chỉ "nhắc" được, không chặn |
| `core/` đóng băng | Tổ chức | Trung bình — iOS phải bọc, không sửa engine |
| `shared/` dùng chung macOS | Tổ chức | Trung bình — review chéo, chỉ thêm file |
| Hiến chương M1–M6 | Sản phẩm cứng | Cao — quy chiếu trước mọi quyết định UI |
| On-device 100%, không mạng | Riêng tư cứng | Trung bình — nhật ký mã hóa tại chỗ, không server |

## 7. Success Criteria (định tính — cố ý không KPI growth)

- **SC1** — Người dùng cài được bàn phím, gõ ra tiếng Việt có dấu bằng Telex trong Notes + Zalo (Round 1).
- **SC2** — Lớp chánh niệm (sóng `~` ambient + chuông) hoạt động đúng tinh thần "quan sát không chặn" (Round 2).
- **SC3** — Nhật ký on-device mã hóa + soi lại cuối ngày, "đủ để tự nhận ra, không thành dashboard" (Round 3).
- **SC4** — Mọi màn qua bài kiểm *"mô tả hay phán xét?"*; `git diff core/` rỗng; `make build` macOS vẫn xanh.
- **SC5** — Không một yếu tố nào phạm M1 (game hóa/màu cảm xúc/emoji chấm điểm) lọt vào sản phẩm.

---
*Step 0/5 · problem-based-srs. Kế tiếp: `03-customer-problems.md` (CP — WHY).*
