# ROADMAP-WINDOWS — nâng vỏ Windows lên ngang macOS rồi mới đóng gói

**Lập ngày:** 2026-07-16 · **Chốt bởi:** chủ dự án ("nâng cấp toàn bộ rồi mới đóng gói")
**Chuẩn hành vi:** `platforms/apple/macos/` — mọi module Windows phải khớp HÀNH VI bản Mac.
**Luật tối cao:** `docs/AGENT-BRIEF.md` (HIẾN CHƯƠNG). Mơ hồ về nhận diện/pháp lý → hỏi chủ dự án.

---

## 0. Trạng thái xuất phát (đo thật, 2026-07-16)

| | macOS | Windows |
|---|---|---|
| Lớp cảm xúc + nhận diện | **6.669 dòng** (17 file) | **373 dòng** (2 file) — ~5% |
| Gọi `core/mood` | có (`MoodBuffer`, `SendRiskAnalyzer`) | **KHÔNG file nào gọi** |
| Đã từng biên dịch | có (CI mỗi push) | **CHƯA BAO GIỜ** |

Vỏ Windows hiện có: engine gõ chữ (dùng chung core) + `MoodWatch.cpp`/`Bell.cpp` **đời cũ**
(tự gom câu thay vì gọi `MoodBuffer`; dán nhãn "GIẬN/BUỒN/MỆT/LO" viết hoa — nghịch HIẾN CHƯƠNG
§2.2 vốn chốt nhận diện là con sóng `~` một trục phẳng↔gợn, không phân loại).

**Tài sản sẵn có mà chưa ai cắm vào** (khảo sát 2026-07-16 — đừng làm lại từ đầu):
- `brand/platform/windows/AppIcon.ico` — icon đúng brand, đã sinh sẵn từ SVG nguồn (10/7).
- `OpenKey.cpp:172` — `SetWindowsHookEx(WH_KEYBOARD_LL)`, đúng cơ chế gác cổng cần.
- `OpenKeyHelper.cpp:125` — `GetForegroundWindow` + `GetWindowThreadProcessId`, đúng thứ để biết
  đang gõ vào app nào (bản Mac dùng `NSWorkspace.frontmostApplication.bundleIdentifier`).
- `core/engine/SmartSwitchKey.h` — đã nhận diện app qua chuỗi `bundleId`, Windows đã nuôi sẵn.

---

## 1. Nguyên tắc xuyên suốt

1. **Vỏ KHÔNG chép logic của bộ não.** Gõ chữ → `core/engine`; gom câu → `core/mood/MoodBuffer`;
   chấm điểm → `core/mood/SendRiskAnalyzer`. Vỏ chỉ lo: bắt phím, vẽ, lưu, chính sách hiển thị.
2. **Lỗi riêng Windows sửa ở `platforms/windows/`**, không sửa `core/`.
3. **Rebrand = chuỗi hiển thị.** KHÔNG đổi tên file/class/project/solution.
4. **Nhận diện lấy từ `brand/tokens.json`**, cấm tự chế màu/chữ/hình.
5. **Không tuyên bố "xong" khi chưa có bằng chứng chạy thật** (`docs/TEST_MATRIX.md`).

---

## 2. GIAI ĐOẠN 0 — Dựng lưới an toàn TRƯỚC khi viết UI

> Đây là giai đoạn rẻ nhất và **quan trọng nhất**. Bỏ qua nó = viết ~6.000 dòng UI trong bóng tối.

### 0.1 `brand-lint` đang MÙ với toàn bộ vỏ Windows — chặn cứng

`scripts/brand_lint.py:41` liệt kê `UI_EXT = {".m", ".mm", ".swift", ".h", ".html", ".css", ".js",
".ts", ".tsx", ".kt", ".xml", ".storyboard", ".xib"}` — **không có `.cpp`, `.rc`, `.iss`**.

Hệ quả: 15 file `.cpp` của vỏ Windows **không được quét**. `CLAUDE.md` mô tả brand-lint là ràng
buộc CỨNG "chặn mọi tool/agent, không phụ thuộc có đọc CLAUDE.md hay không" — **điều đó hiện KHÔNG
đúng với Windows**. Cả UI Windows sắp viết sẽ nằm trong `.cpp`, tức là toàn bộ phần dễ vi phạm
nhận diện nhất lại là phần duy nhất không ai gác.

→ **Việc:** thêm `.cpp`, `.rc`, `.iss` vào `UI_EXT`; chạy lint; sửa vi phạm lộ ra (nếu có).
→ **Bằng chứng:** `make brand-lint` quét được file Windows (số file quét tăng từ 133).

### 0.2 Mốc 1 chưa verify — mọi thứ phía sau là giả định

Vỏ Windows chưa từng biên dịch. `.github/workflows/windows.yml` đã viết sẵn (CI build Debug +
Release x64 trên `windows-latest`, có VS 2022 toolset v143 project đòi) nhưng **chưa chạy vì chưa
push**. Port 6.000 dòng lên một vỏ chưa biết có compile nổi không là canh bạc tệ nhất.

→ **Việc:** push → đọc log → sửa tới khi xanh.
→ **Bằng chứng:** CI Windows xanh + `.exe` tải về gõ được tiếng Việt (cần người trên Windows).

### 0.3 Bảng màu brand cho Windows — và một cái bẫy đã từng cắn

Bản Mac lấy màu qua `NSColor colorNamed:` (Asset Catalog) — Windows không có thứ đó.
`platforms/apple/shared/BrandPalette.h` là "data thuần" (hex) cho iOS dùng, **nhưng nó được CHÉP
TAY** ("giá trị hex rút từ `BrandColors.h`"). Tức chuỗi `tokens.json → Assets.xcassets →
BrandPalette.h` **không có ai sinh tự động**.

⚠️ **Đây đúng là mô hình đã đẻ ra bug lexicon** (2 bản chép tay trôi lệch trong 3 ngày, làm iOS mù
với câu có dấu chấm — xem `FRICTION-LOG` 2026-07-16). Thêm bản màu thứ 3 cho Windows bằng cách
chép tay = lặp lại đúng sai lầm vừa mất công đi sửa.

→ **Việc:** sinh header màu Windows **từ `brand/tokens.json`** bằng script (nếp `brand/export-*.sh`),
không chép tay. Cân nhắc sinh luôn cho cả macOS/iOS để dứt điểm — **cần chủ dự án chốt** vì đụng
code 2 đội.
→ **Bằng chứng:** đổi 1 giá trị trong `tokens.json` → chạy script → 3 vỏ đổi theo; `make brand-lint` xanh.

---

## 3. GIAI ĐOẠN 1 — Module 1: MoodWatch (nền của mọi thứ)

Bản Mac: `MoodWatchMac.mm` (nay chỉ còn chính sách vỏ, công thức đã về core).

| Việc | Chi tiết |
|---|---|
| Bỏ `g_words` tự chế | gọi `core/mood/MoodBuffer` (đã có sẵn, `maxWords=15` y hệt) |
| Bỏ quyết-định-bằng-nhãn | gọi `core/mood/SendRiskAnalyzer` → `risk` [0,1], ngưỡng `0.5` |
| Sửa copy | bỏ "GIẬN" viết hoa → giọng bản Mac: *"Câu bạn vừa gõ nghe đang giận. Khoan gửi đã, hít thở 10 giây rồi hãy quyết định nhé."* |
| Chạy ngoài mạch gõ | Mac dùng serial `dispatch_queue`; Windows: thread riêng / thread pool. **TUYỆT ĐỐI không** phân tích ngay trong `keyboardHookProcess` (làm khựng gõ toàn hệ thống) |
| **Bẫy đã cắn 2 vỏ** | `vOnWordCommitted` truyền tham chiếu tới biến CỤC BỘ của `Engine.cpp:463`, chết ngay khi callback return. iOS và macOS đều đã ngã ở đây (macOS crash 10 lần đêm 2026-07-16). Windows **phải copy `wstring` TRƯỚC** khi đẩy sang thread. Xem `FRICTION-LOG` 2026-07-16 |

**Bằng chứng cần có:** CI Windows xanh + test host cho phần chính sách (nếu tách được khỏi Win32).

---

## 4. GIAI ĐOẠN 2 — Module 2: SendGatekeeper (Feature #1)

Đây là **tính năng số 1 của sản phẩm** và Windows đang không có. Tin tốt: hạ tầng đã sẵn.

| Bản Mac | Bản Windows |
|---|---|
| `CGEventTap` (ở `OpenKey.mm`) | `WH_KEYBOARD_LL` — **đã có** (`OpenKey.cpp:172`) |
| `NSWorkspace.frontmostApplication.bundleIdentifier` | `GetForegroundWindow` → `GetWindowThreadProcessId` → `QueryFullProcessImageName` → tên `.exe` — **đã có một nửa** (`OpenKeyHelper.cpp:125`) |
| Allow-list bundle id (`Zalo`, `Discord`) | Allow-list tên exe (`Zalo.exe`, `Discord.exe`) — **cần chủ dự án xác nhận tên tiến trình thật** |
| Nuốt Enter, hiện `NSPanel`, `CGEventPost` gửi lại | Trả `1` từ hook để nuốt, hiện cửa sổ Win32, `SendInput` gửi lại |

**Nhớ:** gác cổng **CỐ Ý không dùng cooldown chung** — luôn hiện khi đủ điều kiện (Feature #1).

---

## 5. GIAI ĐOẠN 3 — Module 3: MoodStore (RỦI RO CAO NHẤT)

`MoodStoreMac.mm` = **921 dòng**, dùng `sqlite3` (174 chỗ) + `CommonCrypto` (AES-256-CBC) +
Keychain. Không có món nào chạy sẵn trên Windows.

| Bản Mac | Bản Windows | Ghi chú |
|---|---|---|
| `libsqlite3` hệ thống | **vendor `sqlite3.c` amalgamation** | Windows 10+ có `winsqlite3.dll` nhưng link bấp bênh. Thêm dependency → **cần chủ dự án chốt** (tiền lệ: đã từ chối SQLCipher vì nặng) |
| `CCCrypt` (CommonCrypto) | **BCrypt / CNG** (`bcrypt.h`) | AES-256-CBC có sẵn trong Windows, không cần thư viện ngoài |
| Keychain (`SecItemAdd`) | **DPAPI** (`CryptProtectData`) | Khoá gắn với tài khoản Windows. Khác mô hình Keychain — **chạm RIÊNG TƯ, cần chủ dự án chốt** |
| `NSUserDefaults` | Registry (đã có `APP_SET_DATA`) | |

**Bắt buộc giữ:** cùng tên cột + cùng `event_type` (`sample`/`checkin`/`note`) như macOS/iOS —
`SYNC-emotion-mechanism-v2.md §A` chốt để nhật ký 3 vỏ cùng dạng. Mã hoá at-rest. Consent gate.

---

## 6. GIAI ĐOẠN 4 — Module 4: Nudge + Bell

- `NudgeCoordinatorMac.mm` (43 dòng) — logic thuần, cooldown 45s, snooze 1h → port thẳng, dễ.
- `BellMac.mm` (232 dòng) — chuông + **nhịp lấy mẫu chung** (`kMKMoodBeatNotification`).
  Windows: `SetTimer` (đã có trong `Bell.cpp`) + cơ chế phát nhịp cho MoodWatch nghe.
- Nâng `Bell.cpp` đời cũ: hiện chỉ theo lịch → thêm rung theo **chuỗi câu căng liên tiếp**.
- **Sàn nhịp 15 phút / trần 240** — đã chốt 2026-07-15, không được phá (reo dày = hối thúc,
  HIẾN CHƯƠNG cấm; và nhật ký dày = phá trần riêng tư).

---

## 7. GIAI ĐOẠN 5 — Module 5+6: Reflection + EmotionRiver

- `ReflectionScreenMac.mm` (566 dòng) — câu hỏi phản chiếu là trọng tâm, số liệu chỉ là bối cảnh.
  **Cố ý không biểu đồ, không gamify.**
- `EmotionRiverView.mm` (426 dòng) — vẽ bằng `NSBezierPath` + `NSColor`.
  → Windows: **GDI+ `GraphicsPath`** (hoặc Direct2D). Vẽ tay, không có thư viện đỡ.
  Giữ đúng: trục dọc **chỉ cường độ, không valence**; **không bịa nước giả** ở quãng không gõ;
  trục thời-gian nét đứt mờ (chốt 2026-07-16).

---

## 8. GIAI ĐOẠN 6 — Vỏ nhận diện (khối UI lớn nhất)

Popover 3 tab, cửa sổ 6 mục, `PillSwitch`/`CTAButton`, sóng `~` theo biên độ, thẻ Gác cổng…
Bản Mac: `PanelViewController` + `SettingsWindowController` + `BrandControls` + các pane.
Windows: dialog Win32 hiện tại là **đồ OpenKey gốc**, phải thay.

Cũng ở giai đoạn này: thay `icon.ico` + bộ icon khay (`StatusViet/Eng.ico`) bằng asset brand.

> Bộ công cụ vẽ khác nhau (Cocoa vs Win32) nên **KHÔNG cần giống từng pixel** — giao diện Windows
> phải tự nhiên với người Windows. Nhưng **nhận diện phải đồng nhất**: màu/font/hình khối từ
> `tokens.json`, cùng con sóng `~` theo biên độ, cùng giọng "mô tả không phán xét".

---

## 9. GIAI ĐOẠN 7 — Đóng gói (ĐÃ DỰNG SẴN)

Xong rồi, chờ 0–6: `platforms/windows/installer/MindfulKey.iss` + job `build-windows` trong
`.github/workflows/release.yml`. Gắn tag `v*` → 1 Release có cả `.dmg` (macOS) lẫn
`MindfulKey_<ver>_x64-setup.exe`.

---

## 10. Thứ tự và lý do

```
GĐ0 (lưới an toàn) ──► GĐ1 MoodWatch ──► GĐ2 Gác cổng ──► GĐ3 MoodStore ──► GĐ4 Nudge+Bell
                                                                                    │
                                                          GĐ7 Đóng gói ◄── GĐ6 Vỏ ◄── GĐ5 Soi lại+Sông
```

- **GĐ0 trước hết** vì nó rẻ và vì nếu không có nó thì mọi giai đoạn sau đều mù (không build được,
  không ai gác nhận diện).
- **GĐ1 trước GĐ2** vì gác cổng cần điểm risk mà MoodWatch tính.
- **GĐ3 trước GĐ5** vì Soi lại/dòng sông chỉ vẽ được khi đã có nhật ký để đọc.
- **GĐ4 sau GĐ3** vì chuông là nhịp lấy mẫu — mỗi ngân là 1 điểm ghi vào nhật ký.
- **GĐ6 gần cuối** vì UI đắt nhất và cần mọi dữ liệu phía dưới đã chạy.

**Cố ý KHÔNG ước lượng số ngày.** Vỏ Windows chưa compile lần nào; mọi con số lúc này là bịa.
Ước lượng được sau khi GĐ0 xong và ta thấy build thật.

---

## 11. Rủi ro lớn nhất

| Rủi ro | Vì sao đáng sợ | Giảm bằng cách |
|---|---|---|
| **Không ai gõ thử được** | Không có máy Windows thì CI chỉ chứng minh *compile*, không chứng minh *chạy đúng*. Cả 6 module có thể build sạch mà sai hành vi | Cần **một máy Windows bất kỳ** để chạy `.exe` từ CI (không cần cài Visual Studio) |
| **MoodStore (GĐ3)** | 921 dòng, 3 công nghệ phải thay cùng lúc, chạm dữ liệu riêng tư | Làm sau khi GĐ0–2 đã chứng minh vỏ sống; tách test host nếu được |
| **Chép tay bảng màu** | Đúng mô hình đã đẻ bug lexicon | GĐ0.3: sinh từ `tokens.json`, không chép |
| **`vOnWordCommitted` tham chiếu chết** | Đã cắn iOS và macOS. Windows sẽ cắn y hệt | Copy `wstring` trước khi sang thread (GĐ1) |
| **UI Windows không ai gác nhận diện** | `.cpp` ngoài tầm brand-lint | GĐ0.1 |

---

## 12. Chờ chủ dự án chốt

| # | Câu hỏi | Chặn giai đoạn |
|---|---|---|
| 1 | Sinh bảng màu từ `tokens.json` cho cả 3 vỏ (đụng code macOS/iOS) hay chỉ Windows? | GĐ0.3 |
| 2 | Tên tiến trình thật của Zalo/Discord trên Windows để làm allow-list | GĐ2 |
| 3 | Vendor `sqlite3.c` amalgamation vào repo — chấp nhận không? | GĐ3 |
| 4 | DPAPI thay Keychain để giữ khoá mã hoá — chấp nhận mô hình bảo mật đó? | GĐ3 |
| 5 | Wizard bộ cài có cần tiếng Việt? (Inno không kèm sẵn, phải kéo file cộng đồng) | GĐ7 |
| 6 | Chứng chỉ Authenticode — có chưa? (chưa thì SmartScreen báo "Unknown publisher") | GĐ7 |
| 7 | File trong bộ cài vẫn tên `OpenKey64.exe` — giữ hay đổi? (đổi = đụng lằn ranh cứng) | GĐ7 |
| 8 | Link Facebook "OpenKeyVN" + `CompanyName` trong About | GĐ6 |
