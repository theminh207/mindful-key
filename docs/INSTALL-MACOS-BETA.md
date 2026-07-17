# Cài MindfulKey trên macOS — bản beta (chưa notarize)

**Lập:** 2026-07-17 · Bối cảnh: người dùng thật tải 0.2.1 qua Chrome và bị macOS báo
*"MindfulKey is damaged and can't be opened"* (xem `docs/FRICTION-LOG.md` cùng ngày).

## Vì sao bị "damaged" — cơ chế thật, không phải app hỏng

Hình dung cờ **quarantine** như cái tem kiểm dịch dán lên kiện hàng. Tem này KHÔNG phải do Apple
dán từ xa — do chính **trình duyệt/Mail/AirDrop trên máy người nhận** dán lên file lúc tải về.
Gatekeeper của macOS chỉ soi những kiện có tem: app đã công chứng (notarize) thì qua; app ký
ad-hoc như bản beta này thì bị chặn thẳng với thông báo *"damaged"* — chữ "damaged" là macOS nói
sai lệch, file thực ra nguyên vẹn.

Điểm mấu chốt: **`curl` trong Terminal không dán tem.** Nên cùng một file `.dmg`, tải bằng
trình duyệt thì bị chặn, tải bằng script qua `curl` thì mở là chạy. Đây không phải "lách kiểm tra
an ninh" — chỉ là không bị dán nhầm tem ngay từ đầu. (Homebrew hoạt động cũng nhờ đúng cơ chế
này; các app indie "không cần notarize" mà bạn thấy ngoài kia đều đi đường này hoặc đẩy việc gỡ
tem sang người dùng.)

## Ba đường cài, chọn một

### 1. Script Terminal (khuyên dùng cho beta)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/theminh207/mindful-key/main/scripts/install-macos.sh)"
```

Script (`scripts/install-macos.sh`) tải bản mới nhất, tự thoát bản cũ nếu đang chạy, chép vào
`/Applications`, mở app. Đã test thật trên máy dev 2026-07-17 (cài từ dmg local, chạy lặp 2 lần,
đường lỗi 404 thoát sạch kèm thông điệp rõ).

> ⚠️ **Trạng thái link (đo thật 2026-07-17):** `releases/latest/download/MindfulKey.dmg` đang
> **404** — job release kèm asset tên cố định chưa chạy lần nào (xem `docs/TEST_MATRIX.md`).
> Script sẽ báo lỗi tử tế và chỉ sang trang Releases. Link tự sống từ bản phát hành kế tiếp.

### 2. Tải bằng trình duyệt + tự gỡ tem

Tải `.dmg` từ [Releases](https://github.com/theminh207/mindful-key/releases), kéo vào
Applications, rồi:

```bash
xattr -dr com.apple.quarantine /Applications/MindfulKey.app
```

Chỉ làm vậy với tệp tải từ trang chính thức của dự án. Dạy người dùng phổ thông gõ lệnh này là
**thói quen xấu** (họ sẽ gỡ tem cho cả app không rõ nguồn) — nên đường 1 vẫn hơn.

### 3. Chờ bản notarize (đường duy nhất cho công chúng)

Muốn "tải bằng trình duyệt, double-click là chạy" cho mọi người dùng thì **không có đường nào
khác** ngoài Apple Developer Program **$99/năm** + ký Developer ID + notarize + staple.

**Sự thật cần nói thẳng về "dùng Xcode miễn phí":** tài khoản Apple ID miễn phí chỉ ký được bản
chạy trên **chính máy mình**, hết hạn sau 7 ngày, và **không notarize được** — notarization đòi
membership trả phí. Không có mẹo Xcode nào thay được $99 cho việc phân phối công khai. Với app đã
có người ngoài dùng, $99/năm là khoản rẻ nhất của cả dự án.

## Ranh giới đã kiểm chứng

| Điều | Bằng chứng |
|---|---|
| Script cài được từ dmg local, dọn mount sạch, chạy lặp OK | Chạy thật trên máy dev 2026-07-17 |
| Đường lỗi 404 thoát mã 1 + thông điệp tiếng Việt | Chạy thật (link đang 404 thật) |
| Cài từ link GitHub thật → mở app trên máy lạ | **CHƯA** — cần bản phát hành kế tiếp + mắt người |
| App mở được không bị "damaged" sau khi cài qua script | **CHƯA** trên máy lạ — cơ chế quarantine là hành vi hệ điều hành đã biết, nhưng vẫn phải xác nhận thật |
