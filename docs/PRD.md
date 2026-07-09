# PRD — Mindful Keyboard: macOS MVP

## 1. Định vị: "Người gác cổng cảm xúc" (Emotional Gatekeeper)

Đây **không phải** một bộ gõ tiếng Việt có thêm tính năng theo dõi tâm trạng cho vui. Định vị ngược lại: một bộ gõ tiếng Việt tồn tại vì **một nhiệm vụ duy nhất** — đứng giữa bạn và khoảnh khắc bạn sắp gửi đi thứ mà 5 phút sau bạn sẽ hối hận.

**Feature #1 (không phải feature thứ n):** một khoảng dừng chánh niệm (mindful pause) ngay trước khi một tin nhắn đang giận dữ được gửi đi trong app chat. Mọi tính năng khác (thống kê, nhật ký, chuông tỉnh thức) phục vụ cho feature này, không ngang hàng với nó.

**Người dùng chính:** cộng đồng thực hành chánh niệm (thiền, mindfulness) — không phải "mọi người gõ tiếng Việt". Đây là nhóm đã có sẵn động lực nội tại để chấp nhận "chậm lại 1 nhịp", nên ma sát (friction) mà sản phẩm tạo ra được đón nhận như một tính năng, không phải một phiền toái.

**Vì sao macOS trước:** máy dev hiện tại là macOS — build/thử tại chỗ, không phải chờ máy Windows + Visual Studio. Đổi lại macOS "trói tay" hơn: phải xin quyền **Accessibility + Input Monitoring**, và muốn phát hành ngoài phải **ký (Developer ID) + notarize** với Apple. MVP này **phân phối trực tiếp qua .dmg đã ký/notarize, không qua Mac App Store** — App Store review không cần thiết cho closed beta và áp thêm ràng buộc (sandbox) không tương thích với việc bắt phím toàn cục.

## 2. Vòng lặp lõi: Sense → Pause → Remind → Reflect

1. **Sense (Cảm nhận)** — `MoodBuffer` (C++ dùng chung) + `MoodWatchMac` đọc câu vừa gõ xong qua callback `vOnWordCommitted` của engine, tính ra **1 điểm send-risk (0–1)** — không phải phân loại nhiều cảm xúc. Chạy on-device, bất đồng bộ (dispatch ra khỏi CGEventTap thread), chỉ tại điểm kết câu — không được làm khựng gõ.
2. **Pause (Dừng lại)** — khi send-risk vượt ngưỡng VÀ vỏ macOS phát hiện người dùng sắp gửi (Enter/nút Gửi) trong một app chat đã allow-list (Zalo, Messenger, Telegram), hiện một `NSPanel` nổi ~3 giây với "Vẫn gửi"/"Đợi chút". Đây là **ma sát mềm**, không phải chặn cứng — nút Gửi không bao giờ bị khóa, quyết định cuối cùng luôn thuộc về người dùng.
3. **Remind (Nhắc)** — câu chữ trên panel ngắn, không phán xét, không cảnh cáo, không chấm điểm.
4. **Reflect (Suy ngẫm)** — chuông chánh niệm (`BellMac`) rung theo chuỗi câu căng thẳng phát hiện được (không chỉ theo đồng hồ); cuối ngày, màn hình trong app trên thanh menu đọc lại kho dữ liệu local, hiện tóm tắt đỉnh căng thẳng + 1 câu phản chiếu + 1 gợi ý nhỏ — không gamify.

MVP thành công = vòng lặp này chạy mượt trên macOS, trong ít nhất 2–3 app chat phổ biến.

## 3. Non-goals (loại trừ rõ ràng)

- **Không phải add-on vui vui** — mood tracking không phải tính năng phụ, nó chính là lý do sản phẩm tồn tại.
- **Không phải công cụ giám sát** — không phải parental control, không phải employee monitoring. Dữ liệu chỉ người gõ được xem; không có chế độ báo cáo/xem từ xa cho người khác.
- **Không chặn cứng việc gửi** — luôn là ma sát mềm; ép buộc sẽ khiến người dùng gỡ cài đặt ngay (đã cảnh báo trong `docs/OPENKEY-MAP.md`).
- **Không gửi câu gõ gốc ra khỏi máy** dưới bất kỳ lý do nào, kể cả "để cải thiện model".
- **Không qua Mac App Store ở MVP này** — phân phối trực tiếp qua .dmg đã ký + notarize.
- **Không hứa phủ hết mọi app chat** — MVP giới hạn ở 2–3 app đã test kỹ (Zalo/Messenger/Telegram); phát hiện "sắp gửi" dựa trên allow-list + Enter-không-Shift qua CGEventTap, không phải AX semantic "nút Gửi" riêng từng app.
- **Không đa nền tảng ở MVP này** — chỉ macOS. Windows/Android/iOS là lộ trình sau, ngoài phạm vi PRD này (Windows tái dùng engine + design đã có, nhưng cần vỏ Win32 riêng).
- **Không cần model sentiment thật ở MVP** — dùng lexicon/heuristic hiện có để tính send-risk; PhoBERT ONNX on-device là fast-follow, không phải điều kiện để ra mắt MVP.
- **Không nhắm độ chính xác tuyệt đối** — chấp nhận sai số vừa phải miễn không gây phiền quá mức; vùng mù đã biết (chỉ hoạt động khi gõ tiếng Việt, bộ gõ đang bật, ngoài ô mật khẩu) được công khai với người dùng, không che giấu.

## 4. Success metrics (đo được, đúng tầm MVP)

MVP nhắm nhóm nhỏ (cộng đồng chánh niệm), nên không đặt mục tiêu tăng trưởng — mục tiêu là **validate vòng lặp lõi**:

- Có instrument đo được: tỷ lệ khoảnh khắc "pause" mà người dùng chủ động sửa/không gửi sau khi thấy nhắc nhở.
- Tỷ lệ cảnh báo "đúng ngữ cảnh" theo tự đánh giá nhanh của người dùng ngay tại panel (nút "đúng"/"sai"), theo dõi xu hướng theo thời gian.
- **Zero** báo cáo giật/khựng gõ do lớp cảm xúc gây ra — điều kiện sống còn, không phải số liệu tăng trưởng.
- **Zero** rớt onboarding vì màn xin quyền Accessibility/Input Monitoring gây hoang mang — theo dõi tỷ lệ hoàn tất cấp quyền.
- Người dùng tự nguyện mở màn soi lại cuối ngày ≥ 1 lần/tuần — chỉ báo bước "reflect" có giá trị thật, không chỉ "pause" hữu ích.

## 5. Nguyên tắc riêng tư: 100% on-device

- Câu gõ gốc **không bao giờ** rời khỏi máy — toàn bộ xử lý cảm xúc chạy on-device.
- Kho dữ liệu local (SQLite, mã hoá) chỉ chứa **send-risk score + timestamp + app category** — không bao giờ chứa văn bản gốc.
- Cần sự đồng ý rõ ràng khi bật lớp cảm xúc lần đầu (onboarding consent), có thể tắt bất cứ lúc nào, có nút xoá toàn bộ nhật ký.
- Vùng mù phải được nói thẳng với người dùng ngay từ onboarding, không ngầm định "bắt được hết".
- **Zero network telemetry** mặc định — không có đồng bộ cloud ở MVP này.

## 6. Phạm vi kỹ thuật MVP

macOS only (Mojave+/Xcode, deployment target 10.15+), dùng nguyên bộ não OpenKey đã fork + callback đã cắm sẵn (`vOnWordCommitted`); vỏ = `OpenKey.xcodeproj`/`ModernKey` (menu-bar app có sẵn, CGEventTap + Accessibility có sẵn); mood layer dùng lexicon quy về 1 điểm send-risk (chưa cần PhoBERT ONNX); UI = `NSPanel` nổi tại thời điểm "pause" + màn soi lại trong app trên thanh menu; đóng gói `.dmg` ký Developer ID + notarize, launch-at-login, zero telemetry.
