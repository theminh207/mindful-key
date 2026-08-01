# 06 — Operations

> Build, kiểm thử, ký, phát hành, cài đặt. Tầng này mô tả **quy trình đang chạy**; các bước cần
> quyền truy cập Apple Developer Program hoặc GitHub repo settings nằm chi tiết ở
> `tasks/RELEASE.md`, `tasks/WINDOWS-CODE-SIGNING.md` và `tasks/CODE-SIGNING-POLICY.md`.

## 1. Lệnh hằng ngày

```bash
make help          # liệt kê mọi việc làm được
make test          # regression core + macOS + iOS
make build         # build app macOS, ký ad-hoc
make run           # build, cài, mở đúng bản vừa dựng
make doctor        # quét bản .app lạc trên máy
make brand-lint    # ràng buộc nhận diện
make hooks         # bật git pre-commit, chạy một lần mỗi máy
```

`make doctor` tồn tại vì một lỗi kinh điển: sửa code, build lại, mở app từ Spotlight và thấy lỗi
vẫn còn — do máy còn một bản `.app` cũ ở chỗ khác. `make run` cài đè để máy chỉ giữ đúng một bản.

Build ad-hoc **thu hồi quyền Accessibility và Input Monitoring** mỗi lần dựng lại. Cần cấp lại thủ
công trước khi thử hành vi gõ. Chạy `make dev-cert` một lần mỗi máy để bản dev giữ quyền qua các lần
build.

## 2. Sinh lại nhận diện

```bash
make brand                 # SVG nguồn → PNG, .icns
make brand-platform        # icon Windows, Android, Linux
make brand-palette         # bảng màu mọi vỏ từ brand/tokens.json
make brand-palette-check   # báo đỏ khi bản sinh lệch nguồn (CI chạy cái này)
make public-brand          # bộ nhận diện công khai cho repo public
```

Đổi màu hoặc đổi dấu ấn là **việc lớn**: phải bump phiên bản brand, ghi CHANGELOG, và chạy lại **cả
hai** `make brand` (asset trong app) lẫn `make public-brand` (mặt tiền) để hai bên không lệch nhau.

Yêu cầu môi trường cho việc xuất asset: `rsvg-convert` (qua `brew install librsvg`), `iconutil`,
`sips`.

## 3. Kiểm thử

| Lệnh | Phạm vi |
|---|---|
| `make test-core` | bộ não C++: engine Telex/VNI, chấm điểm send-risk (hai bộ sau gỡ theo #13, thay bằng ca đo nhịp gõ ở #6/#7) |
| `make test-macos` | vỏ macOS: chuỗi gõ → nhịp → ghi → đọc, cô lập kho và Keychain |
| `make test-ios` | vỏ iOS: bridge Telex, mood bridge, settings bridge, build-smoke extension |

Vỏ Windows chưa có bộ test tự động tương đương. Bù lại bằng hai thứ: CI biên dịch bằng MSVC thật, và
kịch bản nghiệm thu tay ở `tasks/QA-WINDOWS.md`. Khi viết code Windows trên máy macOS, cách bắt lỗi
cú pháp sớm là cài `mingw-w64` rồi syntax-check toàn bộ `.cpp` một lượt — CI mỗi lần chỉ báo lỗi đầu
tiên của file đang biên dịch nên sửa xong push lại mới lộ lỗi kế.

## 4. CI

| Workflow | Việc |
|---|---|
| `macos.yml` | `make test` + `xcodebuild` Debug ad-hoc |
| `windows.yml` | MSBuild Debug và Release x64 |
| `brand-lint.yml` | ràng buộc nhận diện |
| `release.yml` | build, ký, notarize, đóng gói, đăng Release nháp |

Không giả định "push xong là ổn" — chờ CI xanh mới yên tâm.

## 5. Phát hành

Gắn tag là GitHub Actions tự dựng cả macOS lẫn Windows và đăng **một Release chung**.

```bash
# 1. bump VERSION trong version.env
# 2. CHANGELOG.md: đổi [Unreleased] thành [X.Y.Z] - YYYY-MM-DD, thêm [Unreleased] rỗng mới
# 3. commit hai file trên
git tag vX.Y.Z && git push origin <nhánh> --tags
```

Thử cục bộ trước khi tin CI:

```bash
SKIP_SIGN=1 bash scripts/release.sh   # đóng gói, không ký thật
bash scripts/release.sh               # ký thật, cần đủ biến môi trường
```

Kiểm bản đã ký: `spctl -a -vv release-out/MindfulKey.dmg` phải trả về
`accepted, source=Notarized Developer ID`.

### Luật đặt tên asset

Mọi asset mang **tên app cộng số phiên bản**. Ngoại lệ duy nhất là hai bản copy tên cố định phục vụ
nút tải trên trang web — chúng tồn tại chính vì cái tên không bao giờ đổi.

| Asset | Vai trò |
|---|---|
| `MindfulKey-X.Y.Z.dmg` | bản macOS theo phiên bản |
| `MindfulKey.dmg` | copy y hệt, tên cố định cho nút tải |
| `MindfulKey-X.Y.Z-universal.zip` | bản `.app` nén, universal |
| `MindfulKey-X.Y.Z-universal.dSYM.zip` | ký hiệu debug để giải mã crash log |
| `MindfulKey_X.Y.Z_x64-setup.exe` | bộ cài Windows theo phiên bản |
| `MindfulKey-setup.exe` | copy y hệt, tên cố định cho nút tải |

### Release đăng ra ở dạng nháp

Chạy xong workflow là **chưa ai thấy gì**. Phải vào tab Releases, soi đủ sáu asset, rồi bấm Publish.
Chừng nào chưa bấm thì đường dẫn `releases/latest/download/...` chưa tồn tại và nút tải trên web
gãy.

Đây là lựa chọn có chủ đích: một phiên bản từng chết ba lần liên tiếp ở bước đăng.

## 6. Ký số

**macOS** — Developer ID Application để ký, cộng App Store Connect API Key để notarize. Hai thứ khác
nhau, không dùng lẫn. Chọn API Key thay vì Apple ID kèm mật khẩu ứng dụng vì API Key không bị ảnh
hưởng khi đổi mật khẩu hay bật tắt xác thực hai lớp — ổn định hơn cho CI chạy lâu dài. Cần bảy
secret trong GitHub repo settings; danh sách đầy đủ ở `tasks/RELEASE.md` §4.

**Windows** — đi đường SignPath Foundation, miễn phí cho dự án mã nguồn mở. Đánh đổi đã chấp nhận:
dòng nhà phát hành mà SmartScreen hiện lúc cài sẽ là "SignPath Foundation", không phải tên chủ dự
án. Muốn hiện tên riêng thì phải mua chứng chỉ EV có phí kèm HSM cho CI — để ngỏ, chưa chọn.

Tệp `tasks/CODE-SIGNING-POLICY.md` là tài liệu **công khai** theo yêu cầu của chương trình
SignPath — không sửa nội dung nếu chưa đối chiếu lại với điều kiện của họ.

## 7. Cài đặt

Cách được khuyến nghị cho người dùng thật là `scripts/install-macos.sh`, vì `curl` không dán cờ
quarantine — cờ đó do trình duyệt dán, và nó chính là nguyên nhân một người dùng thật từng gặp thông
báo *"MindfulKey is damaged"* khi tải qua trình duyệt. Cơ chế đầy đủ và cách xử lý:
`tasks/INSTALL-MACOS-BETA.md`.

## 8. Landing page

Sống ngay trong monorepo tại `site/`, là HTML tĩnh **không build**. Triển khai bằng Coolify trỏ
thẳng vào repo với Base Directory là `site` và Build Pack Static.

Điểm mấu chốt để không dựng thừa: bật auto-deploy nhưng đặt **Watch Paths = `site/**`**, nhờ vậy chỉ
khi landing đổi mới triển khai lại; commit engine hay app không kích build.

## 9. Chưa có

- **Auto-update Sparkle** — `appcast.xml` chưa được đổ dữ liệu tự động vì app chưa gắn Sparkle SDK.
- **Bộ test tự động cho vỏ Windows.**
- Chi tiết những gì còn thiếu so với repo tham chiếu: `scripts/README.md`.
