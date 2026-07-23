# WINDOWS-PARITY-TASKS — bảng thi công (chia nhỏ để model yếu thực thi)

> Bản THI CÔNG của [WINDOWS-PARITY-PLAN.md](WINDOWS-PARITY-PLAN.md) (bản đó lo "vì sao", bản này lo
> "làm gì, ở đâu, thế nào, xong khi nào"). Mỗi dòng là 1 việc **tự-chứa**: model chỉ cần đọc neo
> `file:line`, làm theo công thức, chạy cổng nghiệm thu, đổi trạng thái. KHÔNG cần suy luận kiến trúc.
> Mọi neo trong `platforms/windows/win32/MindfulKey/MindfulKey/` (ghi tắt `WIN/`).

## ⛔ LUẬT CHO NGƯỜI THỰC THI — đọc trước khi làm bất cứ việc nào

1. **Làm TỪNG việc một, từ trên xuống** trong 1 giai đoạn. Xong 1 việc → chạy cổng → commit → đổi
   trạng thái ô này thành ✅ → mới sang việc kế. KHÔNG gộp nhiều việc vào 1 commit.
2. **Cổng nghiệm thu MÁY sau mỗi việc** (bắt buộc, đủ 3):
   - `bash /private/tmp/.../win-syntax-check.sh` HOẶC mingw trực tiếp:
     `cd WIN && x86_64-w64-mingw32-g++ -fsyntax-only -std=gnu++14 -DUNICODE -D_UNICODE -DWIN32 -D_WIN32 -D_WIN64 -I. -I../../../../../core/engine -I../../../../../core/mood <file>.cpp`
     → chỉ được có lỗi `BaseDialog.cpp` C4211 (giả, bỏ qua). File mình sửa phải **sạch**.
   - `make brand-lint` → **0 vi phạm** (không đèn đỏ/xanh cảm xúc, không emoji chấm điểm, không
     gamification, không hardcode màu ngoài `brand/tokens.json`).
   - `make test-core` → PASS (chỉ cần chạy nếu lỡ đụng `core/` — mà **KHÔNG được đụng** `core/`).
3. **CẤM sửa `core/`** để vá lỗi riêng Windows. Lỗi vỏ Windows sửa trong `WIN/`. Nếu thấy phải đụng
   `core/` → DỪNG, hỏi chủ dự án.
4. **CẤM chạm nhận diện**: không thêm đèn đỏ/xanh cho cảm xúc, mặt cười, streak/điểm/huy hiệu, copy
   khiển trách. Mơ hồ → HIẾN CHƯƠNG (`docs/AGENT-BRIEF.md`) là tối cao, hỏi chủ dự án.
5. **Bám STYLE code sẵn có.** Việc "cho nút bấm được" = **chép y hệt mẫu khối `WM_LBUTTONUP` của
   tab 2** (`MainControlDialog.cpp:531-564`): dựng lại RECT giống hệt nhánh `WM_PAINT`, dùng điểm
   chuột thật `pt`, `PtInRect`/helper, rồi `InvalidateRect(hDlg, NULL, FALSE)`.
6. **Toạ độ RECT trong `WM_LBUTTONUP` PHẢI khớp TỪNG SỐ với nhánh `WM_PAINT`** của cùng tab (cùng
   `y`, cùng `+offset`). Chép nguyên, đừng tự tính lại.
7. **KHÔNG để nút giả.** Nếu 1 control chưa làm kịp thật → GỠ khỏi UI (đừng vẽ nút không bấm được).
8. **Commit mỗi việc**, message tiếng Anh, cuối có trailer `Co-Authored-By: ...`. **KHÔNG push**
   (chủ dự án tự push).
9. **Việc nào cần quyết định ngoài spec này** (số liệu, tên, hành vi mơ hồ) → DỪNG, hỏi chủ dự án,
   ghi 1 dòng vào `docs/FRICTION-LOG.md`. ĐỪNG bịa "reasonable default".
10. Xong 1 việc → **cập nhật ô Trạng thái trong file này** trong cùng commit.

## Ký hiệu trạng thái

`⬜ Chưa làm` · `🔄 Đang làm` · `✅ Xong (máy xanh)` · `👁 Chờ mắt người` (đã code+máy xanh, cần chủ
dự án nhìn app thật) · `⛔ Chặn (chờ quyết định)`

---

## GĐ-A — Nối lại dây điện (làm những gì ĐÃ VẼ chạy thật)

> Ra bản **v0.4.14** sau khi xong GĐ-A. Cổng người: bật chuông từ popover → 15' sau nghe reo đúng
> tiếng; bật nhật ký từ popover → gõ → sông có chấm; mọi control đã vẽ đều bấm được hoặc đã gỡ.

| ID | Trạng thái | Việc |
|---|---|---|
| **A0** | ✅ | **Helper hit-test cho BrandControls** — nền cho A1–A4. Chi tiết ↓ |
| **A1** | ✅ | **Credit GPL** (thuần đổi chuỗi, 0 rủi ro) — làm trước cho quen tay. Chi tiết ↓ |
| **A2** | ✅ | **Tab Chuông (settings) bấm được + nối đúng dây chuông**. Chi tiết ↓ |
| **A3** | ⬜ | **Tab Hôm nay (settings) bấm được** (Độ nhạy + nút Bật nhật ký). Chi tiết ↓ |
| **A4** | ⬜ | **Tab Riêng tư (settings) bấm được** (retention + Xuất CSV). Chi tiết ↓ |
| **A5** | ⬜ | **Popover hết đảo kép** (pill chỉ xử `WM_LBUTTONUP`). Chi tiết ↓ |
| **A6** | ⬜ | **Popover nối đúng dây chuông** (vBell + vBellSoundName + vBellVolume). Chi tiết ↓ |
| **A7** | ⬜ | **Nút "Bật nhật ký" tại chỗ** trên popover (chỗ hiện "đang tắt"). Chi tiết ↓ |
| **A8** | ⬜ | **Khớp index Độ nhạy** UI(0/1/2) ↔ NudgeCoordinator(1/2/3). Chi tiết ↓ |

### A0 — Helper hit-test (BrandControls.h + .cpp)

**Vì sao:** các hàm `BrandControls_DrawX` vừa vẽ vừa dò-click (nhận `POINT pt`). Trong `WM_PAINT`
`pt={-1,-1}` nên không dò. Ta cần bản DÒ-KHÔNG-VẼ để gọi trong `WM_LBUTTONUP`.

1. `BrandControls.h`: thêm khai báo (cạnh các `BrandControls_Draw*`):
   ```cpp
   // Hit-test thuần (không vẽ) — dùng trong WM_LBUTTONUP, khớp toán của bản Draw* tương ứng.
   int  BrandControls_HitSegmented(const RECT& rc, int count, POINT pt); // trả index 0..count-1, hoặc -1
   int  BrandControls_HitIconGroup(const RECT& rc, int count, POINT pt); // như trên
   bool BrandControls_HitSlider(const RECT& rc, POINT pt, float* outPos); // true nếu trúng, outPos=0..1
   ```
2. `BrandControls.cpp`: thêm định nghĩa (khớp TỪNG dòng toán với `DrawSegmentedControl:203-216`,
   `DrawIconGroup:291-299`, `DrawSlider:244-248`):
   ```cpp
   int BrandControls_HitSegmented(const RECT& rc, int count, POINT pt) {
       if (count <= 0 || pt.x == -1) return -1;
       int itemWidth = (rc.right - rc.left) / count;
       for (int i = 0; i < count; i++) {
           RECT it = { rc.left + i*itemWidth, rc.top, rc.left + (i+1)*itemWidth, rc.bottom };
           if (pt.x >= it.left && pt.x < it.right && pt.y >= it.top && pt.y < it.bottom) return i;
       }
       return -1;
   }
   int BrandControls_HitIconGroup(const RECT& rc, int count, POINT pt) {
       return BrandControls_HitSegmented(rc, count, pt); // cùng toán chia đều
   }
   bool BrandControls_HitSlider(const RECT& rc, POINT pt, float* outPos) {
       if (pt.x == -1 || pt.x < rc.left || pt.x > rc.right || pt.y < rc.top || pt.y > rc.bottom) return false;
       float p = (float)(pt.x - rc.left) / (rc.right - rc.left);
       if (p < 0) p = 0; if (p > 1) p = 1;
       *outPos = p; return true;
   }
   ```
   (Pill switch không cần helper — dùng thẳng `PtInRect(&switchRc, pt)` như tab 2.)
- **Nghiệm thu:** mingw file `BrandControls.cpp` sạch. Chưa đổi hành vi gì (chỉ thêm hàm) → build vẫn xanh.

### A1 — Credit GPL (đổi chuỗi, làm quen tay)

Đổi 3 nhóm chuỗi bị cú rename OpenKey→MindfulKey nuốt mất (chi tiết + lý do: PLAN §6):
1. `WIN/MindfulKey.rc:144` — `"Dựa trên MindfulKey — Mai Vũ Tuyên (GPL v3)"` → **`OpenKey`**.
2. `WIN/MindfulKey.rc:142` và `:344` — `facebook.com/MindfulKeyVN` → **`facebook.com/OpenKeyVN`**.
3. `WIN/stdafx.h:6-7` header — `Github: https://github.com/tuyenvm/MindfulKey` → **`tuyenvm/OpenKey`**;
   `Fanpage: .../MindfulKeyVN` → **`.../OpenKeyVN`**. Rồi grep boilerplate y hệt đầu MỌI `.cpp`/`.h`
   trong `WIN/` (`grep -rn "tuyenvm/MindfulKey\|MindfulKeyVN" WIN/`) và đổi HẾT. **KHÔNG đổi** dòng
   `Copyright (C) 2019 Mai Vu Tuyen` (đúng rồi) và **KHÔNG đổi** tên sản phẩm "Mindful Keyboard/
   MindfulKey" ở chỗ khác (chỉ đổi credit về tác giả gốc OpenKey).
- **Nghiệm thu:** `grep -rn "MindfulKeyVN\|tuyenvm/MindfulKey" WIN/` → **rỗng**; brand-lint 0. Không đụng logic → không cần mingw nhưng chạy cho chắc.

### A2 — Tab Chuông (settings) bấm được + nối ĐÚNG dây chuông  ⚠️ việc lớn nhất GĐ-A

**Bối cảnh:** hiện toàn bộ dò-click tab 1 nằm trong `WM_PAINT` (`MainControlDialog.cpp:305-350`) với
`pt={-1,-1}` → chết. Và nối **nhầm dây**: toggle lật `FLAG_BEEP` (tiếng bíp đổi Việt/Anh) thay vì
`vBell`; tiếng ghi `vBellSoundIndex`, âm lượng ghi `vVolume` — Bell đọc `vBellSoundName`+`vBellVolume`.

**Bước 1 — sửa nạp trạng thái** (`MainControlDialog.cpp:294-297`):
- `bool s_bellEnabled = HAS_BEEP(vSwitchKeyStatus);` → `bool s_bellEnabled = (vBell != 0);`
- `int s_bellSoundIndex = getRegInt("vBellSoundIndex", 0);` → map từ tên: đọc
  `getRegString(_T("vBellSoundName"), _T(""))` rồi map **temple→0, chime→1, wind→2** (xem đúng chuỗi
  id ở `Bell.cpp` `SoundIdFromStored`, dòng ~181; tiếng tùy chỉnh nếu có → index 3).
- `int s_bellVolume = getRegInt("vVolume", 50);` → `getRegInt(_T("vBellVolume"), 60);` (mặc định 60
  khớp macOS 0.6).

**Bước 2 — GỠ 4 khối dò-click chết trong WM_PAINT** (giữ phần VẼ, bỏ phần `if (pt.x != -1 && ...)`):
- pill (`:305-311`): bỏ khối `if`, chỉ giữ `BrandControls_DrawPillSwitch(memDC, sw1Rc, s_bellEnabled);`
- Nhịp (`:324-329`), Bộ tiếng (`:340-343`), Âm lượng (`:347-350`): bỏ các khối `if (clicked...)`
  (giữ dòng gọi `BrandControls_Draw*` để vẫn vẽ).

**Bước 3 — thêm khối click thật** trong `WM_LBUTTONUP`, chèn 1 nhánh `else if (currentTab == 1) { }`
**trước** `else if (currentTab == 2)` (`:531`). Bên trong: dựng lại **y hệt** RECT như paint
(`sw1Rc`, `seg2Rc`, `iconGrpRc`, `sliderRc` — chép nguyên số từ `:304,321,338,345`) rồi:
```cpp
if (PtInRect(&sw1Rc, pt)) {                       // pill Phát tiếng gõ
    APP_SET_DATA(vBell, vBell ? 0 : 1);
    Bell_ApplySettings();                          // BẬT/tắt đồng hồ chuông thật
    changed = true;
}
int ci = BrandControls_HitSegmented(seg2Rc, 3, pt);   // Nhịp Nhanh/Vừa/Chậm
if (ci != -1) { int m = ci==0?30:(ci==1?60:120); APP_SET_DATA(vBellInterval, m); Bell_ApplySettings(); changed = true; }
int cs = BrandControls_HitIconGroup(iconGrpRc, 4, pt); // Bộ tiếng
if (cs != -1) { const wchar_t* ids[]={L"temple",L"chime",L"wind",L"custom"}; MindfulKeyHelper::setRegString(_T("vBellSoundName"), ids[cs]); changed = true; } // dùng ĐÚNG chuỗi id của Bell.cpp
float vp; if (BrandControls_HitSlider(sliderRc, pt, &vp)) { MindfulKeyHelper::setRegInt(_T("vBellVolume"), (int)(vp*100)); changed = true; }
```
(Khai `bool changed = false;` đầu nhánh, cuối nhánh `if (changed){ SystemTrayHelper::updateData(); InvalidateRect(hDlg,NULL,FALSE);} `.)
- **⛔ Điểm phải xác minh, KHÔNG đoán:** chuỗi id tiếng ĐÚNG mà `Bell.cpp` `SoundIdFromStored` chấp
  nhận (temple/chime/wind?) + có ô thứ 4 "tùy chỉnh" hay không. Đọc `Bell.cpp:155-185`. Sai chuỗi =
  chuông không tìm ra tiếng. Nếu mơ hồ → hỏi.
- **Nghiệm thu máy:** mingw `MainControlDialog.cpp` sạch; brand-lint 0. **Mắt người (v0.4.14):** mở
  Cài đặt ▸ Chuông → bật "Phát tiếng gõ" → đặt Nhịp Nhanh → chờ/nghe reo đúng tiếng đã chọn.

### A3 — Tab Hôm nay (settings) bấm được

Trong `WM_LBUTTONUP` thêm `else if (currentTab == 0)`: dựng lại RECT card Độ nhạy như paint
(`:260` vùng), hit-test segmented 3 mức → `APP_SET_DATA(vBellSensitivity, idx)` (xem A8 về index) +
`NudgeCoordinator` cập nhật. Gỡ khối dò-click chết trong paint. (Nút "Bật nhật ký" làm ở A7 nếu đặt
ở đây; nếu chỉ đặt trên popover thì bỏ qua ở tab này.)
- **Nghiệm thu:** mingw sạch; mắt người: đổi Độ nhạy Ít/Vừa/Nhạy thấy chấm chọn dịch.

### A4 — Tab Riêng tư (settings) bấm được

Trong `WM_LBUTTONUP` thêm `else if (currentTab == 3)`: hit-test segmented "Thời gian lưu trữ"
(30/60/90/Không) → ghi khoá purge (xem macOS `PrivacyPaneView`/`MoodStoreMac` dùng key gì, mirror);
nút "Xuất CSV" → gọi hàm export của `MoodStore.cpp` (tìm `MoodStore_ExportCSV` tương đương). Gỡ khối
chết trong paint (`:375`). Nếu chưa có hàm export Windows → GỠ nút (đừng để giả), ghi FRICTION-LOG.
- **Nghiệm thu:** mingw sạch; mắt người: bấm Xuất → hộp lưu file hiện.

### A5 — Popover hết đảo kép

`TrayPopover.cpp:288-291` gọi `ProcessTabX(...)` cho CẢ down/up/move → pill đảo 2 lần. Bọc cụm dispatch
`if (g_currentTab==0) ProcessTabToday... else...` trong `if (msg == WM_LBUTTONUP) { ... }`. (Segmented
đổi tab ở trên đã up-only rồi — giữ nguyên.) Slider thành click-để-đặt (chấp nhận, đơn giản + đúng).
- **Nghiệm thu:** mingw sạch; mắt người: bật 1 pill trên popover → đổi trạng thái và GIỮ (không nhảy về).

### A6 — Popover nối đúng dây chuông

Trong `ProcessTabBell` (TrayPopover.cpp) — cùng 3 sửa như A2: pill → `vBell`+`Bell_ApplySettings()`
(không `FLAG_BEEP`); Bộ tiếng → `vBellSoundName` (id chuỗi, không `vBellSoundIndex`); âm lượng →
`vBellVolume` (không `vVolume`). Nạp trạng thái cũng đọc đúng khoá.
- **Nghiệm thu:** mắt người: bật chuông từ popover → nghe reo (đây là cổng người CHÍNH của GĐ-A).

### A7 — Nút "Bật nhật ký" tại chỗ (popover)

Chỗ vẽ chữ `"Nhật ký cảm xúc đang tắt."` (TrayPopover.cpp:86; MainControlDialog.cpp:279) — thêm 1
nút "Bật nhật ký" ngay dưới, hit-test trong `WM_LBUTTONUP` → gọi `MoodWatch_Toggle()` (đã có consent
gate sẵn, MoodWatch.cpp:379). Sau toggle `InvalidateRect`.
- **Nghiệm thu:** mắt người: popover đang "đang tắt" → bấm → (consent) → chữ đổi + sông bắt đầu có mẫu.

### A8 — Khớp index Độ nhạy

UI ghi `vBellSensitivity` 0/1/2 nhưng `NudgeCoordinator.cpp:25,34` switch 1/2/3 → "Nhạy" không bao
giờ đạt. Chọn 1 chuẩn (đề xuất: theo macOS — xem `NudgeCoordinatorMac.mm:25-43` dùng 1/2/3) rồi sửa
để UI ghi cùng thang coordinator đọc. Kiểm mọi nơi đọc `vBellSensitivity` cùng thang.
- **Nghiệm thu:** mingw sạch; đọc code xác nhận 3 mức map đúng ngưỡng (Ít=0.6, Vừa=0.5, Nhạy=0.4).

---

## GĐ-B — Sóng sống (port thật, có luồng — KHÔNG thuần chép-dán)

> Ra bản **v0.4.15**. Cổng người: gõ câu căng → đầu sóng nhích trong vài giây; ngừng 5' → tự lặng
> về phẳng. ⚠️ **Hợp đồng dec.4 (bất khả xâm phạm):** idle = KHÔNG vẽ đầu sóng, KHÔNG bịa nước nối
> quãng đứt. Trục dọc = CƯỜNG ĐỘ, không valence, không đỏ/xanh.

| ID | Trạng thái | Việc |
|---|---|---|
| **B1** | ⬜ | State sóng sống + cập nhật trong worker. Chi tiết ↓ |
| **B2** | ⬜ | `MoodWatch_LiveAmplitude()` + `MoodWatch_FetchLiveTrace()`. Chi tiết ↓ |
| **B3** | ⬜ | Nối `liveHead` thật + vệt dày vào 3 chỗ vẽ. Chi tiết ↓ |
| **B4** | ⬜ | Dòng "Chuông kế tiếp: lúc HH:mm" trên popover. Chi tiết ↓ |

### B1 — State sóng sống + cập nhật trong worker (`MoodWatch.cpp`)

**Bối cảnh:** Windows đã có worker gọi `SendRiskAnalyzer_Analyze` mỗi câu (`MoodWatch.cpp:225-226`)
nhưng KHÔNG giữ state EMA/vệt như macOS. macOS giữ `g_liveEma` + `g_lastWordTs` + `g_liveTrace`
(khoá `g_liveLock`), cập nhật mỗi câu.

1. Thêm hằng (cạnh `kSendRiskThreshold`, `MoodWatch.cpp:53-55`) — số LẤY TỪ macOS, không tự chế:
   ```cpp
   static const double kLiveAlpha       = 0.4;        // MoodWatchMac.mm (grep kLiveAlpha / g_liveEma)
   static const double kLiveFadeSeconds = 300.0;      // phai 5 phút
   static const long long kLiveTraceMaxSec = 4*3600;  // giữ vệt 4h
   static const long long kLiveTraceMinGap = 30;      // ≤1 điểm/30s
   ```
2. Thêm globals + khoá (cạnh `g_sampleMutex:62`):
   ```cpp
   static mutex g_liveMutex;
   static double g_liveEma = 0.0;
   static long long g_lastWordTs = 0;
   static std::vector<std::pair<long long,double>> g_liveTrace; // (ts, value 0..1)
   ```
3. Trong worker, NGAY SAU khi có `risk` từ `SendRiskAnalyzer_Analyze` (`~226`), thêm (khoá
   `g_liveMutex`): `ema = alpha*risk + (1-alpha)*ema`; `lastWordTs = now`; nếu `now - ts_điểm_cuối
   >= 30` thì `push_back({now, risk})`; xoá đầu vệt cũ hơn `now - 4h`. **Mirror TỪNG dòng** với chỗ
   macOS cập nhật `g_liveEma`/`g_liveTrace` — `grep -n "g_liveEma\|g_liveTrace" MoodWatchMac.mm`
   (quanh dòng 150-171), làm y hệt.
- **⛔ Verify, đừng đoán:** `now` lấy bằng `time(NULL)` (giây, khớp macOS `timeIntervalSince1970`).
- **Nghiệm thu:** mingw `MoodWatch.cpp` sạch (thêm `#include <vector>`/`<utility>` nếu thiếu).

### B2 — 2 hàm phơi cho UI (`MoodWatch.cpp` + `MoodWatch.h`)

Thêm khai báo ở `MoodWatch.h`, định nghĩa ở `MoodWatch.cpp`, **mirror `MoodWatchMac.mm:215-258`**:
1. `double MoodWatch_LiveAmplitude()` — khoá đọc `g_liveEma`+`g_lastWordTs`; `lastTs==0` → `-1`;
   `idle >= 300` → `-1`; else `clamp01(ema * smoothstep(1 - idle/300))`. Cần `smoothstep`+`clamp01`:
   `grep -rn "MKSmoothstep\|smoothstep\|Clamp01" core/mood WIN/` — nếu `core/mood/EmotionWaveAmplitude.h`
   có thì dùng; nếu không, thêm 2 hàm static nhỏ NGAY trong `MoodWatch.cpp` (`s = t*t*(3-2t)`).
2. `std::vector<std::pair<long long,double>> MoodWatch_FetchLiveTrace(double windowSec)` — trộn vệt
   RAM `g_liveTrace` (khoá) + mẫu persisted `MoodStore_FetchRecentSamples(windowSec)` (đã có), bỏ mẫu
   persisted trùng quãng vệt RAM (theo `firstLiveTs`), sort tăng theo ts. Mirror `:231-258`.
- **⛔ Verify:** kiểu trả về của `MoodStore_FetchRecentSamples` (vector gì?) — `grep -n
  "FetchRecentSamples" MoodStore.h` — để chuyển đổi cho khớp `EmotionRiver_Draw` đang nhận.
- **Nghiệm thu:** mingw sạch; đọc code đối chiếu logic với macOS.

### B3 — Nối `liveHead` + vệt dày vào 3 chỗ vẽ

1. Thay `liveHead = -1.0` cứng bằng `MoodWatch_LiveAmplitude()` tại: `TrayPopover.cpp:82`,
   `MainControlDialog.cpp:273`, `ReflectionScreen.cpp:319`.
2. Card "Hôm nay" popover (`TrayPopover.cpp:81-84`): đổi nguồn vẽ từ `MoodStore_FetchRecentSamples(3h)`
   sang `MoodWatch_FetchLiveTrace(3*3600)` (vệt dày hơn). Giữ guard `if (vMoodWatch)` (tắt = "Nhật
   ký cảm xúc đang tắt.").
- **Nghiệm thu máy:** mingw 3 file sạch. **Mắt người:** bật nhật ký, gõ câu căng → đầu sóng nhích
  trong vài giây; ngừng 5' → lặng về phẳng (idle không vẽ đầu sóng).

### B4 — "Chuông kế tiếp: lúc HH:mm"

Mirror `PanelViewController.mm:547-571`. Cần Bell phơi giờ reo kế: `grep -n "NextRing\|MinutesUntil\|
fireDate\|nextFire" Bell.cpp Bell.h`. Nếu chưa có → thêm `int Bell_MinutesUntilNextRing()` đọc từ
timer/`vBellInterval` (mirror `BellMac.mm:284-296`, trả `-1` khi tắt/hoãn). Vẽ dòng dưới card Hôm
nay popover, ẩn khi `-1`.
- **Nghiệm thu:** mắt người: bật chuông nhịp 30' → thấy "Chuông kế tiếp: lúc HH:mm".

---

## GĐ-C — Khung cửa sổ đúng cỡ + đồng bộ thiết kế (nặng nhất, có ĐIỂM QUYẾT ĐỊNH)

> Ra bản **v0.4.16**. Cổng người: đặt 2 máy cạnh nhau, chụp TỪNG màn — lệch nào phải có lý do ghi
> PLAN §5. ⚠️ **Đây là GĐ khó nhất, KHÔNG thuần chép-dán** — vài việc cần chủ dự án chốt trước.

| ID | Trạng thái | Việc |
|---|---|---|
| **C1** | ⛔ chờ chốt | Thu cỡ + cho kéo giãn cửa Cài đặt. Chi tiết ↓ (cần chốt cỡ đích) |
| **C1b** | ⬜ | Layout co giãn theo `WM_SIZE` (sau C1). Chi tiết ↓ |
| **C2** | ⬜ | DPI PerMonitorV2 + scale toạ độ vẽ tay. Chi tiết ↓ (nặng) |
| **C3** | ⛔ chờ chốt | Combo thật + icon Bộ tiếng thật (cần biết icon brand có chưa). Chi tiết ↓ |
| **C4** | ⬜ | Pane Chuông đủ: giờ yên lặng + snooze + tiếng tùy chỉnh. Chi tiết ↓ |
| **C5** | ⬜ | Check-in overlay 3 mức sóng. Chi tiết ↓ |

### C1 — Thu cỡ + cho kéo giãn  ⛔ CẦN CHỦ DỰ ÁN CHỐT CỠ ĐÍCH
`MindfulKey.rc:149` STYLE: bỏ `DS_MODALFRAME`, thêm `WS_THICKFRAME | WS_MINIMIZEBOX`. Thu `DIALOGEX
0,0,450,450` (`:148`) về cỡ nhỏ hơn.
- **⛔ DỪNG hỏi:** cỡ đích bao nhiêu DLU? Không tự chế. Đề xuất tham chiếu cỡ cửa sổ macOS
  (`SettingsWindowController.mm` minSize) đổi ra DLU, HOẶC chủ dự án cho số. Ghi FRICTION-LOG.
- **Nghiệm thu:** mắt người: cửa sổ nhỏ vừa màn + kéo mép giãn được.

### C1b — Layout co giãn (sau C1)
Hiện `tabPageEventProc` vẽ với `navRc={10,20,150,260}` cố định + `contentRc={160,0,clientRc.right,
clientRc.bottom}` (đã theo bề rộng client — giãn NGANG đã chạy). Thiếu: giãn DỌC (card dùng `y+offset`
cứng) → nội dung dài hơn client bị cắt. Chọn 1: (a) bọc nội dung trong vùng cuộn (thêm scrollbar khi
tràn), hoặc (b) tính lại `y` theo tỷ lệ. Đề xuất (a) đơn giản+an toàn hơn. Thêm xử `WM_SIZE` →
`InvalidateRect`.
- **Nghiệm thu:** mắt người: kéo cửa sổ nhỏ lại → nội dung cuộn được, không cụt.

### C2 — DPI PerMonitorV2 + scale toạ độ (nặng, cẩn thận)
1. `DeclareDPIAware.manifest`: nâng `<dpiAware>true` → thêm
   `<dpiAwareness>PerMonitorV2</dpiAwareness>` (đúng schema Win10 — verify format ở docs Microsoft).
2. Trong `tabPageEventProc` (+ TrayPopover paint): đầu hàm tính `double s =
   GetDpiForWindow(hDlg)/96.0;` rồi **nhân `s` vào MỌI số toạ độ literal** của RECT vẽ + hit-test
   (nav, card, offset). Font đã theo DPI sẵn (`BrandControls.cpp:27,38`) nên chỉ còn phần vẽ tay.
- **⚠️ Rủi ro cao:** đây là sửa rải khắp; làm TỪNG tab, mingw sau mỗi tab. Nếu quá rộng → tách
  thành C2a/b/c per-tab.
- **Nghiệm thu:** mắt người: đặt Windows scale 150% → chữ + khung + vùng bấm khớp, không mờ/lệch.

### C3 — Combo thật + icon Bộ tiếng thật  ⛔ CẦN BIẾT ICON BRAND CÓ CHƯA
1. Popover Kiểu gõ/Bảng mã (`TrayPopover.cpp:168-176`) đang là **nhãn vẽ**. Đổi thành dropdown thật:
   hoặc child `COMBOBOX` Win32, hoặc menu bật khi bấm. Ghi `vInputType`/`vCodeTable` + áp.
2. Icon Bộ tiếng: `BrandControls_DrawIconGroup` fallback chữ A/B/C/D (`BrandControls.cpp:301-309`).
   - **⛔ DỪNG hỏi:** có icon brand cho 3 tiếng chuông (temple/chime/wind) trong `brand/` chưa?
     `ls brand/platform/windows/ | grep -i bell` + `grep -i "IDI.*BELL\|sound" MindfulKey.rc`. CÓ →
     load `.ico` vẽ vào iconRc. KHÔNG → hỏi chủ dự án vẽ, HOẶC tạm dùng chữ Việt gọn ("Chùa/Gió/Reo")
     thay A/B/C/D (KHÔNG bịa icon).
- **Nghiệm thu:** mắt người: bấm dropdown Kiểu gõ đổi được; Bộ tiếng hiện icon/chữ thật.

### C4 — Pane Chuông đủ (giờ yên lặng + snooze + tiếng tùy chỉnh)
Bell.cpp CÓ SẴN logic: giờ yên lặng (`vBellFrom`/`vBellTo`, `isInBellRange`), tiếng tùy chỉnh
(`Bell_InstallCustomSound`/`kRegCustomPath` ~155-185), snooze (`Bell_Snooze`). Thiếu ĐƯỜNG VÀO UI.
Thêm vào tab Chuông (settings) — mirror `BellSettingsView.mm`: 2 ô giờ (từ–đến), nút "Chọn tiếng của
bạn..." (mở `GetOpenFileName` .wav → `Bell_InstallCustomSound`), nút "Tạm hoãn 1 giờ".
- **⛔ Verify:** tên hàm thật ở `Bell.cpp`/`Bell.h` (grep) trước khi gọi.
- **Nghiệm thu:** mắt người: đặt giờ yên lặng → trong khoảng đó không reo; chọn .wav lạ → reo tiếng đó.

### C5 — Check-in overlay 3 mức sóng
Mirror macOS `PanelViewController.mm:361-460` (khung "Mặt hồ đang thế nào?" + 3 nút Phẳng lặng/Gợn
nhẹ/Gợn sóng + "Bỏ qua", ghi `MoodStore_LogCheckinEvent(1/2/3)`). Windows: overlay trên popover, bật
sau nhịp chuông. Kiểm `MoodStore_LogCheckinEvent` đã có ở `MoodStore.cpp` chưa (grep) — chưa thì thêm.
- **Nghiệm thu:** mắt người: sau nhịp chuông, popover hiện khung check-in; bấm 1 mức → ghi + đóng.

---

## GĐ-D — Khép 100% + sổ sách

> Ra bản **v0.5.0** (mốc "đồng bộ Windows↔macOS"). Cổng: chạy trọn `QA-WINDOWS.md` trên máy thật.

| ID | Trạng thái | Việc |
|---|---|---|
| **D1** | ⬜ | Version Windows tự đọc `version.env` lúc build. Chi tiết ↓ |
| **D2** | ⬜ | Quét ma trận PLAN §3 lần cuối. Chi tiết ↓ |
| **D3** | ⬜ | Chạy TRỌN `docs/QA-WINDOWS.md` + điền `TEST_MATRIX.md`. Chi tiết ↓ |
| **D4** | ⬜ | SignPath duyệt → nối ký. Chi tiết ↓ |

### D1 — Version tự đọc `version.env`
Tạo `scripts/sync-win-version.py` (Python, chạy cả macOS lẫn runner Windows): đọc `VERSION` từ
`version.env`, tính dạng phẩy (`0.5.0`→`0,5,0,0`) + dạng chấm (`0.5.0.0`), ghi đè 4 dòng trong
`WIN/MindfulKey.rc` (`FILEVERSION`, `PRODUCTVERSION`, `VALUE "FileVersion"`, `VALUE "ProductVersion"`)
bằng regex. Thêm 1 step `shell: bash` chạy `python3 scripts/sync-win-version.py` TRƯỚC `msbuild` trong
CẢ `windows.yml` VÀ `release.yml` (job build-windows).
- **Nghiệm thu:** chạy script local → `.rc` đổi đúng; mingw không đụng; CI Windows xanh.

### D2 — Quét ma trận lần cuối
Đối chiếu PLAN §3 với code sau A→C. Mục nào còn 🎨/❌ → làm nốt hoặc ghi "khác biệt cố ý" vào PLAN §5
(có lý do). Cập nhật cột trạng thái toàn file này.

### D3 — QA đầy đủ + sổ bằng chứng
Chạy trọn `docs/QA-WINDOWS.md` (§3 gõ · §4 cảm xúc/gác cổng/chuông/nhật ký · §5 bất biến riêng tư ·
§6 nhận diện) trên máy Windows thật. Mỗi ca PASS → điền bằng chứng (ảnh/mô tả) vào `TEST_MATRIX.md`
cột mắt người, nâng ô ❌→✅. Ca iOS-style "chập chờn" phải PASS 2 lần.

### D4 — Nối ký SignPath (khi duyệt)
Khi SignPath cấp Organization ID / Project slug / Signing-policy slug + API token: vá bug
`github-artifact-name`→`github-artifact-id` (+`github-token`) trong `release.yml` job `sign-windows`,
cắm 3 slug, chủ dự án lưu secret `SIGNPATH_API_TOKEN`. Xem `docs/WINDOWS-CODE-SIGNING.md` §Bước 2.
- **Nghiệm thu:** tag 1 bản → `.exe` tải về `signtool verify` thấy chữ ký; SmartScreen hết "Unknown".

---

## ⚠️ ĐỌC KỸ — giới hạn của "chạy một mạch"

Sonnet **code được** cả A→D liền mạch, NHƯNG:

1. **3 điểm ⛔ BẮT BUỘC dừng hỏi chủ dự án** (không được đoán, sẽ chặn "một mạch" tại đó):
   **C1** (cỡ cửa sổ đích) · **C3** (icon brand cho tiếng chuông có chưa) · **D4** (chờ SignPath
   duyệt — ngoài tầm code). Gặp là DỪNG, hỏi, ghi FRICTION-LOG, làm việc khác trong khi chờ.
2. **Nghiệm thu là MẮT NGƯỜI trên Windows, theo từng GĐ.** Máy chỉ chứng minh "build được", KHÔNG
   chứng minh "chạy đúng" (đúng bài học cả dự án). **Khuyến nghị mạnh:** xong mỗi GĐ → ra 1 bản
   (v0.4.14/15/16/0.5.0) → chủ dự án test tay → mới sang GĐ sau. Nếu Sonnet code B/C/D chồng lên A
   mà A có lỗi runtime ẩn (chỉ hiện trên Windows), là xây nhà trên cát.
3. **GĐ-C là refactor nặng, dễ vỡ** (resize + DPI rải khắp code vẽ tay). Nếu 1 việc quá rộng cho 1
   lượt → tự tách nhỏ hơn (per-tab), mingw sau mỗi mảnh. Đừng làm 1 commit khổng lồ.
4. **Bump version + CHANGELOG mỗi khi kết 1 GĐ** (không phải mỗi việc con). `version.env` là nguồn
   duy nhất.

---

## Bản đồ phụ thuộc (thứ tự an toàn, cả 4 GĐ)

```
GĐ-A  A0 ─┬─> A2 ─> A6         A1 (credit, độc lập)
          ├─> A3
          └─> A4       A5 (popover) ─> A7, A8
      └──────────────────────────────> v0.4.14 → MẮT NGƯỜI ─┐
                                                             v
GĐ-B  B1 ─> B2 ─> B3 ─> B4 ───────────> v0.4.15 → MẮT NGƯỜI ─┐
   (B cần A2/A6 xong: sóng dựa trên chuông/nhật ký đã bật được) v
GĐ-C  C1⛔ ─> C1b ─> C2 ;  C3⛔ ;  C4 ;  C5 ─────> v0.4.16 → MẮT NGƯỜI ─┐
                                                                        v
GĐ-D  D1 ─> D2 ─> D3 (QA đầy đủ) ;  D4⛔ (chờ SignPath) ──> v0.5.0 (đồng bộ 100%)
```

