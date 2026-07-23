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
| **A0** | ⬜ | **Helper hit-test cho BrandControls** — nền cho A1–A4. Chi tiết ↓ |
| **A1** | ⬜ | **Credit GPL** (thuần đổi chuỗi, 0 rủi ro) — làm trước cho quen tay. Chi tiết ↓ |
| **A2** | ⬜ | **Tab Chuông (settings) bấm được + nối đúng dây chuông**. Chi tiết ↓ |
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

## GĐ-B — Sóng sống (chi tiết hoá khi tới; cần bám chuẩn macOS)

| ID | Trạng thái | Việc | Chuẩn macOS để mirror |
|---|---|---|---|
| B1 | ⬜ | Thêm `MoodWatch_LiveAmplitude()` (EMA α=0.4, phai smoothstep 5' về 0, idle=-1) | `MoodWatchMac.mm:65-66,155,215-227` |
| B2 | ⬜ | Thêm `MoodWatch_FetchLiveTrace()` (vệt RAM ≤1điểm/30s, giữ 4h, trộn persisted) | `MoodWatchMac.mm:231-258` |
| B3 | ⬜ | Nối `liveHead` thật vào 3 chỗ vẽ (bỏ `-1.0` cứng) | TrayPopover.cpp:82 · MainControlDialog.cpp:273 · ReflectionScreen.cpp:319 |
| B4 | ⬜ | Dòng "Chuông kế tiếp: lúc HH:mm" trên popover | `PanelViewController.mm:547-571` |
- **Cổng người B:** gõ câu căng → đầu sóng nhích trong vài giây; ngừng 5' → tự lặng về phẳng.
- ⚠️ Hợp đồng dec.4 (bất khả xâm phạm): idle = KHÔNG vẽ đầu sóng, KHÔNG bịa nước nối quãng đứt.

## GĐ-C — Khung cửa sổ đúng cỡ (chi tiết hoá khi tới)

| ID | Trạng thái | Việc |
|---|---|---|
| C1 | ⬜ | Cửa Cài đặt resizable: `MindfulKey.rc:149` bỏ `DS_MODALFRAME`, thêm `WS_THICKFRAME`; thu `450,450`→cỡ khớp thiết kế; xử `WM_SIZE` để layout co giãn |
| C2 | ⬜ | Nâng manifest `DeclareDPIAware.manifest` lên PerMonitorV2; scale mọi RECT vẽ tay/hit theo `GetDpiForWindow` |
| C3 | ⬜ | Combo Kiểu gõ/Bảng mã popover thành dropdown thật; icon Bộ tiếng thật (bỏ chữ giả A/B/C/D — `BrandControls.cpp:301-309`) |
| C4 | ⬜ | Pane Chuông đủ: giờ yên lặng + snooze + tiếng tùy chỉnh (Bell.cpp có sẵn logic, thiếu đường vào UI) |
| C5 | ⬜ | Check-in overlay 3 mức sóng (mirror `PanelViewController.mm:361-460`) |
- **Cổng người C:** đặt 2 máy cạnh nhau, chụp từng màn — lệch nào phải có lý do ghi ở PLAN §5.

## GĐ-D — Khép 100% + sổ sách

| ID | Trạng thái | Việc |
|---|---|---|
| D1 | ⬜ | Version Windows tự đọc `version.env` lúc build (hết sửa tay `.rc`) — 1 script sinh `.rc` version + gọi trong `windows.yml`+`release.yml` trước msbuild |
| D2 | ⬜ | Quét ma trận PLAN §3 lần cuối: ❌/🎨 còn lại → làm hoặc ghi "khác biệt cố ý" (PLAN §5) |
| D3 | ⬜ | Chạy TRỌN `docs/QA-WINDOWS.md` trên máy thật, điền bằng chứng vào `TEST_MATRIX.md` |
| D4 | ⬜ | SignPath duyệt → nối ký (vá bug `github-artifact-name`, xem `WINDOWS-CODE-SIGNING.md`) |

---

## Bản đồ phụ thuộc (thứ tự an toàn)

```
A0 (helper) ─┬─> A2 ─> A6      A1 (credit, độc lập, làm bất cứ lúc)
             ├─> A3 ──┐
             └─> A4   ├─> A5 (popover, độc lập A2-4)
                      └─> A7, A8
GĐ-A xong → v0.4.14 → mắt người → GĐ-B → v0.4.15 → ... → GĐ-C → GĐ-D
```
