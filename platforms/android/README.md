# platforms/android

Chưa có code — chỉ ghi chú lộ trình.

Theo `docs/OPENKEY-MAP.md` §Lộ trình, Android đứng thứ 3 (sau macOS, Windows): tính năng
"chặn tin nhắn nóng giận" hợp ngữ cảnh điện thoại nhất (IME tiếng Việt + gác cổng gửi tin
trong các app chat di động). Vỏ sẽ là 1 Input Method Service (Kotlin/Java hoặc NDK bridge
sang `core/engine` C++ qua JNI) — `core/engine` và `core/mood` dùng lại y nguyên, không fork
logic gõ hay logic gom câu.

Model đọc cảm xúc on-device: xem `../../models/tflite/README.md` (TensorFlow Lite là lựa chọn
tự nhiên nhất cho Android, thay vì Core ML/ONNX).
