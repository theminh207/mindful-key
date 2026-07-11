# 00 — Sổ cái Input (Input Ledger): đã có gì / cần hoàn thiện gì

> **Pha 0** của gói phân tích sản phẩm iOS. Mục đích: đối chiếu *tài liệu tuyên bố* ↔ *sự thật
> trong code*, để mọi kết luận "đã xong / chưa xong" ở các pha sau đều **truy được về file thật**,
> không tin tài liệu suông. Đây là nền cho cột trạng thái ✅/🟡/⬜ trong `ROADMAP.md`.
>
> **Ngày lập:** 2026-07-10 · **Nguồn:** đọc trực tiếp repo `mindful-key/` + `git`.

---

## 1. Bằng chứng code thật (đã đọc từng file)

### 1.1 Build config — `platforms/apple/project.yml`
| Sự thật | Bằng chứng | Trạng thái |
|---|---|---|
| Có target `MindfulKeyiOS` (application, iOS) | `project.yml:87-128` — sources `ios/App` + `shared`, dep `MindfulKeyKeyboard` (embed), bundle `vn.gnh.mindfulkey.ios`, iPhone-only, ad-hoc | ✅ đã có |
| Có target `MindfulKeyKeyboard` (app-extension, iOS) | `project.yml:130-172` — sources `core/engine` + `core/mood` + `ios/KeyboardExtension` + `shared`, bundle `...ios.keyboard` | ✅ đã có |
| Deployment target iOS 16.0 khai báo | `project.yml:9` | ✅ đã có |
| Target macOS `MindfulKey` giữ nguyên | `project.yml:16-82` | ✅ không đụng |

### 1.2 Vỏ iOS — `platforms/apple/ios/**` (committed, "Mốc A")
| File | Vai trò thật | Trạng thái |
|---|---|---|
| `App/AppDelegate.{h,m}`, `ViewController.{h,m}`, `main.m`, `Info.plist` | Container app skeleton tối thiểu | 🟡 khung trống — chưa có onboarding/Full Access UI |
| `KeyboardExtension/KeyboardBridge.{h,mm}` | Định nghĩa 21 biến `extern int` engine (từ `EngineDefaults.h`), gọi `vKeyInit()` một lần qua `dispatch_once`. **Cố ý KHÔNG set `vOnWordCommitted`** | 🟡 mới init — chưa nối `vKeyHandleEvent` để gõ |
| `KeyboardExtension/KeyboardViewController.mm` | Bàn phím tự vẽ QWERTY 3 hàng + hàng dưới (🌐/space/⌫) bằng `UIStackView` | 🟡 **chèn ký tự THÔ** — `letterKeyTapped:` gọi thẳng `insertText:letter` (dòng 115-118), **chưa qua `core/engine`** |

> 🔑 **Điểm mấu chốt:** đây là **Mốc A** theo comment trong `KeyboardViewController.mm:3-8`.
> `KeyboardBridge_Init()` gọi ở `viewDidLoad` (dòng 31) chỉ để **chứng minh engine sống trong
> tiến trình extension** (gỡ rủi ro lớn nhất của SPEC). **Mốc B** — nối `vKeyHandleEvent` → gõ
> Telex ra dấu (chính là FR-002) — **CHƯA làm**. Nên tiêu chí Success "gõ ra tiếng Việt có dấu"
> **CHƯA đạt**.

### 1.3 Code dùng chung Apple — `platforms/apple/shared/**` (Nhịp 0, committed)
| File | Vai trò | Trạng thái |
|---|---|---|
| `EngineDefaults.h` | 20+ hằng số config mặc định engine (rút từ `AppDelegate.m` macOS) | ✅ đã rút |
| `EngineKeyMap.h` + `EngineKeyMap.mm` | Bảng char → `KEY_x` (rút từ `OpenKey.mm` macOS) | ✅ đã rút |
| `BrandPalette.h` | Giá trị hex màu gốc (nguồn màu — DESIGN.md không đặt lại) | ✅ đã rút |

> Khớp đúng ghi nhận decision-log "Nhịp 0 rút được RẤT ÍT nguyên xi" — chỉ 3 thứ (key map,
> config defaults, hex màu). Mọi `.mm` macOS khác gắn chặt AppKit/CGEventTap → không rút được.

### 1.4 Test iOS — `tests/ios/**`
| Sự thật | Trạng thái |
|---|---|
| `tests/ios/` chỉ có `README.md`, **không có test thật** | 🟡 no-op — `make test-ios` chưa chạy test bridge (FR-005 chưa đạt) |

### 1.5 `core/` — đóng băng
`git diff core/` **rỗng** — `core/engine`, `core/mood` không nằm trong git status. ✅ đúng cam kết.

---

## 2. Bằng chứng thực nghiệm đã có (không phải suy diễn)

| Câu hỏi rủi ro | Kết quả thực nghiệm | Nguồn |
|---|---|---|
| `core/engine` build được cho iOS không? | ✅ **CÓ, 0 thay đổi** — compile 5 file `core/engine/*.cpp` cho `arm64-apple-ios16.0-simulator`, ra Mach-O **198KB** (`__TEXT` 112KB + `__DATA` 16KB) | `tech-spec.md:196-214` |
| Engine size có phải rủi ro RAM chính không? | ❌ Không — 198KB là muối bỏ biển so với trần jetsam ~48-60MB. Rủi ro thật ở **UIKit overhead runtime** của bàn phím tự vẽ | `tech-spec.md:146-159` |
| `platforms/mac.h` có API AppKit không? | ❌ Không — chỉ là bảng `#define KEY_A 0`... (số nguyên thuần), tên "mac" gây hiểu lầm | `tech-spec.md:210-214` |

---

## 3. ⚠️ Doc-drift đã phát hiện (tài liệu lạc hậu so với code — cần vá, KHÔNG sửa trong pha phân tích)

| File | Ghi (sai) | Thực tế | Đề xuất |
|---|---|---|---|
| `platforms/apple/ios/README.md` | "Chưa mở code… iOS làm SAU CÙNG" | Đã có 11 file code committed (App + KeyboardExtension) | Cập nhật sang "Round 1 Mốc A đang chạy" |
| `platforms/apple/shared/README.md` | "Chưa mở" | Đã có 4 file (EngineDefaults/EngineKeyMap/BrandPalette) | Cập nhật liệt kê file đã rút |
| `tech-spec.md §Key Components #1` (dòng 238) | "Đề xuất — chưa chạy qua `xcodegen generate` thật" | Target iOS đã tồn tại thật trong `project.yml` (FR-001 làm một phần ở Mốc A) | Đối chiếu lại — R5 rủi ro giảm |
| `bmad-output/ios/README.md` | (mô tả thư mục "được chứa epics/story…") | Thư mục nay đầy artifact + có `analysis/` mới | Cập nhật khi chốt analysis |

> Ba README này chỉ *ghi nhận* ở đây. Việc vá là follow-up riêng, chờ chủ dự án duyệt (đưa vào
> `09-bmad-reconcile.md` → decision queue), không sửa lén trong lúc phân tích (kỷ luật Surgical Changes).

---

## 4. Tổng kết trạng thái Round 1 (walking skeleton)

| Hạng mục Round 1 | FR | Trạng thái | Còn thiếu |
|---|---|---|---|
| Engine sống trong extension | (nền FR-002) | ✅ đã có | — (đã chứng minh) |
| Target iOS trong project.yml | FR-001 | ✅ đã có | verify `xcodegen generate` thật (R5) |
| Gõ Telex ra dấu qua engine (Mốc B) | FR-002 | 🟡 chưa | nối `vKeyHandleEvent` trong `KeyboardViewController` |
| Onboarding + Full Access (2 màn) | FR-003 | ⬜ chưa | UI container + copy (thiếu mockup — open item) |
| App Group heartbeat detection | FR-004 | ⬜ chưa | `AppGroupBridge` + entitlement App Group |
| `tests/ios` test thật | FR-005 | 🟡 chưa | test bridge-layer, tái dùng case `tests/core` |
| `git diff core/` rỗng | (ràng buộc) | ✅ giữ | — |

**Kết luận Pha 0:** Round 1 mới đi được ~30% (khung + chứng minh rủi ro), phần *chứng minh giá
trị người dùng* (gõ ra dấu thật, onboarding) chưa xong. Đây là điểm xuất phát để `ROADMAP.md`
đặt nhãn trạng thái cho cả tầm nhìn lớn.

---
*Pha 0/4 — gói phân tích sản phẩm iOS. Kế tiếp: `01-discovery-findings.md`.*
