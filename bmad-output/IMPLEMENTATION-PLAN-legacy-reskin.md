# Plan triển khai + Prompt — Thay áo 4 màn cũ (mindful-key macOS)

**Epic:** 1 · **Story:** 1.7–1.10 · **Track:** bmad-method · **Chốt:** 2026-07-09, **revise:** 2026-07-10
**Nguồn thiết kế:** `DESIGN-legacy-screens-macos.md` · Review hình: 2 artifact trước/sau đã duyệt.
**Người thực thi:** `platform-shell-agent` (qua skill `mindful-key:mindful-keyboard-harness`).

> Đây KHÔNG phải LOCKED spec — là plan thi công + bộ prompt copy-dán được, đóng vai trò file
> story cho 1.7-1.10 (xem `epics.md` + `sprint-status.yaml` + `decision-log.md` 2026-07-10 —
> quyết định có chủ đích không viết đủ format `.story.md` cho 4 việc "thay áo" thuần này).

---

## 0. Sự thật kiến trúc đã verify (không đoán) — CẬP NHẬT 2026-07-10

- 4 màn = 4 cửa sổ, mỗi màn 1 file VC riêng: `ViewController.m` (Điều khiển),
  `MacroViewController.mm` (Gõ tắt), `ConvertToolViewController.mm` (Chuyển mã),
  `AboutViewController.m` (Thông tin).
- **Cả 4 màn vẽ chung 1 file `Main.storyboard`** (65 `<button>`, 4 `<popUpButton>`, 37 `<textField>`).
- Màu **cam** trên checkbox: gần như là **accent color hệ thống macOS**, không phải hardcode.
- 2 nút Convert xanh = **ảnh** `StartConvert` (▶) + `OK` (✓) gắn trong storyboard.
- Chưa bundle font Montserrat/Inter trong app.
- **⚠️ ĐÃ CÓ `BrandControls.h/.m` + `BrandColors.h/.m`** (story 1.1, code xong + commit
  4dcc947). **KHÔNG tạo helper trùng lặp (MKBrandKit) — dùng lại cái này.** API thật (đã đọc
  code, không đoán):
  - `Brand` (`BrandColors.h`): `+teal +tealLight +orange +orangeLight +charcoal +muted
    +softWhite +divider +stone` — đọc từ Assets.xcassets Color Set.
  - `PillSwitch : NSControl` — toggle **tự vẽ tay bằng `drawRect:`**, không phải category
    tint lên NSButton có sẵn. Comment gốc trong code giải thích rõ lý do: *"NSSwitch hệ thống
    không đổi được màu xanh-lá mặc định nếu không dùng API riêng tư"* → đây chính là lý do
    Story 0 (MKBrandKit) của bản plan CŨ **sai về kỹ thuật**: không có API `contentTintColor`
    đáng tin cậy để "ép" 65 checkbox cũ sang teal. Phải **THAY control**, không tint.
  - `StatusDot : NSView` — chấm tròn nhị phân, chỉ nhận `on`/`off`, không nhận biên độ/màu.
  - `CTAButton : NSButton` — nút cam nền `#FF7A1A`, chữ **luôn charcoal** (không bao giờ trắng),
    tự vẽ `drawRect:`, có hover/focus/active/disabled.
  - **CHƯA CÓ:** nút phụ trung tính (secondary) và card-wrapper (bo góc + bóng). Cần thêm —
    xem §1.2.
- **⚠️ `ViewController.m` đang có sửa đổi CHƯA COMMIT** (lát cắt dọc story 1.4 — mount
  `GatekeeperCardView` qua `viewDidAppear`/`mountGatekeeperCardIfNeeded`). File thật, không
  phải giả định — xem `git diff -- platforms/apple/macos/ViewController.m`.

## 1. Chiến lược (revise 2026-07-10)

### 1.1 Dùng lại BrandControls thật, không tạo MKBrandKit

Bản plan cũ định "pha 1 thùng sơn mới". Sai — thùng sơn **đã có sẵn và đã dùng thật** (`Brand`,
`PillSwitch`, `StatusDot`, `CTAButton`). Việc cần làm không phải tạo lại, mà là:

1. **Với checkbox (đổi cam → teal):** thay từng `NSButton` (buttonType checkbox) trong 4-tab
   bằng 1 `PillSwitch` thật (đã có class, đã proven trong story 1.1). Đây là việc **thay control**,
   không phải "gọi hàm tint" — cần định vị lại frame + nối target/action tới đúng thuộc tính
   BOOL mà checkbox cũ đang bind (đọc kỹ `ViewController.m` phần các `IBAction` liên quan trước
   khi thay, đừng đoán tên property).
2. **Với nút hành động (Thêm/Chuyển mã/Kiểm tra bản mới):** dùng `CTAButton` có sẵn.
3. **Với nút phụ (Xoá/Đóng/Nạp/Xuất):** `CTAButton`/`PillSwitch`/`StatusDot` không có sẵn kiểu
   này → **thêm 1 class mới `SecondaryButton : NSButton`** vào `BrandControls.h/.m` (nền trắng/
   viền `divider`, chữ `charcoal`, cùng style hover/focus/disabled như `CTAButton` nhưng không
   cam). Đây là **mở rộng có chủ đích** 1 file đã "done" (1.1) — ghi rõ trong PR/commit message,
   KHÔNG đổi API cũ, chỉ thêm class mới.
4. **Với "card bo góc":** không có class UIView riêng, các card mới (Gatekeeper) tự vẽ trong
   `drawRect:` của chính view đó. → **thêm 1 helper nhỏ** (category `NSView+MKCard` HOẶC hàm
   tiện ích trong `BrandControls`) áp `wantsLayer + cornerRadius 16 + shadow` lên 1 view chứa —
   agent tự quyết cách gọn nhất, miễn cùng 1 chỗ dùng lại được cho cả 4 story.
5. **Checklist bắt buộc trước khi nhân rộng ra 65 checkbox:** làm thử 1-2 checkbox đầu tiên,
   BUILD + CHẠY THẬT xem `PillSwitch` thay thế có giữ đúng hành vi cũ không (đọc đúng giá trị
   UserDefaults, bắn đúng action), rồi mới thay hàng loạt. Đừng thay hết 65 cái rồi mới build lần đầu.

### 1.2 Chỉ chạm storyboard/asset ở mức tối thiểu
Thay ảnh logo (About) + gỡ ảnh 2 nút Convert + thay từng checkbox bằng PillSwitch (đụng
storyboard vì control đang khai báo ở đó, không tránh được — nhưng mỗi story chỉ đụng đúng
phần scene của mình).

## 2. Sơ đồ phụ thuộc (thứ tự chạy) — revise 2026-07-10

```
BrandControls.h/.m (story 1.1 — ĐÃ XONG, đã commit)
   │  (mọi story sau dùng lại; 1.7-1.10 CÓ THỂ mở rộng thêm SecondaryButton + card helper)
   │
   ├──► 1.7 Điều khiển (ViewController.m)  ⚠️ PHỤ THUỘC 1.4 (đang dở, chưa commit, cùng file)
   ├──► 1.8 Gõ tắt      (MacroViewController.mm)        — độc lập, an toàn song song
   ├──► 1.9 Chuyển mã    (ConvertToolViewController.mm)  — độc lập, an toàn song song
   └──► 1.10 Thông tin   (AboutViewController.m + asset)  — độc lập, an toàn song song
```

- **Khuyên chạy 1.9 hoặc 1.8 TRƯỚC** (file cô lập hoàn toàn, không đụng gì đang dở) để verify
  pattern "thay checkbox bằng PillSwitch" + "thêm SecondaryButton/card helper vào BrandControls"
  hoạt động thật trên 1 màn nhỏ, rủi ro thấp — rồi mới làm 1.7 (rủi ro cao nhất: file đang có
  sửa đổi chưa commit của người khác/phiên khác).
- **1.7 bắt buộc đọc `git diff -- platforms/apple/macos/ViewController.m` TRƯỚC khi sửa** —
  không được ghi đè khối `mountGatekeeperCardIfNeeded`/property `gatekeeperCard`/`gatekeeperMounted`.
- Nếu 1.9/1.8/1.10 cùng lúc mở rộng `BrandControls.h/.m` (thêm `SecondaryButton`) → **chỉ 1
  story được thêm class mới, 3 story còn lại dùng lại** — tránh 2 agent cùng thêm trùng class.
  Khuyên: làm 1.9 trước, thêm `SecondaryButton` + card helper ở đó, 1.7/1.8/1.10 sau chỉ import dùng.

## 3. Cổng chất lượng (áp cho MỌI story — từ CLAUDE.md mindful-key)

Coi là "xong" chỉ khi:
- `make test` XANH (regression engine — dù đợt này không đụng `core/`, vẫn phải chạy lại).
- `make build` / `xcodebuild` sạch: 0 error, **KHÔNG thêm warning mới**.
- KHÔNG đụng `core/` (bộ não C++). KHÔNG đụng `EmotionWaveView.mm`. Với `ViewController.m`
  (chỉ 1.7): KHÔNG đụng khối `mountGatekeeperCardIfNeeded`/`GatekeeperCardView` đã có.
- KHÔNG để lại `// TODO`, `#if 0`, code chết. Surgical — chỉ sửa thứ trong phạm vi story.
- **Xem app thật**: mở đúng cửa sổ đó, mắt thấy đổi đúng, bấm thử checkbox/nút xem còn đúng
  hành vi cũ không (dùng skill `run`/`verify`).
- Debt delta = 0 so với baseline.

## 4. Kiểm HIẾN CHƯƠNG (soát cuối, mọi story)
- [ ] Cam `#FF7A1A` chỉ còn ở nút hành động (CTAButton) + link, KHÔNG ở checkbox/tab/trạng thái?
- [ ] Không còn xanh-dương/xanh-lá hệ thống ở nút Convert?
- [ ] Logo About = sóng `~` teal + dấu ngã cam, không còn "V" đỏ?
- [ ] Nút CTA cam luôn **chữ tối `#2A2A2A`** (đã tự động đúng nếu dùng `CTAButton` có sẵn)?
- [ ] Credit "Mai Vũ Tuyên (GPL v3)" còn nguyên ở About?
- [ ] PillSwitch thay thế checkbox vẫn đọc/ghi đúng UserDefaults như checkbox cũ (hành vi không đổi)?

---

# 5. BỘ PROMPT (copy-dán cho từng story)

> Cách dùng: mở phiên làm việc, chạy skill `mindful-key:mindful-keyboard-harness`, dán prompt
> tương ứng. Harness giao cho `platform-shell-agent`. **Khuyên thứ tự: 1.9 → 1.8 → 1.10 → 1.7**
> (dễ → khó, cô lập → chung file), khác thứ tự số cũ.

---

## PROMPT — Story 1.9 · Màn Chuyển mã (Convert) — LÀM TRƯỚC, ít rủi ro nhất

```
Bối cảnh: dự án mindful-key, thay áo cửa sổ Chuyển mã theo NOW BRAND OS. Đọc trước:
docs/AGENT-BRIEF.md (HIẾN CHƯƠNG §2.2/2.3), bmad-output/DESIGN-macos-control-panel.md §1
(token màu), bmad-output/DESIGN-legacy-screens-macos.md §4.3,
platforms/apple/macos/BrandControls.h + .m (ĐỌC KỸ code thật, đây là control tự vẽ tay, không
phải hàm tint) + BrandColors.h.

Việc: thay áo platforms/apple/macos/ConvertToolViewController.mm (+ scene "Convert" trong
Main.storyboard nếu buộc phải đụng để gỡ ảnh nút).

1. Trong BrandControls.h/.m: THÊM class mới `SecondaryButton : NSButton` (nền trắng/viền
   Brand.divider 1px, chữ Brand.charcoal, bo góc 8px, hover/focus/disabled cùng kiểu CTAButton
   nhưng không cam) — dùng lại được cho 3 story khác sau. KHÔNG đổi PillSwitch/StatusDot/CTAButton
   đã có. THÊM 1 helper card-wrap nhỏ (category NSView hoặc hàm tiện ích) áp bo góc 16px +
   bóng 0 8px 30px rgba(29,124,145,0.08) lên 1 container view.
2. Nút "Chuyển mã" (đang dùng ảnh StartConvert xanh dương ▶): gỡ ảnh, đổi class sang CTAButton
   (đã có, cam + chữ tối tự động đúng).
3. Nút "Đóng" (đang dùng ảnh OK xanh lá ✓): gỡ ảnh, đổi class sang SecondaryButton vừa thêm.
4. 2 nhóm checkbox (Tùy chọn chung / Lựa chọn): thay từng NSButton checkbox bằng PillSwitch —
   ĐỌC KỸ action/binding hiện tại của mỗi checkbox trong ConvertToolViewController.mm trước khi
   thay, giữ đúng hành vi (đừng đoán tên property). Bọc 2 nhóm vào card dùng helper ở bước 1.
5. Dropdown Bảng mã nguồn/đích + nút swap ⇄: giữ nguyên chức năng, chỉ chỉnh viền/bo góc nếu cần.

TUYỆT ĐỐI không thêm màu semantic đỏ-vàng-xanh-lá. Giữ nguyên chức năng chuyển mã. Không đụng
core/, không đụng ViewController.m/GatekeeperCardView/EmotionWaveView. Xong: build sạch, MỞ APP
thử chuyển 1 chuỗi thật + bấm thử từng checkbox xem còn đúng hành vi, make test xanh, không
warning mới. Soát HIẾN CHƯƠNG §5 trong design doc.
```

---

## PROMPT — Story 1.8 · Màn Gõ tắt (Macro)

```
Phụ thuộc: Story 1.9 đã xong (dùng lại SecondaryButton + card helper vừa thêm vào
BrandControls — ĐỌC lại BrandControls.h/.m trước, đừng tạo trùng). Đọc
DESIGN-legacy-screens-macos.md §4.2. Chỉ đụng platforms/apple/macos/MacroViewController.mm
(+ scene "Macro" nếu buộc).

Việc:
- Đặt tên 2 cột bảng tiếng Việt: "Từ gõ tắt" / "Nội dung đầy đủ" (bỏ placeholder "Table View Cell").
- Nút "＋ Thêm" → đổi class sang CTAButton. "－ Xoá", "Nạp từ file…", "Xuất ra file…" → SecondaryButton.
- Checkbox "Tự động viết hoa theo phím tắt" → thay bằng PillSwitch (đọc đúng action/binding hiện
  tại trước khi thay).
- Bảng + control bọc card (dùng helper đã thêm ở 1.9).

Giữ nguyên chức năng. Không đụng core/, ViewController.m. Xong: build sạch, MỞ APP xem cửa sổ Gõ
tắt + thử thêm/xoá 1 dòng thật, make test xanh, không warning mới. Soát HIẾN CHƯƠNG §5.
```

---

## PROMPT — Story 1.10 · Màn Thông tin (About)

```
Phụ thuộc: Story 1.9 đã xong (dùng lại SecondaryButton/card helper nếu cần — ĐỌC lại
BrandControls.h/.m trước). Đọc DESIGN-legacy-screens-macos.md §4.4 + docs/BRAND-ASSETS.md.
Chỉ đụng platforms/apple/macos/AboutViewController.m + asset logo (Resources/Assets.xcassets + brand/).

Việc:
- Thay logo "V" đỏ bằng glyph sóng ~ teal + dấu ngã cam. Lấy từ brand/svg/, xuất qua
  brand/export.sh vào asset; KHÔNG tự vẽ logo mới. Nếu asset chưa có, DỪNG và báo (đừng chế logo).
- VÁ BUG đè chữ: "Trang GitHub:" đang chồng lên "Dựa trên OpenKey…". Layout lại 2 dòng rời nhau
  (đọc constraint/frame hiện tại trong storyboard trước khi sửa, đừng đoán). Bỏ hoặc điền dòng
  "Fanpage:" đang trống.
- Link GitHub = màu Brand.teal; checkbox "Kiểm tra bản mới khi khởi động" → PillSwitch; nút
  "Kiểm tra bản mới…" → CTAButton.
- ⚠️ KHÓA PHÁP LÝ: giữ NGUYÊN "Dựa trên OpenKey — Mai Vũ Tuyên (GPL v3)". Không đổi, không xóa
  (ràng buộc HIẾN CHƯƠNG). Nếu định đụng dòng này → DỪNG, hỏi chủ dự án trước.

Không đụng core/, ViewController.m. Xong: build sạch, MỞ APP xem cửa sổ Thông tin (logo đúng,
hết đè chữ, còn credit), make test xanh, không warning mới. Soát HIẾN CHƯƠNG §5.
```

---

## PROMPT — Story 1.7 · Màn Điều khiển (4 tab) — LÀM SAU CÙNG, rủi ro cao nhất

```
⚠️ BẮT BUỘC bước đầu tiên: chạy `git diff -- platforms/apple/macos/ViewController.m` và ĐỌC
KỸ toàn bộ output trước khi viết bất kỳ dòng nào. File này đang có sửa đổi CHƯA COMMIT từ story
1.4 (lát cắt dọc) — mount GatekeeperCardView qua viewDidAppear/mountGatekeeperCardIfNeeded.
TUYỆT ĐỐI KHÔNG xoá/sửa/ghi đè: property `gatekeeperCard`, `gatekeeperMounted`, method
`mountGatekeeperCardIfNeeded`, và lệnh gọi nó trong viewDidAppear. Việc của story này là sửa
THÊM vào phần code 4-tab CŨ (phần chưa đụng tới của lát cắt dọc), không phải viết lại file.

Phụ thuộc: Story 1.9 đã xong (dùng lại SecondaryButton/card helper — ĐỌC lại BrandControls.h/.m
trước). Đọc bmad-output/DESIGN-legacy-screens-macos.md §4.1 và §3.

Việc: thay áo PHẦN 4-TAB của ViewController.m (không đụng phần Gatekeeper đã mount):
- Mọi checkbox (Phím chuyển, 2 lưới trong 4 tab Bộ gõ/Gõ tắt/Hệ thống/Thông tin, Kêu beep...) →
  thay bằng PillSwitch. ĐỌC KỸ action/IBOutlet hiện tại của TỪNG checkbox trước khi thay — đây
  là ~30+ control, làm thử 2-3 cái đầu, BUILD + CHẠY THẬT xác nhận hành vi giữ nguyên (đọc/ghi
  đúng UserDefaults) rồi mới nhân rộng, đừng thay hết rồi mới build lần đầu.
- Tab đang chọn: cần cách hiển thị "đang chọn" bằng teal thay vì cam hệ thống — tự tìm cơ chế
  đúng (có thể đã có code custom cho tab, đọc trước khi sửa), không phải chỉ đổi 1 màu string.
- Gom các nhóm control vào card (dùng helper đã thêm ở 1.9).
- Radio "Chế độ gõ": tint teal (đọc xem có cần thay control tương tự PillSwitch không, hay
  NSButton radio có API tint hợp lệ — verify bằng build thật, đừng đoán).
- Nút mở "Bảng gõ tắt…": đổi class sang SecondaryButton.

Giữ NGUYÊN chức năng + nhãn tiếng Việt. Không dời control sang màn khác. Không đụng core/,
GatekeeperCardView.mm/EmotionWaveView.mm, và không đụng khối mount đã nói ở trên. Xong: build
sạch + MỞ APP xem cửa sổ Điều khiển thật (card Gác cổng vẫn nổi trên đỉnh, 4 tab bên dưới đã
thay áo, bấm thử vài checkbox xem đúng hành vi), không warning mới, make test xanh. Soát
checklist HIẾN CHƯƠNG §5 trong design doc.
```

---

## PROMPT — Điều phối tổng (nếu muốn giao cả gói 1 lần)

```
Chạy skill mindful-key:mindful-keyboard-harness. Đọc bmad-output/IMPLEMENTATION-PLAN-legacy-reskin.md
VÀ bmad-output/decision-log.md (entry 2026-07-10 "Reconciliation"). Điều phối story 1.7-1.10 cho
platform-shell-agent theo đúng thứ tự: 1.9 TRƯỚC (thêm SecondaryButton + card helper vào
BrandControls.h/.m, ít rủi ro nhất), rồi 1.8, 1.10 (song song được, đều đọc lại BrandControls
mới), CUỐI CÙNG 1.7 (rủi ro cao nhất — cùng file ViewController.m với story 1.4 đang dở, chưa
commit). Mỗi story qua đủ cổng chất lượng (make test xanh, make build sạch, xem app thật, soát
HIẾN CHƯƠNG §5) mới sang story kế. KHÔNG đụng core/ và không đụng khối mountGatekeeperCardIfNeeded
trong ViewController.m. Báo lại sau mỗi story.
```

---

## 6. Sau đợt này (ghi để nhớ, KHÔNG làm bây giờ)
- Bundle font Montserrat/Inter thật vào app (hiện dùng font hệ thống).
- Story 1.5 (bell-settings-card): cách gắn UI chưa chốt (nổi thành card thứ 2 hay nhét vào 1
  trong 4 tab) — hỏi chủ dự án khi tới lúc làm, không tự quyết.
- Nối panel mới (Gatekeeper/EmotionWave) đầy đủ vào luồng cửa sổ chính (hiện chỉ có Gatekeeper).
