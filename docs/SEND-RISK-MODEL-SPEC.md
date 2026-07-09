# Spec: thay lexicon bằng PhoBERT ONNX cho send-risk (chưa implement)

> Trạng thái: **SPEC — chưa code.** MVP macOS ship với lexicon (`prototype/mood_demo.cpp`,
> `MoodWatchMac.mm`). Tài liệu này định nghĩa cách thay thế sau, không phải việc cần làm ngay.

## 1. Hợp đồng phải giữ nguyên

```
onSentenceComplete(sentence: wstring) -> risk: double  // [0.0, 1.0]
```

Hiện `risk` được tính bởi `analyzeSendRisk()`/`analyzeRecentTextAsync()` (lexicon có trọng số
theo category: giận=1.0, buồn/mệt/lo=0.35, +=0.6, bão hòa qua `1 - e^(-raw/5)`). Khi thay bằng
model, **chỉ thay phần bên trong hàm này** — không đổi chữ ký, không đổi đơn vị (vẫn `[0,1]`,
vẫn "hại tới đâu nếu gửi", không phải phân loại nhiều cảm xúc). Mọi thứ downstream (hợp đồng
"nhịp thở" ở bước 3, gác cổng gửi tin ở bước 5, kho dữ liệu ở bước 6) chỉ cần con số này, không
quan tâm nó tính bằng lexicon hay model.

## 2. Model đề xuất

- **PhoBERT-base** (hoặc `PhoBERT-base-v2`), fine-tune như bài toán regression/binary trên nhãn
  "harmful-if-sent" (không phải multi-class cảm xúc) — khớp đúng bài toán đã thu hẹp ở bước 2.
- Export sang **ONNX** (`torch.onnx.export` hoặc qua `optimum`), quantize INT8 nếu cần giảm kích
  thước/độ trễ cho on-device.
- Runtime: **ONNX Runtime** build universal (arm64 + x86_64) cho macOS; cân nhắc **Core ML
  Execution Provider** để tận dụng Apple Silicon, fallback CPU EP nếu không khả dụng.

## 3. Ràng buộc độ trễ & luồng chạy

- Bắt buộc chạy **ngoài** CGEventTap thread — đã có sẵn `g_moodQueue` (serial dispatch queue)
  trong `MoodWatchMac.mm`, model inference cắm vào đúng chỗ này, không đổi kiến trúc threading.
- Đặt **timeout cứng** (đề xuất 150ms) cho 1 lần inference. Vượt timeout → coi như model "trượt"
  cho câu đó, rơi về lexicon ngay lập tức cho câu đó — KHÔNG chờ, không làm khựng luồng gõ.
- Câu tiếng Việt ngắn (đúng độ dài `MoodBuffer` gom, ~15 từ) trên PhoBERT-base + ONNX Runtime
  trên Apple Silicon thường nằm dưới mốc này, nhưng phải đo thật trên máy đích trước khi bật mặc định.

## 4. Fallback bắt buộc

Nguyên tắc đã có trong `.claude/agents/mood-layer-agent.md`: model lỗi/không tải được → rơi về
lexicon heuristic, ghi log việc rơi về (Console.app, không hiện cho user), tuyệt đối không crash
hoặc chặn luồng gõ. Áp dụng y hệt khi thêm model: nếu file `.onnx` thiếu, load lỗi, hoặc
inference lỗi/timeout → gọi thẳng `analyzeSendRisk()`/`analyzeRecentTextAsync()` hiện tại như
plan B, không có nhánh thứ 3.

## 5. Dữ liệu huấn luyện — vấn đề chưa có lời giải, nêu rõ thay vì giả định

Repo **chưa có** dataset "harmful-if-sent" tiếng Việt nào. Không được dùng câu gõ thật của người
dùng để train (vi phạm nguyên tắc 100% on-device / không bao giờ lưu văn bản gốc trong
`docs/PRD.md`). Hướng đề xuất khi tới lúc làm:
1. Bootstrap nhãn yếu (weak label) bằng chính lexicon + danh sách profanity hiện có làm nhãn tự động trên corpus tiếng Việt công khai (báo, mạng xã hội public, bình luận công khai đã ẩn danh).
2. Tập validation nhỏ gán nhãn tay (vài trăm câu) để đo chính xác thật, không chỉ tin nhãn yếu.
3. Không thu thập/qua tay dữ liệu người dùng thật của Mindful Keyboard dưới bất kỳ hình thức nào.

## 6. Checklist khi thực sự làm bước này (fast-follow sau MVP)

- [ ] Có dataset huấn luyện + validation tuân thủ mục 5.
- [ ] Fine-tune PhoBERT, export ONNX, đo độ chính xác so với lexicon baseline trên tập validation.
- [ ] Đo latency thật trên máy Apple Silicon lẫn Intel (nếu còn hỗ trợ) với ONNX Runtime.
- [ ] Cắm timeout + fallback (mục 3–4) trước khi bật mặc định cho bất kỳ ai.
- [ ] A/B so sánh lexicon vs model trên vài chục câu thật (do chính dev tự gõ, không phải dữ liệu người dùng) trước khi thay hẳn.
- [ ] Cập nhật `.claude/skills/mood-sentiment-layer/SKILL.md` sau khi model thay thế lexicon thành công.
