# Release thật (ký Developer ID + notarize) — checklist

Mục tiêu: gắn tag `vX.Y.Z` → GitHub Actions tự build + ký thật + notarize + đăng **1 Release có
cả macOS lẫn Windows** — giống cấu trúc repo tham chiếu `github.com/sonpiaz/haynoi`.

**Luật đặt tên asset (chủ dự án chốt 2026-07-17):** mọi asset mang **tên app + số version** để
phân biệt được. Ngoại lệ DUY NHẤT là 2 bản copy tên-không-đổi phục vụ nút tải trên web — chúng
tồn tại chính vì cái tên không bao giờ đổi (thêm version vào là link đổi mỗi bản → hết tác dụng):

| Asset | Vai trò |
|---|---|
| `MindfulKey-X.Y.Z.dmg` | bản macOS theo version (bản chuẩn để lưu/đối chiếu) |
| `MindfulKey.dmg` | copy y hệt, **tên cố định** → nút "Tải cho macOS" trên web |
| `MindfulKey-X.Y.Z-universal.zip` | bản .app nén (universal) |
| `MindfulKey-X.Y.Z-universal.dSYM.zip` | ký hiệu debug, để giải mã crash log |
| `MindfulKey_X.Y.Z_x64-setup.exe` | bộ cài Windows theo version |
| `MindfulKey-setup.exe` | copy y hệt, **tên cố định** → nút "Tải cho Windows" (chưa nối, xem `site/README.md`) |

> Người tải bản tên-cố-định vẫn biết mình cầm bản nào: ổ đĩa `.dmg` khi mount hiện
> "Mindful Keyboard X.Y.Z", bộ cài Windows hiện "Mindful Key X.Y.Z", và pane **Hệ thống** trong
> app hiện số bản thật.

⚠️ **Release đăng ra ở dạng NHÁP (draft)** — chạy xong workflow là *chưa ai thấy gì*. Vào tab
**Releases**, soi đủ 6 asset rồi bấm **Publish release**. Chừng nào chưa bấm thì
`releases/latest/download/...` chưa tồn tại ⇒ **nút tải trên web gãy**. Draft là cố ý: v0.2.1 từng
chết 3 lần liên tiếp ở bước đăng, và bản Windows chưa từng đi qua đường release lần nào.

Code (script + workflow) đã viết xong. Phần **dưới đây chỉ bạn làm được** — cần quyền truy
cập Apple Developer Program + GitHub repo settings mà tôi không có.

## 1. Lấy chứng chỉ "Developer ID Application"

Máy dev hiện tại (máy đang gõ lệnh này) **chưa có** cert này trong Keychain (đã kiểm tra:
`security find-identity -v` trả về rỗng) — dù tài khoản Apple Developer dùng chung với
haynoi. Hai khả năng:

- **Cert từng tạo cho haynoi vẫn còn hiệu lực, chỉ đang nằm ở máy/Keychain khác** (VD máy đã
  build haynoi trước đây, hoặc đã import thẳng vào GitHub Secrets của repo haynoi mà không
  giữ lại local). Nếu còn máy đó: mở **Keychain Access** → tìm "Developer ID Application: ..."
  trong danh mục *My Certificates* → chuột phải → **Export...** → lưu dạng `.p12`, đặt mật
  khẩu (nhớ mật khẩu này, dùng ở bước 3).
- **Không còn giữ ở đâu / muốn tách riêng cert cho mindful-key:** tạo cert mới tại
  [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates/list)
  → loại **Developer ID Application** → cần tạo CSR (Certificate Signing Request) từ Keychain
  Access trước (menu Keychain Access → Certificate Assistant → Request a Certificate from a
  Certificate Authority). Tải cert `.cer` về, double-click để cài vào Keychain, rồi Export như
  trên.

## 2. Lấy Team ID

`developer.apple.com/account` → góc trên bên phải hoặc mục **Membership** → **Team ID** (chuỗi
10 ký tự, VD `A1B2C3D4E5`).

## 3. Chuẩn bị App Store Connect API Key (dùng để notarize, KHÔNG phải cùng cert ở bước 1)

[appstoreconnect.apple.com/access/api](https://appstoreconnect.apple.com/access/api) → tab
**Keys** → **Generate API Key** → role **Developer** (đủ quyền notarize, không cần Admin) →
tải file `AuthKey_<KeyID>.p8` (**chỉ tải được 1 lần duy nhất** — mất phải tạo key mới). Ghi
lại **Key ID** và **Issuer ID** hiện trên trang đó.

> Vì sao không dùng Apple ID + app-specific password (cách cũ hơn)? API Key không bị ảnh
> hưởng khi đổi mật khẩu Apple ID hay bật/tắt 2FA — ổn định hơn cho CI chạy tự động lâu dài.
> `scripts/sign-and-notarize.sh` vẫn hỗ trợ cả 2 cách nếu bạn thấy cách kia tiện hơn.

## 4. Thêm secrets vào GitHub repo — `theminh207/mindful-key`

**Quan trọng:** đây LÀ repo GitHub khác với `sonpiaz/haynoi` (khác owner) — secrets của
haynoi **không tự động dùng chung** dù cùng 1 tài khoản Apple Developer đứng sau. Phải khai
báo lại ở đây.

Vào `github.com/theminh207/mindful-key` → **Settings** → **Secrets and variables** → **Actions**
→ **New repository secret**, thêm đủ 7 secret sau:

| Tên secret | Giá trị |
|---|---|
| `APPLE_CERTIFICATE_P12_BASE64` | `base64 -i DeveloperIDApplication.p12 \| pbcopy` rồi dán |
| `APPLE_CERTIFICATE_PASSWORD` | mật khẩu đặt lúc Export .p12 ở bước 1 |
| `APPLE_SIGNING_IDENTITY` | `"Developer ID Application: Tên bạn/công ty (TEAMID)"` — lấy đúng chuỗi bằng `security find-identity -v -p codesigning` **trên máy đang giữ cert** |
| `APPLE_TEAM_ID` | Team ID ở bước 2 |
| `APPLE_API_KEY_ID` | Key ID ở bước 3 |
| `APPLE_API_ISSUER_ID` | Issuer ID ở bước 3 |
| `APPLE_API_KEY_P8_BASE64` | `base64 -i AuthKey_XXXX.p8 \| pbcopy` rồi dán |

Nếu có `gh` CLI local (`brew install gh && gh auth login`) có thể set thẳng bằng lệnh, VD:
```bash
base64 -i DeveloperIDApplication.p12 | gh secret set APPLE_CERTIFICATE_P12_BASE64
```
để không phải copy/paste nội dung nhạy cảm qua clipboard nhiều bước — chạy lệnh này ngay
trên máy của bạn (KHÔNG dán nội dung .p12/.p8 vào chat hay để lộ trong lịch sử lệnh).

## 5. Test cục bộ trước khi tin tưởng CI (khuyên làm)

Nếu máy này (hoặc máy đang giữ cert) import được `.p12` vào Keychain:

```bash
security find-identity -v -p codesigning   # xác nhận thấy "Developer ID Application: ..."

export APPLE_SIGNING_IDENTITY="Developer ID Application: ... (TEAMID)"
export APPLE_TEAM_ID="TEAMID"
export APPLE_API_KEY_ID="..."
export APPLE_API_ISSUER_ID="..."
export APPLE_API_KEY_PATH="/path/to/AuthKey_XXXX.p8"

bash scripts/release.sh
```
Ra đủ asset trong `release-out/`. Kiểm bằng `spctl -a -vv release-out/MindfulKey.dmg` —
phải thấy `accepted, source=Notarized Developer ID`.

Muốn build+đóng gói thử KHÔNG ký thật (nhanh, không cần cert) — dùng như trước giờ vẫn làm:
```bash
SKIP_SIGN=1 bash scripts/release.sh
```

## 6. Quy trình phát hành thật (sau khi có đủ secrets ở bước 4)

1. Bump `VERSION` trong `version.env`.
2. Đổi `## [Unreleased]` trong `CHANGELOG.md` thành `## [X.Y.Z] - YYYY-MM-DD`, thêm mục
   `## [Unreleased]` rỗng mới lên đầu cho lần sau (đúng quy ước Keep a Changelog).
3. Commit 2 file trên.
4. `git tag vX.Y.Z && git push origin main --tags` (hoặc `git push origin vX.Y.Z` nếu chỉ
   muốn đẩy tag).
5. GitHub Actions (`release.yml`) tự chạy — theo dõi ở tab **Actions**. Xong sẽ thấy Release
   mới ở tab **Releases**, đúng cấu trúc như ảnh tham chiếu haynoi.

## Còn thiếu so với haynoi (biết trước, không phải sự cố)

- **Auto-update Sparkle** (`appcast.xml` được đổ dữ liệu tự động) — app hiện chưa gắn Sparkle
  SDK, nên chưa làm `make_appcast.sh`. Xem `scripts/README.md` mục "Còn thiếu".
- File tên ổn định `MindfulKey.dmg` (bản mới nhất, link không đổi) hiện chỉ là **bản copy nội
  dung y hệt** `MindfulKey-X.Y.Z.dmg`, publish lại mỗi release — đúng cách haynoi làm (2 file
  `Haynoi-0.3.7.dmg` + `Haynoi.dmg` trong ảnh tham chiếu cũng trùng SHA256 với nhau).
  **[2026-07-17] Nay đã có người dùng:** nút "Tải cho macOS" ở `site/index.html` trỏ thẳng
  `releases/latest/download/MindfulKey.dmg`. Trước đó nút trỏ trang Releases còn `site/README.md`
  thì ghi là trỏ file — tài liệu nói dối suốt, và bản copy này thực tế chẳng ai dùng.
