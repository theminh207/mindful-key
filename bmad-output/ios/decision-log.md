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
