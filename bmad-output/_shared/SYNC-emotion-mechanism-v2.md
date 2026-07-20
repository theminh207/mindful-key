# Sổ tay đồng bộ cơ chế cảm xúc v2 — macOS ↔ iOS

**Ngày chốt:** 2026-07-13 · **Nguồn:** `decision-log.md` entry 2026-07-13 "Diện mạo mới v2"
**Mục đích:** khoá ranh giới "cái gì DÙNG CHUNG cho mọi vỏ" vs "cái gì RIÊNG macOS", để khi đội iOS
bắt tay, nhật ký + dòng sông + Soi lại vẽ ra **giống nhau**, không phải phát minh lại.

> ⚖️ Mọi mục dưới lọc qua HIẾN CHƯƠNG: cảm xúc = con sóng `~` một sắc, một trục **phẳng ↔ gợn**
> (KHÔNG tốt/xấu, KHÔNG đỏ/xanh, KHÔNG streak/điểm/gamification), câu hỏi > con số.

---

## A. LÕI DÙNG CHUNG — iOS phải kế thừa y hệt (nên sống ở `core/mood`)

| Cơ chế | Hiện ở đâu | Ghi chú đồng bộ |
|--------|-----------|-----------------|
| `MoodBuffer` (gom từ → câu) | `core/mood` ✅ | Đã dùng chung. iOS nối thẳng. |
| **Chấm điểm send-risk 0–1** (một trục phẳng↔gợn) | lexicon trong `MoodWatchMac.mm` (vỏ macOS) ⚠️ | **NÊN ĐƯA VỀ `core/mood`** để iOS chấm điểm y hệt — nếu không, hai vỏ ra hai điểm khác nhau, sông không so được. Đây chính là friction "hợp nhất lexicon về core hay giữ ở platforms/apple/shared" — v2 tạo áp lực **chọn đưa về core**. |
| **Mô hình LẤY MẪU**: để ý liên tục trong RAM → ghi **1 số trung bình mỗi nhịp** (interval = nhịp chuông/nhắc); quãng **không gõ để TRỐNG** | chưa code (Bước 3 macOS) | Là **hợp đồng dữ liệu**, không phải UI → làm ở lớp dùng chung để nhật ký iOS/macOS cùng dạng. |
| **Schema nhật ký**: `ts · event_type · send_risk · …` với `event_type` mới `'sample'` (lấy mẫu mỗi nhịp) + `'checkin'` (tự thuật) | `MoodStoreMac` (macOS) — cột `checkin` đã khai báo sẵn | iOS dùng **cùng tên cột + cùng event_type** → sông vẽ giống. Ghi mã hoá at-rest cả hai vỏ. |
| **`event_type = 'note'`** (ô ghi cảm nhận cuối ngày — CHỮ TỰ DO, khác `'checkin'` có cấu trúc) | chưa code — xem `_shared/DECISION-daily-note-v1.md` | ⚠️ Lần đầu lưu **chữ thật** của người dùng → cột text **mã hoá at-rest cả hai vỏ**, consent RIÊNG, loại khỏi export mặc định, **CẤM chạy sentiment lên nội dung**. iOS dùng cùng `event_type`. Note = chữ, chỉ con người đọc. |
| **Độ nhạy = LỚP DIỄN GIẢI** (ngưỡng "gợn", ngưỡng nhắc), KHÔNG viết lại điểm thô | spec (Bước 3) | Nguyên tắc chung: điểm thô bất biến, độ nhạy chỉ đổi cách *đọc*. iOS giữ y nguyên nguyên tắc. |
| **4 phép tính Soi lại**: dòng sông · đỉnh gợn (≥2 câu/nhịp) · quãng lặng dài nhất · "lặng lại" (kể-thành-câu) | chưa code (Bước 4 macOS) | Logic thuần số → ứng viên đưa `core/mood` để iOS tính giống hệt. |
| **Chuông = nhịp lấy mẫu** (mỗi ngân = 1 điểm lên sông) | Bước 3–4 | iOS: nhắc thụ động theo nhịp + lấy mẫu theo cùng nhịp. Khái niệm chung. |
| **Hợp đồng nhận diện** (1 hue, biên độ, câu hỏi là trung tâm, không gamification) | HIẾN CHƯƠNG | Bất biến mọi vỏ. |

## B. RIÊNG VỎ macOS — iOS KHÔNG có / làm khác

- **Gác cổng gửi tin** (chặn Enter-không-Shift xuyên app qua CGEventTap): **iOS KHÔNG LÀM ĐƯỢC** (sandbox, không global hook). Đã chốt friction 2026-07-10: iOS = **nhật ký + nhắc thụ động, KHÔNG gác cổng**.
  → Hệ quả: **"khoảnh khắc gác cổng" (chân kiềng dữ liệu #2) trên iOS sẽ VẮNG.** iOS phải dựa nhiều hơn vào **check-in (chân #3)** + **sóng chữ (chân #1)** để bù. Ghi rõ khi thiết kế Soi lại iOS: đừng giả định có dữ liệu "lựa chọn đợi/sửa/vẫn gửi".
- **Popover / menu-bar / cửa sổ 6 mục**: AppKit riêng. iOS có UI keyboard-extension riêng — nhưng **mượn cùng ngôn ngữ**: chia tab, dòng sông, màn Soi lại 4 nhịp.
- **Độ nhạy điều khiển ngưỡng gác cổng**: iOS bỏ phần gác cổng, chỉ giữ phần điều khiển nhắc/chuông.

## C. Việc cần QUYẾT khi mở lại đội iOS (đừng quên)

1. **Đưa phần chấm điểm (send-risk) + 4 phép tính Soi lại về `core/mood`** để hai vỏ đồng bộ — hay giữ mỗi vỏ một bản (rủi ro lệch). **v2 nghiêng về ĐƯA VỀ CORE.** Chốt trước khi iOS code lớp cảm xúc.
2. iOS thiếu chân kiềng #2 (gác cổng) → cân nhắc **tăng vai trò check-in** để bù mật độ dữ liệu ngày.
3. Ba chân kiềng của iOS = **sóng chữ + check-in** (không có gác cổng) — thiết kế Soi lại iOS phải trung thực với điều này.

---

*Ba chân kiềng dữ liệu (đầy đủ): (1) sóng chữ auto · (2) khoảnh khắc gác cổng [macOS-only] · (3) check-in 1 chạm. Xem chi tiết thuật toán ở `decision-log.md` 2026-07-13 + 3 mockup đợt thiết kế v2.*
