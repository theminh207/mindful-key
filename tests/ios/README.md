# tests/ios/

**Sở hữu:** đội iOS — test riêng vỏ iOS. Không đụng `tests/core/`.

**Chạy:** `make test-ios` (hoặc `make test` chạy chung cả core/macos/ios).

## Trạng thái

- **Bridge test (`bridge_test.mm`)** — ĐÃ CÓ, wired vào `make test-ios` (`tests/ios/build.sh`).
  Tái dùng 5 ca Telex→Unicode của `tests/core/test_engine.cpp` nhưng gõ QUA `KeyboardBridge`
  (Mốc B). `make test-ios` hiện chạy thật, exit 0, KHÔNG còn no-op.
- **Build-smoke** (`tests/ios/build_smoke.sh`: `xcodegen generate` + `xcodebuild -scheme
  MindfulKeyKeyboard -sdk iphonesimulator build`) — ĐÃ wire vào `make test-ios` (story 1.8).
  Bắt lỗi mà bridge test host không bắt (API chỉ có trên iOS, project.yml hỏng). `make test-ios`
  exit non-zero nếu bridge test HOẶC build-smoke lỗi (verify: bẻ scheme → exit 2, trả lại → 0).

## Bằng chứng build-verification (story 1.5 — đóng Risk R5 của tech-spec)

Chạy thật 2026-07-11 (Xcode 26.6, iPhoneSimulator SDK 26.5), từ `platforms/apple/`:

| Lệnh | Kết quả |
|---|---|
| `xcodegen generate` | exit 0 — sinh `MindfulKey.xcodeproj`, đủ 3 scheme (MindfulKey, MindfulKeyiOS, MindfulKeyKeyboard) qua `xcodebuild -list` |
| `xcodebuild -scheme MindfulKeyKeyboard -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build` | **BUILD SUCCEEDED** — 0 error/warning. Extension (core/engine + core/mood + KeyboardBridge) compile+link thật cho iOS Simulator |
| `xcodebuild -scheme MindfulKeyiOS -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build` | **BUILD SUCCEEDED** — 0 error/warning. Container app + embed extension |
| `make build` (macOS `MindfulKey`) | **BUILD SUCCEEDED** — NFR-08 giữ (chỉ warning cũ `ld: ignoring duplicate libraries: '-lc++'`, không phải warning mới) |

→ **Risk R5 ("YAML iOS chưa chạy thử thật") ĐÓNG bằng bằng chứng chạy thật**, không phải giả định.
`project.yml` KHÔNG cần sửa (2 target iOS build sạch nguyên trạng).

## Kiểm thủ công còn lại (cần simulator/thiết bị + máy chủ dự án)
- Gõ "vieetj"→"việt" trong Notes VÀ Zalo (story 1.2 AC).
- Đo RAM extension bằng Instruments < trần jetsam ~48–60MB — ghi kết quả vào file này sau mỗi lần thử.
