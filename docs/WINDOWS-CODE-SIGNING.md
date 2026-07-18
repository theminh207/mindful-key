# Ký số bản Windows — đường SignPath Foundation

> Chốt 2026-07-18: chủ dự án chọn **SignPath Foundation** (miễn phí cho dự án mã nguồn mở).
> Đánh đổi đã đồng ý: dòng nhà phát hành (publisher) mà SmartScreen hiện lúc cài sẽ là
> **"SignPath Foundation"**, KHÔNG phải tên chủ dự án. Muốn tên mình thì phải đi chứng chỉ EV
> có phí (~$400–600/năm + HSM cho CI) — để ngỏ, chưa chọn.

## Vì sao bị chặn, và vì sao ký giải quyết được

SmartScreen chặn mọi `.exe` **chưa ký** như bảo vệ chặn người lạ không đeo thẻ. Ký số = đeo thẻ
có tên + niêm phong "chưa ai sửa dọc đường". Không có đường tắt hợp lệ nào khác; thứ gì hứa
"bypass SmartScreen" đều là né, mà né thì đúng cái mã độc làm.

Với **bộ gõ** — phần mềm đọc từng phím — bị hỏi giấy là Windows làm ĐÚNG. Việc của ta không phải
làm cảnh báo biến mất, mà làm cho danh tính kiểm chứng được.

## Điều kiện SignPath — đối chiếu dự án

| Điều kiện SignPath | mindful-key | Trạng thái |
|---|---|---|
| Mã nguồn mở, repo công khai | github.com/theminh207/mindful-key (public) | ✅ |
| Giấy phép OSS được công nhận | GPL v3 (`LICENSE.txt`) | ✅ |
| Chức năng được mô tả ở trang tải/README | `README.md` + trang Releases | ✅ (kiểm lại nội dung release notes) |
| **Đã phát hành ở đúng dạng cần ký** | Bộ cài hiện tại CHƯA mở được (bug khởi động vừa vá, chưa CI-verify) | ❌ **CHẶN** |

Cột cuối là lý do SignPath là **bước 2**: họ không ký một bản chưa chạy, mà ký cũng vô nghĩa.

## Thứ tự đúng (không đảo được)

**Bước 0 — có bản chạy được** *(việc của chủ dự án + CI, đang dở)*
Push bản vá khởi động (`e68f101`) → CI dựng `.exe` + bộ cài → chủ dự án cầm máy Windows xác nhận:
mở được, gõ Telex ra dấu (QA `T1`), chuông kêu (`B0`). Chưa qua bước này thì mọi bước sau là xây
nhà trên cát.

**Bước 1 — nộp đơn SignPath** *(việc của chủ dự án, CHẠY SONG SONG được ngay hôm nay)*
Duyệt mất **vài ngày–vài tuần**, nên bắt đầu sớm là khôn. Vào https://signpath.org/ →
"Apply for Open Source". Điền:
- **Project name:** Mindful Keyboard (mindful-key)
- **Repository:** https://github.com/theminh207/mindful-key
- **License:** GPL v3
- **Mô tả chức năng:** bộ gõ Tiếng Việt (Telex/VNI) chánh niệm, chạy trên máy, không gửi nội
  dung gõ đi đâu. Fork engine OpenKey (Mai Vũ Tuyên), GPL v3.
- **Build system:** GitHub Actions (`.github/workflows/release.yml`) — build từ tag trên repo
  công khai. Đây là điểm SignPath thích: bản ký truy được về đúng commit công khai.

**Bước 2 — nối ký vào CI** *(việc của tôi, SAU khi duyệt)*
Sau khi duyệt, SignPath cấp cho chủ dự án 3 mảnh **cấu hình** (không phải bí mật) + 1 **token bí mật**:
- Organization ID, Project slug, Signing-policy slug → tôi cắm vào `release.yml`.
- API token → chủ dự án lưu vào GitHub secret `SIGNPATH_API_TOKEN` (Settings → Secrets).

Chưa có 4 mảnh này thì **tôi KHÔNG viết YAML trước** — viết bằng slug tự chế là bịa cấu hình, đúng
thứ kỷ luật dự án cấm. Khi có, tôi nối một bước giữa "build .exe" và "đóng bộ cài": gửi `.exe` cho
SignPath ký → nhận về → đóng bộ cài → gửi luôn bộ cài (`MindfulKey_*_x64-setup.exe`) đi ký nốt.
Ký cả hai vì người dùng chạm bộ cài trước, rồi bộ cài thả `.exe` đã ký ra.

## Kỳ vọng thật (không tô hồng)

- Chứng chỉ SignPath mức **OV**. OV không cho uy tín SmartScreen tức thì như EV — nhưng chứng chỉ
  của **SignPath Foundation đã được vô số dự án OSS dùng**, nên nó không phải thẻ mới tinh: bảo vệ
  đã quen mặt. Thực tế tốt hơn hẳn bản chưa ký; giai đoạn đầu có thể còn cảnh báo nhẹ nhưng **có
  tên nhà phát hành thật**, không còn "Unknown publisher".
- `AppPublisher` trong bộ cài (`MindfulKey.iss` hiện ghi "The OpenKey Project") là **chuỗi hiển
  thị trong Programs & Features**, KHÁC với publisher mà SmartScreen đọc từ chứng chỉ
  ("SignPath Foundation"). Hai chỗ khác nhau, đừng nhầm là một.
- Credit Mai Vũ Tuyên trong hộp Giới thiệu **không đổi** — ký số không đụng gì tới GPL hay credit.

## Nhắc

Trong lúc chờ, `Unblock-File "…\MindfulKey-setup.exe"` trong PowerShell đủ để **chủ dự án tự test**
trên máy mình (gỡ dấu "tải từ Internet"). KHÔNG giúp gì cho người dùng khác — máy họ vẫn chặn tới
khi có chữ ký thật.
