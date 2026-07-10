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

## Ghi chú

- File này bổ cho `TEST_MATRIX.md`: **ma trận** phơi *cái gì chưa được chứng minh*,
  **friction-log** phơi *chỗ nào AI phải đoán* — hai góc mù khác nhau.
- Khi một dòng chuyển sang `đã chốt`, ghi rõ luật/quyết định nằm ở đâu (vd: "đã cập
  nhật `docs/AGENT-BRIEF.md §3.2`" hoặc "changelog CLAUDE.md ngày …").
