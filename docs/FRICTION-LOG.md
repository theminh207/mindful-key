# FRICTION-LOG — sổ ghi "chỗ phải đoán"

> Mỗi khi một agent (hoặc chủ dự án) phải **suy diễn vì thiếu luật / thiếu nguồn sự
> thật**, ghi lại đúng chỗ đó thành một dòng. Đây không phải nhật ký lỗi — nó là
> danh sách *"chỗ nào trong dự án còn mơ hồ nên AI phải đoán"*, tức là **danh sách
> việc nên viết luật / chốt quyết định tiếp theo**.
>
> Viết **cụ thể**. Tốt: *"install script không copy docs Phase 2, nhưng chuyện đó
> ngoài phạm vi"*. Kém: *"docs khó hiểu"*. Càng cụ thể càng dễ chốt.

## Cách dùng

- **Khi nào thêm dòng:** bất cứ lúc nào phải đoán một quy tắc, một đường dẫn, một ý
  đồ sản phẩm mà đáng lẽ phải có sẵn nhưng không tìm thấy.
- **Trạng thái:** `mở` (chờ chốt) · `đã chốt` (đã viết luật/quyết định, kèm nơi ghi).
- **Không xóa dòng đã chốt** — giữ vết để biết dự án từng mơ hồ ở đâu.

## Bảng

| Ngày | Việc | Chỗ phải đoán (cụ thể) | Đã tạm xử sao | Cần chốt gì | Trạng thái |
|---|---|---|---|---|---|
| 2026-07-08 | Cấu trúc thư mục nguồn | Hiến chương §3.2 nói cấu trúc đích là `Sources/MindfulKeyboard/` + XcodeGen, nhưng bản gốc là `OpenKey/Sources/OpenKey/…` + `.xcodeproj` commit sẵn | **Đã migrate** trong repo `mindful-key`: `core/engine` + `core/mood` (bộ não C++ dùng chung) + `platforms/<os>/` (vỏ native) + XcodeGen (`platforms/apple/project.yml`, `make generate`). Tên thư mục khác §3.2 (`core/`+`platforms/` thay vì `Sources/MindfulKeyboard/`) nhưng đúng tinh thần: modular + XcodeGen thay `.xcodeproj` commit | Đã chốt cấu trúc `core/`+`platforms/`. (Việc còn lại: `.claude/` chưa theo path mới — xem dòng 2026-07-10 dưới) | đã chốt |
| 2026-07-08 | Thang màu brand cho cảm xúc | Một số asset đang dùng thang teal→cam-bão-hòa để mã hóa cảm xúc, khác luật 2.3 (nhận diện theo **biên độ** + sắc độ **trung tính, không bão hòa**) | Giữ asset hiện tại, chưa soát lại | Chủ dự án chốt: soát lại toàn bộ asset theo 2.3 (biên độ, không dùng màu bão hòa để chấm điểm cảm xúc) | mở |
| 2026-07-10 | Gác cổng Feature #1 trên iOS | iOS keyboard extension bị sandbox: không thấy nút Gửi host app, không tap toàn cục như `CGEventTap` macOS → **không chặn được** gửi tin. Android chỉ chặn được phím action khi `imeOptions=actionSend`. Feature #1 hoá ra không đồng đều giữa 3 OS | **Chủ dự án đã chốt (2026-07-10):** iOS chấp nhận giới hạn sandbox — mandate hẹp lại còn **nhật ký cảm xúc + nhắc chánh niệm thụ động** (gợn sóng `~` ambient), KHÔNG chặn Enter xuyên app. Nhận diện "người gác cổng" giữ ở macOS/Windows; iOS thể hiện cùng tinh thần chánh niệm ở mức "quan sát + nhắc", không "chặn". Ghi ở: TEST_MATRIX (khối Đội iOS, dòng gác cổng iOS = `retired`), `platforms/apple/ios/README.md`, agent `ios-shell-agent`, skill `ios-keyboard-extension` | Đã chốt mandate iOS = nhật ký + nhắc thụ động | đã chốt |
| 2026-07-10 | `.claude/` (agents + skills) còn path cũ | `engine-agent.md`, `platform-shell-agent.md`, skill `platform-porting`/`openkey-engine` vẫn nói path bản gốc (`OpenKey/Sources/OpenKey/engine/`, `win32/`, `macOS/`) trong khi repo con đã đổi sang `core/engine`, `platforms/apple/macos`, `platforms/windows/` | File mới/đụng lần này (harness orchestrator, `ios-shell-agent`, `ios-keyboard-extension`, phần routing) dùng path đúng của con; các file cũ chưa đụng vẫn giữ path cũ để không sửa ngoài phạm vi yêu cầu | Chủ dự án chốt: có nên quét đổi hết path cũ trong `.claude/agents` + `.claude/skills/{openkey-engine,platform-porting}` sang path `core/`+`platforms/` không? | mở |
| 2026-07-12 | Onboarding iOS — lối tiến khi App Group hỏng | Màn 01→02 CHỈ tiến qua nhịp tim App Group (container đọc lúc foreground, story 1.6/AppDelegate). KHÔNG có nút "tiếp tục" thủ công. Phát hiện khi test tay: App Group đọc rỗng → người dùng **kẹt Màn 01 vĩnh viễn**, nút "Mở Cài đặt" chỉ quay vòng. Đây là single-point-of-failure cho toàn bộ onboarding | Round 1 giữ nguyên cơ chế heartbeat (EXPERIENCE.md không đặc tả fallback tiến thủ công). Xem 2 màn tiếp bằng bản build preview tạm (đã revert nguồn) | **Chủ dự án chốt:** có thêm lối thoát thủ công không? (vd nút "Tôi đã bật rồi, tiếp tục" ở Màn 01; hoặc: quay từ Cài đặt về mà vẫn NeverRan sau N giây thì vẫn cho tiến). Chạm UX onboarding + robustness | mở |
| 2026-07-12 | Kiểm App Group heartbeat trên Simulator | Entitlement App Group KHÔNG nhúng vào binary iOS Simulator với cấu hình ký hiện tại (`CODE_SIGN_STYLE: Manual` + `CODE_SIGN_IDENTITY: "-"` + `CODE_SIGNING_ALLOWED: NO`, không team). `codesign -d` không thấy group; `NSUserDefaults(suiteName:)` trả rỗng; gieo giá trị vào cả shared-container lẫn app-container đều không được app đọc. → detect "đã kích hoạt" không chạy được trên Simulator | Xếp heartbeat detection (story 1.6, FR-A06) vào nhóm **device-only** cùng Zalo/RAM (Phần D `tests/ios/MANUAL-TEST-SCRIPT.md`). Gõ Telex + UI + Shift/số vẫn test đủ trên Simulator | (Kỹ thuật, không gấp) muốn chỉnh cấu hình ký để entitlement nhúng được trên Simulator (test App Group tại chỗ), hay chấp nhận App Group chỉ verify trên máy thật? | mở |

## Ghi chú

- File này bổ cho `TEST_MATRIX.md`: **ma trận** phơi *cái gì chưa được chứng minh*,
  **friction-log** phơi *chỗ nào AI phải đoán* — hai góc mù khác nhau.
- Khi một dòng chuyển sang `đã chốt`, ghi rõ luật/quyết định nằm ở đâu (vd: "đã cập
  nhật `docs/AGENT-BRIEF.md §3.2`" hoặc "changelog CLAUDE.md ngày …").
