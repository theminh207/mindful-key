# Decision Log — mindful-key · iOS

Log riêng của đội iOS (khác `bmad-output/decision-log.md` ở root — chỗ đó dành cho quyết định
xuyên suốt nhiều đội, xem `bmad-output/_shared/README.md`). Threaded, append-only: thêm entry
mới ở TRÊN CÙNG (mới nhất trước), không xoá/sửa entry cũ.

## Entry format

```
### YYYY-MM-DD — <short title>
- **Decision:** <what was decided>
- **Rationale:** <why; alternatives considered>
- **Made by:** <skill/workflow>
- **Supersedes:** <link to prior entry, if any>
```

---

### 2026-07-10 — UX Update: thêm màn Bàn phím + Cài đặt (đầy đủ) + mục Future Round 2/3 (v0.2)
- **Decision:** Mở rộng DESIGN.md (§2.11 Segmented control + Slider — màu chọn = teal, KHÔNG
  xanh-lá hệ thống) + EXPERIENCE.md 2 màn đặc tả đầy đủ (Bàn phím Mindful Key với states
  Shift/Caps/lớp số/secure field; Cài đặt bàn phím với preview sống + slider + segmented) và
  1 mục "Future Screens (Round 2/3)".
- **Ranh giới cố ý:** chia làm 2 nhóm. Nhóm A (bàn phím, cài đặt) = thuần công cụ/Round 1,
  đặc tả ĐẦY ĐỦ. Nhóm B (sóng cảm xúc B1, nhật ký B2, soi lại B3) = chạm nhận diện + dữ liệu
  cảm xúc → CHỈ chốt phần bám hiến chương + tiền lệ macOS đã duyệt; mọi quyết định sản phẩm
  còn mở đánh dấu **❓** để chủ dự án chốt, KHÔNG tự bịa hành vi. Đúng hiến chương "chạm nhận
  diện mà mơ hồ → hỏi chủ dự án".
- **Contrast component mới đã verify thật:** segmented đoạn chọn (pill trắng + tealStrong
  #155A66 = 7.82:1), đoạn không chọn (muted #666666/tealLight = 5.04:1), slider track teal/
  divider = 3.90:1 (graphic ≥3). Ghi vào DESIGN §3.
- **Quyết định mở nổi bật cần chủ dự án (tóm trong EXPERIENCE Future):** map send-risk→biên
  độ sóng + có/không câu quan sát (B1); nhật ký iOS hiện gì + nút xoá + App Group ownership
  (B2); soi-lại là màn hay notification (B3).
- **Made by:** bmad-ux (Update), gọi bởi agent đội iOS.
- **Supersedes:** none (mở rộng v0.1, không phá phần cũ).

### 2026-07-10 — UX design: DESIGN.md + EXPERIENCE.md, phát hiện + vá 2 lỗi contrast trong mockup
- **Decision:** Tạo `bmad-output/ios/DESIGN.md` (hệ thống design bền cho cả app iOS) +
  `EXPERIENCE.md` (journey Round 1 + phác Round 2). Chạy `bmad-ux/scripts/contrast-check.py`
  kiểm THẬT mọi cặp màu brand trước khi chốt token — số ghi trong DESIGN §3 là output thật.
- **2 lỗi accessibility phát hiện khi verify (mockup HTML tao dựng trước đó dính cả 2):**
  (1) teal `#1D7C91` trên tealLight `#E8F2F4` = 4.24:1 → TRƯỢT AA normal. Vá: badge số bước
  dùng `tealStrong #155A66` (6.86:1). (2) stone `#8A9BA0` = 2.72:1 → TRƯỢT cả ngưỡng graphic
  3:1 cho đường phẳng "không bao giờ". Vá: thêm `stoneStrong #5E6E73` (5.00:1) cho graphic
  mang nghĩa; giữ `stone` gốc CHỈ cho con sóng trang trí (Round 2). Cả 2 token phái sinh
  KHÔNG đặt vào BrandPalette.h (đó là nguồn màu gốc), chỉ khai trong DESIGN.md.
- **Nguyên tắc design mới nâng thành luật:** "biên độ mang nghĩa" (amplitude-as-meaning,
  DESIGN §2.10) — phân biệt trạng thái đối lập bằng SÓNG `~` vs ĐƯỜNG PHẲNG, không bao giờ
  bằng ✓xanh/✗đỏ. Đúng hiến chương §2.3 tuyệt đối + không phụ thuộc màu (mù màu vẫn đọc) +
  nghĩa luôn kèm nhãn chữ. Đã áp ở màn Full Access.
- **Phạm vi cố ý:** DESIGN = toàn app (bền mọi round); EXPERIENCE = bám Round 1 (2 màn
  onboarding + gõ Telex + home tối thiểu), Round 2+ chỉ phác. Quick Flow → giữ gọn, không phình.
- **Ranh giới hiến chương ghi rõ trong EXPERIENCE:** KHÔNG journey "chặn Enter/gác cổng" trên
  iOS (mandate 2026-07-10). KHÔNG semantic đỏ-xanh. Lỗi hệ thống ≠ cảm xúc → không tô đỏ.
- **4 câu hỏi mở để chủ dự án chốt** (cuối EXPERIENCE): giọng copy, giữ/bỏ nút "Để sau",
  glyph sóng chính thức, wordmark/logo.
- **Made by:** bmad-ux (Create), gọi bởi agent đóng vai kỹ sư đội iOS.
- **Supersedes:** none (mockup HTML là bản thử ngoài BMAD; DESIGN.md nay là nguồn chuẩn,
  mockup cần sửa 2 màu theo token đã vá nếu còn dùng làm tham chiếu).

### 2026-07-10 — tech-spec created, đã verify bằng thực nghiệm compile thật
- **Decision:** Tạo `bmad-output/ios/tech-spec.md` trả lời 6 mục kỹ thuật bắt buộc (XcodeGen
  target, cầu nối core, trần RAM, container↔extension detection, Nhịp 0 extract, tests/ios).
  Trước khi viết, đã đọc trực tiếp `platforms/apple/project.yml`, `core/engine/`,
  `core/mood/`, `platforms/apple/macos/*` và CHẠY THỰC NGHIỆM: compile 5 file `core/engine/*.cpp`
  cho target `arm64-apple-ios16.0-simulator` (clang++ trực tiếp, không qua Xcode project) —
  link thành công, binary Mach-O 198KB, KHÔNG sửa dòng nào trong `core/`.
- **Rationale:** Chủ dự án yêu cầu tường minh "không viết chay" — tech-spec phải dựa trên bằng
  chứng đọc được/chạy được trong repo, không suy diễn. Thực nghiệm compile trực tiếp trả lời
  được phần rủi ro kỹ thuật cốt lõi của Problem statement trong SPEC.md (core/engine build được
  trong môi trường iOS hay không) bằng dữ liệu thật thay vì lý thuyết.
- **Phát hiện quan trọng nhất:** Nhịp 0 hoá ra rút được RẤT ÍT nguyên xi từ `platforms/apple/macos/`
  — chỉ 3 thứ (bảng char→keycode, khối default 20 biến config, giá trị hex màu). Toàn bộ
  `.m`/`.mm` khác đều gắn chặt AppKit (`NSColor`) hoặc Carbon/CGEventTap, không tồn tại trên
  iOS. Phần "gửi ký tự" của `OpenKey.mm` (dùng CGEventTap) phải viết lại hoàn toàn cho
  `UITextDocumentProxy` — đây là khác biệt kiến trúc thật, không phải chi tiết vặt.
- **Made by:** bmad-tech-spec (Create), gọi bởi agent đóng vai kỹ sư đội iOS.
- **Supersedes:** none

### 2026-07-10 — SPEC created (Round 1: walking skeleton)
- **Decision:** Tạo `bmad-output/ios/SPEC.md` — kernel 5 field cho Round 1 của đội iOS, track
  Quick Flow. Scope: keyboard extension iOS build + gõ Telex qua `core/engine` nguyên vẹn,
  onboarding kích hoạt + Full Access, thêm target iOS vào `platforms/apple/project.yml`, và
  Nhịp 0 (rút code dùng-chung-được ra `platforms/apple/shared/`).
- **Source:** Kernel do chủ dự án cung cấp trực tiếp (vai trưởng nhóm iOS), đối chiếu
  `docs/AGENT-BRIEF.md` + `/Users/now/Projects/mindful-keyboard/docs/MOBILE-UX-ANALYSIS.md`.
- **Key scope decision:** Non-Goal — KHÔNG làm gác cổng/nhịp thở (kể cả bản "nhắc" theo Phương
  án A) ở Round 1, dời sang Round 2. Lý do: `MOBILE-UX-ANALYSIS.md` §3 kết luận Feature #1
  không port thẳng được lên iOS (sandbox không thấy nút Gửi/host app) — cần thiết kế lại,
  ngoài phạm vi walking skeleton chỉ chứng minh engine chạy được trong extension.
- **Made by:** bmad-spec (Create), gọi bởi agent đóng vai kỹ sư đội iOS.
- **Supersedes:** none

### 2026-07-10 — Ghi chú vận hành: log riêng đội iOS thay vì log chung root
- **Decision:** Đội iOS dùng `bmad-output/ios/decision-log.md` riêng cho quyết định nội bộ
  Round 1, thay vì ghi vào `bmad-output/decision-log.md` ở root như hành vi mặc định của skill
  `bmad-spec`.
- **Rationale:** Quyết định phạm vi kernel Round 1 là việc NỘI BỘ đội iOS, không phải quyết
  định xuyên suốt nhiều đội (đó mới là việc của log root, theo quy ước đã chốt khi tách
  `bmad-output/` thành `_shared/`/`macos/`/`ios/`). `bmad-output/config.yaml` vẫn trỏ
  `decision_log: bmad-output/decision-log.md` ở root — CHƯA sửa field đó, vì đó là quyết định
  ảnh hưởng chung (chủ dự án cần xác nhận trước khi đổi single-source-of-truth path cho tool
  BMAD). **Cần chủ dự án xác nhận** đây có đúng ý hay muốn đội iOS vẫn ghi vào log root.
- **Made by:** agent đóng vai kỹ sư đội iOS (quyết định vận hành, ngoài phạm vi skill bmad-spec).
- **Supersedes:** none
