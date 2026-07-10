---
name: ios-keyboard-extension
description: Build/port bộ gõ chánh niệm sang iOS — Custom Keyboard Extension (App Extension), sống ở platforms/apple/ios/, test ở tests/ios/. PHẢI dùng khi việc nhắc tới bàn phím iOS, keyboard extension, App Group, Full Access, SwiftUI/UIKit trong khung bàn phím, hoặc "iOS làm được gì". Mandate cố ý HẸP (chốt 2026-07-10): nhật ký cảm xúc + nhắc chánh niệm thụ động, KHÔNG gác cổng gửi tin xuyên app (sandbox iOS chặn). KHÔNG dùng để sửa core/ (bộ não dùng chung) — lỗi riêng iOS sửa ở vỏ platforms/apple/ios/, không sửa engine.
---

# iOS Keyboard Extension

## Cổng an toàn (đọc TRƯỚC khi sửa — kể cả khi được gọi thẳng, không qua orchestrator)
- **Phân loại rủi ro:** việc chạm **nhận diện** (con sóng/màu/copy/biên độ) · **pháp lý** (GPL v3, credit Mai Vũ Tuyên) · **riêng tư** (dữ liệu gõ/mood, Full Access, App Group, nơi lưu) · **sửa core/ để vá riêng iOS** → **DỪNG, hỏi chủ dự án trước.** Việc nhỏ, rõ, không nhạy cảm → làm luôn.
- **Phải đoán vì thiếu luật/nguồn sự thật?** → thêm 1 dòng cụ thể vào `docs/FRICTION-LOG.md`.

## Kiến trúc: 1 BỘ NÃO + N CÁI VỎ (iOS là vỏ thứ 5)
```
core/engine   ← bộ não C++ dùng chung, KHÔNG đụng OS (xem skill openkey-engine)
core/mood     ← gom câu + send-risk, dùng chung (xem skill mood-sentiment-layer)
platforms/apple/macos   ← vỏ macOS (đã làm — CGEventTap, gác cổng đầy đủ)
platforms/apple/ios     ← vỏ iOS  (chỗ này — Custom Keyboard Extension, sandbox)
platforms/apple/shared  ← code Obj-C/Swift dùng chung 2 vỏ Apple
```
iOS chỉ viết VỎ. `core/engine` + `core/mood` dùng chung 100% — KHÔNG fork logic gõ hay gom câu.

## Vì sao iOS bị chốt mandate hẹp (nhật ký + nhắc thụ động, KHÔNG gác cổng)
Keyboard extension của iOS sống trong sandbox rất chặt:
- **Không global hook.** Không có cửa nào như `CGEventTap` (macOS) để tap phím toàn cục. Extension chỉ thấy phím **khi bàn phím mình đang hiện**, trong ô nhập của host app.
- **Không thấy nút Gửi host app**, không can thiệp hành vi gửi tin của app khác → **gác cổng gửi tin (Feature #1 macOS) bất khả thi.** Đừng thiết kế lại kiểu "chặn Enter" cho iOS.
- **Chốt 2026-07-10 (chủ dự án):** iOS = **nhật ký cảm xúc + nhắc chánh niệm thụ động** (gợn sóng `~` ambient, "quan sát không phán xét"). Nhận diện "người gác cổng" giữ ở macOS/Windows. Chi tiết: `docs/FRICTION-LOG.md`, khối "Đội iOS" trong `docs/TEST_MATRIX.md`.

## Sự thật kỹ thuật cần biết trước (không giả định)
- **App Group** (`group.<bundle-id>`) là kênh DUY NHẤT chia dữ liệu giữa extension và app chính (nhật ký, cấu hình) — extension và container app không đọc thẳng file của nhau. Khai báo trong entitlements cả 2 target.
- **Full Access** (`RequestsOpenAccess = YES` trong Info.plist của extension) cần cho mạng + một số truy cập chia sẻ — nhưng là cờ đỏ riêng tư với người dùng; chỉ bật khi thật cần, giải thích minh bạch (Hiến chương: riêng tư mặc định).
- **Giới hạn bộ nhớ extension gắt** (~40–70MB tuỳ đời máy). Model on-device (PhoBERT ONNX, `docs/SEND-RISK-MODEL-SPEC.md`) có thể vượt hạn mức → **đo thật trước khi cam kết**, luôn có đường lui về lexicon heuristic. Vượt mức = iOS kill extension = bàn phím "chết".
- **UI khung bàn phím** = UIKit/SwiftUI trong `UIInputViewController`. Nhận diện con sóng `~` vẽ trong khung chật này phải trung tính — KHÔNG đèn đỏ/xanh, KHÔNG emoji chấm điểm, KHÔNG gamification.

## Quy trình khi build/port iOS
1. **Chưa mở nhánh trước khi macOS ổn định** (Hiến chương). Kiểm `platforms/apple/ios/README.md` để biết trạng thái.
2. **Scaffold qua XcodeGen, không sửa `.xcodeproj` tay.** Thêm target iOS extension + app chính vào `platforms/apple/project.yml` rồi `make generate` (`cd platforms/apple && xcodegen generate`). Đây là nguồn sự thật cấu hình project của repo con.
3. **Smoke test bộ não trước** khi đụng vỏ: `make test-core` (`tests/core/test_engine` vẫn 5/5) — xác nhận chưa đụng nhầm bộ não dùng chung.
4. **Wire bộ não vào extension:** gọi `vKeyHandleEvent()` (cửa duy nhất vào `core/engine`) từ `UIInputViewController`; nghe `vOnWordCommitted` → đẩy vào MoodBuffer (`core/mood`). Logic quyết định "đọc cảm xúc thế nào" đến từ MoodWatcher (skill `mood-sentiment-layer`); vỏ iOS chỉ lo "hiện lên khung bàn phím thế nào".
5. **Test riêng iOS** ở `tests/ios/` (`make test-ios` — hiện no-op, dựng test thật khi có code). KHÔNG đụng `tests/core/`.
6. Nghi lỗi ở bộ não dùng chung → chuyển `openkey-engine`/`engine-agent`, KHÔNG tự sửa `core/`.

## Dùng chung giữa macOS và iOS
Code Objective-C/Swift lặp giữa 2 vỏ Apple (BrandColors/nhận diện, wrapper `core/mood`, model schema) đặt ở `platforms/apple/shared/` — không copy 2 nơi. Nhưng khung bàn phím (input view) thì mỗi OS một kiểu riêng, không chia.
