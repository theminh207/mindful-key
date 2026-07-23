# AGENTS.md

> File này dành cho **MỌI AI coding agent** mở repo này — Antigravity, Cursor, Copilot, Codex CLI,
> Windsurf, hay bất kỳ tool nào đọc quy ước `AGENTS.md`. Không phụ thuộc cơ chế riêng của Claude
> Code (skill/sub-agent routing) — mọi lệnh dưới đây chạy được bằng `bash`/`make`/`git` thuần.
>
> Nếu bạn là **Claude Code**: đọc `CLAUDE.md` (đầy đủ hơn — có routing 4 sub-agent chuyên biệt
> engine/mood/platform-shell/iOS). File này là bản trích đã tool-agnostic hoá từ đó, tập trung vào
> phần **kiến trúc + CI/CD/release** — thứ agent nào cũng cần biết trước khi đụng vào repo.

## Dự án này là gì

**mindful-keyboard / mindful-key** — bộ gõ Tiếng Việt "chánh niệm", fork engine OpenKey (Mai Vũ
Tuyên, GPL v3). Định vị: **người gác cổng cảm xúc** — chặn gửi tin lúc đang giận trước khi gửi đi,
không phải "bộ gõ + AI" thông thường. 3 vỏ song song: macOS (hạng nhất) → Windows → iOS (keyboard
extension, mandate cố ý hẹp: chỉ nhật ký + nhắc thụ động, không gác cổng gửi tin).

## Bất khả xâm phạm — đọc trước khi đụng UI/nhận diện

- ❌ KHÔNG đèn đỏ/xanh mã hoá cảm xúc · KHÔNG emoji chấm điểm · KHÔNG gamification (streak/điểm/huy
  hiệu) · KHÔNG copy khiển trách.
- ✅ Nhận diện = con sóng `~` (dấu ngã), biến hình theo **BIÊN ĐỘ** (cường độ, KHÔNG phải valence
  tích cực/tiêu cực — quyết định rõ ràng, xem `bmad-output/decision-log.md` mục 2026-07-20 "giữ 1
  trục biên độ"). Sắc độ trung tính, không bão hoà.
- **GPL v3**, giữ credit Mai Vũ Tuyên (OpenKey gốc) ở mọi màn Giới thiệu/header file liên quan.
- **Riêng tư mặc định** — không gửi nội dung gõ đi đâu; dữ liệu cảm xúc mã hoá tại máy (AES-256 +
  Keychain), có consent gate.
- Chạm nhận diện/pháp lý mà mơ hồ → **hỏi chủ dự án**, đừng tự quyết trong im lặng. Bản đầy đủ:
  `docs/AGENT-BRIEF.md`.

## Kiến trúc: "1 bộ não + nhiều vỏ"

```
core/engine/      C++ thuần, dùng chung MỌI OS (Telex/VNI, macro gõ tắt, đổi bảng mã). KHÔNG đụng
                  OS-specific API. Test: `make test-core` (xem mục Lệnh dev bên dưới).
core/mood/        C++ thuần, lớp cảm xúc (send-risk lexicon, mood buffer, câu quan sát). KHÔNG
                  side-effect, KHÔNG tự đọc I/O — nơi gọi (vỏ) chịu trách nhiệm.
platforms/apple/macos/    Vỏ macOS (Objective-C/++, CGEventTap, AppKit).
platforms/windows/        Vỏ Windows (Win32 C++, GDI+, keyboard hook).
platforms/apple/ios/      Vỏ iOS (Custom Keyboard Extension, App Group).
```

**Ranh giới CỨNG:** lỗi/tính năng riêng 1 OS → sửa ở `platforms/<os>/`. **KHÔNG sửa `core/`** để vá
lỗi riêng 1 vỏ — đó là bộ não dùng chung, đụng vào là ảnh hưởng mọi OS khác.

## Lệnh dev thường dùng

**macOS** (máy dev chính, mọi `make` target chạy từ đây):
```bash
make test          # test-core + test-macos + test-ios — PHẢI xanh trước mọi commit đụng core/vỏ
make test-core     # riêng regression engine (Telex/VNI + send-risk + phrasing) — nhanh nhất, chạy
                    # thường xuyên nhất khi chỉ đụng core/engine hoặc core/mood
make build         # generate (XcodeGen sinh .xcodeproj) rồi xcodebuild app macOS Debug, ký ad-hoc
make install       # build rồi THAY bản ở /Applications — giữ máy chỉ có ĐÚNG 1 bản (tự pkill bản
                    # cũ trước khi ditto). ⚠️ chữ ký mới → macOS thu hồi quyền Accessibility/Input
                    # Monitoring, phải cấp lại trong System Settings.
make run           # install rồi open — chạy ĐÚNG bản mà Spotlight/Finder sẽ mở
make doctor        # quét MỌI bản MindfulKey.app lạc trên máy (/Applications, DerivedData cũ, tiến
                    # trình đang chạy) — dùng cái này TRƯỚC KHI kết luận "sửa rồi mà vẫn y như cũ",
                    # thủ phạm kinh điển là đang chạy nhầm bản cài cũ chứ không phải code sai
make brand-lint    # 0 vi phạm nhận diện (đỏ/xanh cảm xúc, emoji chấm điểm, gamification, màu
                    # hardcode ngoài brand/tokens.json) — cổng CỨNG, không phải gợi ý
make version       # in VERSION từ version.env (nguồn phiên bản DUY NHẤT)
make clean         # rm -rf platforms/apple/build/ + xoá .xcodeproj sinh ra + test_engine
```

**Windows** (máy dev KHÔNG có MSVC — Windows chỉ compile thật trên CI hoặc máy Windows thật; kiểm
cú pháp cục bộ trước khi push bằng mingw-w64, phá vòng lặp "sửa mù → chờ CI 10 phút"):
```bash
brew install mingw-w64   # 1 lần
cd platforms/windows/win32/MindfulKey/MindfulKey
x86_64-w64-mingw32-g++ -fsyntax-only -std=gnu++14 -DUNICODE -D_UNICODE -DWIN32 -D_WIN32 -D_WIN64 \
  -I. -I../../../../../core/engine -I../../../../../core/mood <file>.cpp
```
Dùng `-std=gnu++14` (khớp mặc định MSVC — `c++17` gây lỗi giả với `std::byte`/`rpcndr.h`). Lọc
nhiễu header mingw không phải lỗi thật: `rpcndr | gdiplus | PROPID | 'byte' ambiguous | cs_byte`.

## CI/CD & Release

Nguồn version **DUY NHẤT**: `version.env` (`VERSION=X.Y.Z`). Nhật ký đổi: `CHANGELOG.md` (Keep a
Changelog — `## [X.Y.Z]` + `### Added/Fixed/Changed`).

**Preflight bắt buộc trước khi push** (không có ngoại lệ, kể cả thay đổi "nhỏ"):
```bash
make test && make build && make brand-lint
```

**5 workflow trong `.github/workflows/`:**

| File | Trigger | Việc |
|---|---|---|
| `macos.yml` | push `main` + mọi PR | chạy tay `tests/core/build.sh` + `test_engine` (⚠️ KHÔNG gọi `make test-core` — thiếu `test_send_risk`/`test_phrasing`, xem "Bẫy" bên dưới) rồi `xcodebuild` Debug ký ad-hoc |
| `windows.yml` | push/PR chạm `core/**`, `platforms/windows/**`, `tests/core/**` | build MSVC Debug+Release trên `windows-latest` (~2 phút) — CHỈ compile-verify, KHÔNG release |
| `brand-lint.yml` | push + PR | 0 vi phạm nhận diện (đỏ/xanh, emoji, gamification, màu ngoài token) |
| `release.yml` | push tag `v*` | build universal macOS (arm64+x86_64) + bộ cài Windows → ký thật nếu có đủ secrets (Developer ID + SignPath) → notarize → đóng `.dmg`/`.zip`/`.dSYM.zip`/`.exe` → **tự đăng GitHub Release** (không phải draft, không cần bấm Publish tay) |
| `draft-janitor.yml` | push đụng chính file này | quét & xoá MỌI release **draft** `v*` còn sót (sản phẩm phụ của lần chạy dở) — KHÔNG BAO GIỜ đụng release đã publish |

**Cắt 1 bản release thật:**
```bash
# 1. Bump version.env: VERSION=X.Y.Z
# 2. Thêm mục "## [X.Y.Z]" lên đầu CHANGELOG.md
# 3. Commit 2 file trên
git tag vX.Y.Z
git push origin main --tags
# 4. release.yml tự chạy — theo dõi: gh run watch <run-id>, hoặc tab Actions
# 5. Xong tự publish (không phải draft) — asset thiếu ký thật vẫn ra được, gắn --prerelease
#    + cảnh báo Gatekeeper/SmartScreen ngay trong release notes (không giấu rủi ro)
```

**Test cục bộ KHÔNG cần ký thật** (dùng thường xuyên để verify trước khi tin CI):
```bash
SKIP_SIGN=1 bash scripts/release.sh   # build + đóng gói macOS đầy đủ, bỏ qua Apple sign/notarize
```
Ra asset ở `release-out/`. Kiểm nhanh: mount thử `.dmg`, `codesign -dv` (nếu ký ad-hoc) hoặc
`spctl -a -vv` (nếu ký thật — phải thấy `accepted, source=Notarized Developer ID`).

**Bẫy đã root-cause — đọc trước khi debug lại từ đầu** (bản đầy đủ: `docs/RELEASE.md` +
`CHANGELOG.md` mục Fixed của các bản 0.4.9–0.4.14, ghi lại từng sự cố CI/release có thật):
- **GitHub Actions secrets là PER-REPO** — không tự dùng chung dù cùng 1 tài khoản Apple Developer
  hay cùng người đứng sau nhiều repo khác nhau.
- Windows chỉ compile được bằng MSVC thật; mingw-w64 syntax-check bắt phần lớn lỗi nhưng **không
  thay thế hoàn toàn** CI thật — vẫn phải chờ `windows.yml`/`release.yml` xanh trước khi yên tâm.
- File Windows dùng GDI+ phải `#include <objidl.h>` **TRƯỚC** `<gdiplus.h>` (PROPID) — thiếu thì
  lỗi nổ ra trong header của Microsoft, dễ hiểu lầm là SDK hỏng.
- `release.yml` xoá MỌI draft `v*` trước khi đăng bản mới trong CÙNG 1 lần chạy — `draft-janitor.yml`
  là công cụ quét ĐỘC LẬP, chỉ chạy khi tự đẩy 1 commit đụng vào chính file đó (không lịch tự động).
- Thiếu secret ký (Apple `APPLE_SIGNING_IDENTITY` / Windows SignPath) → build tự lùi về **ad-hoc**
  (`continue-on-error`, không chặn release) — người tải sẽ bị Gatekeeper/SmartScreen cảnh báo, ghi
  rõ trong release notes chứ không giấu.
- **`macos.yml` đã LỆCH khỏi `make test-core`** — CI chỉ chạy `test_engine` gốc (viết tay trong
  YAML), không chạy `test_send_risk`/`test_phrasing` mà `make test-core` local đã có từ lâu. Nghĩa
  là 2 test đó XANH cục bộ nhưng KHÔNG được CI xác nhận trên mọi PR. Cân nhắc sửa `macos.yml` để
  gọi thẳng `make test-core` thay vì chép tay 2 dòng — tránh lệch tiếp khi thêm test mới.

**Bản đầy đủ** (checklist lấy chứng chỉ Apple Developer ID + App Store Connect API Key, cấu trúc
đặt tên 6 asset, cách thêm 7 secrets vào GitHub, còn thiếu gì so với pipeline tham chiếu):
`docs/RELEASE.md`.

## Nếu bạn cần thêm ngữ cảnh

- `CLAUDE.md` — bản đầy đủ cho Claude Code (Hiến chương trích dẫn, routing 4 sub-agent chuyên biệt,
  kỷ luật commit/push, work discipline "4 Kỹ").
- `docs/AGENT-BRIEF.md` — Hiến chương đầy đủ (nhận diện/pháp lý/riêng tư).
- `docs/OPENKEY-MAP.md` — bản đồ code engine gốc theo dòng số cụ thể.
- `docs/TEST_MATRIX.md` — sổ hành vi→bằng chứng (Engine/macOS/Windows/E2E).
- `docs/RELEASE.md` — checklist release thật, chi tiết hơn phần CI/CD ở trên.
