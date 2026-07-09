# models/coreml

Chưa có model file (`.mlmodel`/`.mlpackage`). Nền tảng đích khi thay lexicon bằng model
sentiment tiếng Việt thật cho **macOS/iOS** (Core ML runtime, chạy on-device).

Trạng thái hiện tại: MVP macOS dùng lexicon thuần (`MoodWatchMac.mm` trong
`../../platforms/apple/macos/`), CHƯA có model ML nào chạy thật. Spec đầy đủ cho bước
chuyển đổi (PhoBERT → ONNX → convert sang Core ML) nằm ở `../../docs/SEND-RISK-MODEL-SPEC.md`.
