# Bản đồ OpenKey — soi code để dựng "bộ gõ chánh niệm"

> Mục tiêu: fork OpenKey (GPL v3) làm bộ gõ tiếng Việt, đắp thêm lớp "đọc cảm xúc + nhắc tâm".
> Repo gốc: https://github.com/tuyenvm/OpenKey — clone tại `/root/projects/mindful-keyboard/OpenKey` (WSL ext4).
> Ngày soi: 2026-06-18.

---

## 1. Kiến trúc: 1 BỘ NÃO + 3 (sắp tới 4-5) CÁI VỎ

```
Sources/OpenKey/
├── engine/          ← BỘ NÃO dùng chung (C++ thuần, ~3.260 dòng) — KHÔNG đụng OS
│   ├── Engine.cpp        (1558 dòng) — vòng đời xử lý phím, buffer từ đang gõ
│   ├── Vietnamese.cpp    (576)  — luật bỏ dấu, ghép vần tiếng Việt
│   ├── Macro.cpp         (293)  — gõ tắt (btw -> by the way)
│   ├── SmartSwitchKey.cpp (73)  — tự đổi Việt/Anh theo app
│   ├── ConvertTool.cpp   (180)  — đổi bảng mã Unicode/VNI/TCVN3
│   └── DataType.h         (156) — định nghĩa struct trả kết quả (vKeyHookState)
│
├── win32/   ← VỎ Windows  (C++ Win32, low-level keyboard hook)
├── macOS/   ← VỎ macOS    (Objective-C, CGEventTap + Accessibility)
└── linux/   ← VỎ Linux
```

**Ý nghĩa:** muốn lên Android/iOS chỉ cần viết thêm 2 cái VỎ mới, **giữ nguyên bộ não**. Đây đúng mô hình "1 bộ não + nhiều vỏ" — fork là tận dụng được ngay phần khó nhất.

---

## 2. Dòng chảy của 1 phím (lấy Windows làm ví dụ)

```
[Người gõ phím]
   │
   ▼
keyboardHookProcess()          ← VỎ Win bắt phím ở tầng hệ điều hành (OpenKey.cpp:583)
   │  gọi
   ▼
vKeyHandleEvent(event,state,keycode,...)   ← cửa DUY NHẤT vào BỘ NÃO (Engine.h)
   │  bộ não cập nhật:
   │    TypingWord[]  = mảng phím của TỪ đang gõ
   │    _index        = độ dài từ hiện tại
   │  rồi điền kết quả vào struct pData (vKeyHookState):
   │    backspaceCount = xóa lùi mấy ký tự
   │    charData[]     = ký tự mới cần gõ ra
   ▼
VỎ đọc pData → SendBackspace() N lần → gõ chữ mới ra app
   (Win: dán qua clipboard + Shift+Insert; hoặc SendKeyCode từng phím)
```

**Word boundary (hết 1 từ):** khi gõ dấu cách / dấu câu / Enter / đổi app, bộ não trả cờ `vBreakWord` hoặc vỏ gọi `startNewSession()` → `_index = 0` (bắt đầu từ mới). Các điểm gọi `startNewSession()`:
- Engine.cpp: 1360, 1459, 1476
- win32/OpenKey.cpp: 368, 413, 639, 690
- macOS/OpenKey.mm: 214, 493, 541, 783

> Đây là cái mạch quan trọng nhất: **bộ não làm việc theo TỪNG TỪ**, và nó biết chính xác khoảnh khắc "một từ vừa xong".

---

## 3. ⭐ CHỖ CẮM lớp cảm xúc (cái cần nhất)

Vì bộ não biết "một từ vừa xong", ta chỉ cần **nghe lén dòng từ hoàn chỉnh đó**, gom lại thành câu, rồi đưa cho AI đọc cảm xúc. Thiết kế tối thiểu, ít đụng code gốc:

### 3.1. Sửa BỘ NÃO — chỉ thêm 1 cái móc (~10-15 dòng)
Thêm 1 con trỏ hàm callback, bắn ra mỗi khi 1 từ hoàn chỉnh:
```cpp
// trong Engine.h
extern void (*vOnWordCommitted)(const wstring& word);   // mặc định = nullptr
```
Gọi nó tại các điểm word-boundary (ngay trước/sau `startNewSession`), dùng sẵn
`getCharacterCode()` + `wideStringToUtf8()` để đổi keycode → chữ Unicode thật.
→ Bộ não vẫn thuần, không biết gì về cảm xúc, không kéo theo ML/mạng. **Đây là thay đổi DUY NHẤT vào phần dùng chung.**

### 3.2. Module MỚI dùng chung — `MoodBuffer` (C++, ~100 dòng)
- Đăng ký nhận callback ở trên.
- Gom từng từ thành "câu gần đây" (rolling buffer ~1-2 câu / ~200 ký tự).
- Khi gặp dấu kết câu (`. ! ?` / Enter) → bắn sự kiện `onSentenceComplete(sentence)`.
- Chạy được trên MỌI nền tảng (thuần C++).

### 3.3. Module MỚI theo từng OS — `MoodWatcher` (tầng vỏ)
Đây là chỗ KHÁC nhau giữa Win/Mac/Android/iOS:
- Chạy model đọc cảm xúc **trên máy** (Windows: ONNX Runtime/DirectML; Mac: Core ML; mobile sau).
- Nếu câu tiêu cực vượt ngưỡng → hiện popup native nhẹ ("câu này nghe đang giận, gửi không?").
- Ghi sự kiện cảm xúc vào SQLite local → đồng bộ cloud (cho biểu đồ cuối ngày).

### 3.4. App chính (đã có sẵn khung)
OpenKey đã có UI khay hệ thống: Win = `MainControlDialog` + `SystemTrayHelper`; Mac = `ModernKey`.
→ Đắp thêm màn: chuông tỉnh thức (scheduler), hỏi tâm trạng, biểu đồ cảm xúc cuối ngày, gợi ý hồi phục.
Mấy thứ này KHÔNG đụng bộ gõ, sống độc lập trong app chính.

```
BỘ NÃO (callback 1 từ)  →  MoodBuffer (gom câu, chung)  →  MoodWatcher (AI+popup, theo OS)
                                                                  │
                                                                  ▼
                                                       SQLite local → Cloud sync
                                                                  │
                                                       App chính: chuông, thống kê, gợi ý
```

---

## 4. Cảnh báo / điểm phải biết trước

1. **Điểm mù:** bộ não chỉ thấy chữ khi OpenKey đang BẬT + ở chế độ tiếng Việt. Chế độ Anh, ô mật khẩu, app tắt bộ gõ = không thấy. Với việc bắt "lúc cáu" thì phần lớn ổn (người Việt cáu thường gõ tiếng Việt), nhưng phải biết đây là vùng không phủ.
2. **Privacy:** gom "từ hoàn chỉnh" = đang giữ thứ người dùng gõ trong bộ nhớ. Bắt buộc xử lý **on-device**, DB local mã hóa, xin phép rõ. Dù mã nguồn mở, người dùng vẫn rất nhạy chuyện này (bộ gõ = thứ thấy mọi phím bấm).
3. **Không được làm chậm gõ:** AI đọc cảm xúc phải chạy bất đồng bộ + chỉ ở cuối câu (debounce), TUYỆT ĐỐI không chen vào mạch gõ phím, kẻo gõ bị khựng → người dùng gỡ ngay.
4. **Cách Win gõ chữ ra hơi "hack":** nó dán qua clipboard + Shift+Insert → có thể đè clipboard người dùng (lỗi cố hữu của OpenKey). Không ảnh hưởng lớp cảm xúc, nhưng nên biết vỏ Win vốn chắp vá.
5. **"PC/Mac" là 2 vỏ riêng:** Win (Win32 C++) và Mac (Objective-C) viết tách. Chỉ bộ não + MoodBuffer dùng chung.

---

## 5. Bước tiếp theo đề xuất

1. Build thử OpenKey gốc trên Windows cho chạy được (xác nhận môi trường) — theo `win32/README.md`.
2. Cắm cái callback `vOnWordCommitted` + `MoodBuffer`, in câu ra log để kiểm chứng "nghe" đúng.
3. Ghép 1 model sentiment tiếng Việt nhỏ (ONNX) → bật popup demo.
4. Khi 3 cái trên chạy → mới `/plan` chi tiết cho bản Windows MVP.
