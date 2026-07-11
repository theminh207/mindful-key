# apple/shared

Code Objective-C/Swift **dùng chung** giữa vỏ macOS và iOS. **Đã rút (Nhịp 0, committed):**

- `EngineDefaults.h` — 20+ hằng số config mặc định của engine (rút từ `AppDelegate.m` macOS).
- `EngineKeyMap.h` / `EngineKeyMap.mm` — bảng char → `KEY_x` (rút từ `OpenKey.mm` macOS).
- `BrandPalette.h` — giá trị hex màu gốc (nguồn màu; `bmad-output/ios/DESIGN.md` không đặt lại).

⚠️ **Dùng chung với đội macOS** — chỉ THÊM file mới, KHÔNG sửa file macOS đang dùng; chạy
`make build` (macOS) sau mỗi thay đổi. `core/engine` + `core/mood` (C++ thuần) vẫn là phần
dùng-chung ở tầng thấp hơn.

Xem thứ tự lộ trình nền tảng: `../README.md`.
