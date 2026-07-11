# 01 — Discovery Findings: Mindful Key iOS (sản phẩm đầy đủ)

> **Pha 1/4** của gói phân tích. Khung: skill `ask-why-ba` (BA Zone) — Intent Detection →
> 5 lớp BABOK → Gap Detection → thách thức Solution-Bias → Structured Summary.
> **Trạng thái:** Draft v1 · 2026-07-11 · dựa trên artifact lịch sử + 3 câu chốt với chủ dự án.
>
> ⚠️ Khác workshop discovery thường (hỏi từng lượt): ở đây chủ dự án đã cung cấp kho artifact
> dày (SPEC, tech-spec, DESIGN, EXPERIENCE, MOBILE-UX-ANALYSIS) + đã trả lời 3 câu clarify then
> chốt (tầm, cụm Laban, nơi lưu). Nên discovery này **tổng hợp + thách thức giả định** trên nền
> có sẵn, dồn phần mơ hồ vào Open Questions thay vì chặn từng bước.

---

## 0. Intent Detection

| Tín hiệu trong request | Phân loại | Ghi chú |
|---|---|---|
| "xây giống Laban 80%" | ⚠️ **Solution Bias** | "Clone Laban" là **giải pháp nêu sẵn**, không phải nhu cầu gốc — phải đào cái WHY (xem §4) |
| "kết hợp insight tiếng chuông + nhận diện cảm xúc" | **Feature Request** + **Business Objective** | Đây mới là phần *khác biệt*, là lý do sản phẩm tồn tại |
| "1 sản phẩm bài bản nhất" | **Business Objective** | Muốn nâng từ prototype → sản phẩm thật, đa chặng |
| "bóc tách input lịch sử… cái nào đã có cái nào cần hoàn thiện" | **Process/Reporting Need** | Đã xử ở `00-input-ledger.md` |

> ⚠️ **Solution Bias là ca nguy hiểm nhất.** Nếu nhận "làm giống Laban" làm yêu cầu chốt, ta dễ
> bê nguyên cả phần **game hóa** (ví xu, đếm tải, đua theme) — thứ **phạm hiến chương**. Laban là
> *một giả thuyết về hình hài UX quen thuộc*, không phải bản thiết kế để sao y.

---

## 1. Requirement Layer Check (5 lớp BABOK)

| Lớp | Trả lời câu gì | Trạng thái | Vì sao |
|---|---|---|---|
| **Business** (Why) | Vì sao làm sản phẩm này? | ✅ | Hiến chương + PRD macOS đã định vị rõ: "bộ gõ chánh niệm, gác cổng cảm xúc, riêng tư mặc định" |
| **Stakeholder** (Who) | Ai cần gì? | ✅ | Persona rõ (người Việt gõ iPhone, muốn chậm lại, không phán xét); chủ dự án = người chốt nhận diện |
| **Functional** (What) | Hệ thống phải làm gì? | 🟡 | Round 1 rõ (tech-spec); Round 2/3 (sóng cảm xúc, chuông, nhật ký) mới **phác**, nhiều ❓ |
| **Non-functional** (How well) | Tốt tới đâu? | 🟡 | Có ràng buộc cứng (RAM ~48-60MB, on-device, WCAG AA) nhưng chưa gắn từng NFR có số đo cho toàn tầm nhìn |
| **Transition** (chuyển hiện tại→tương lai) | Đi từ đâu tới đâu? | 🟡 | Đây chính là khoảng trống lớn nhất — chưa có lộ trình đa chặng. **`ROADMAP.md` (Pha 3) lấp chỗ này** |

**Nhận định:** request nhảy thẳng vào **Functional** ("xây giống Laban") mà bỏ qua việc nối lại
với **Business** (vì sao) và **Transition** (đi mấy chặng). Discovery này kéo về đúng thứ tự.

---

## 2. Gap Detection (Known / Unknown)

**Known (đã chắc):**
- Định vị sản phẩm + nhận diện (hiến chương, DESIGN.md đã verify contrast thật).
- `core/engine` chạy được trên iOS, 0 thay đổi (thực nghiệm compile).
- 3 điểm mạnh Laban đáng kế thừa (onboarding kích hoạt, preview sống, slider trực tiếp).
- Feature #1 (gác cổng) **không** port thẳng lên iOS — chốt "chỉ nhắc thụ động".
- 3 cụm Laban trong phạm vi (bàn phím lõi, cài đặt+kiểu gõ, theme trung tính).

**Unknown (còn mờ — đẩy xuống Open Questions):**
- Map `send-risk 0..1` → biên độ sóng cụ thể (đường cong nào, ngưỡng "mặt hồ phẳng").
- "Tiếng chuông chánh niệm" trên iOS là gì chính xác: âm khi gõ (preset Âm) hay chuông định kỳ nhắc nghỉ?
- Nhật ký iOS hiện gì (ranh giới "đủ tự nhận ra" vs "thành dashboard").
- Bundle ID / App Group tên thật.
- Mockup 2 màn onboarding (chưa tồn tại file).
- Model sentiment: giữ lexicon hay tiến tới PhoBERT ONNX (trần RAM extension là ràng buộc gắt).

---

## 3. Business Problem & Goal

### 3.1 Business Problem
Người Việt gõ tiếng Việt trên iPhone hằng ngày (nhắn tin, mạng xã hội) **không có** bàn phím nào
vừa (a) gõ Telex/VNI quen tay như Laban, vừa (b) tạo **một khoảng lặng chánh niệm** — nhắc người
ta *tự nhận ra* trạng thái cảm xúc khi gõ, mà **không phán xét, không theo dõi, không game hóa**.
Laban giải (a) rất tốt nhưng hoàn toàn không có (b); các bàn phím mindfulness phương Tây không
hiểu tiếng Việt. mindful-keyboard đã chứng minh (b) trên macOS nhưng iOS mới ở walking skeleton.

### 3.2 Business Goal (định tính — cố ý KHÔNG đặt KPI kiểu tăng trưởng)
Đưa iOS từ *prototype chứng minh engine* → **một bàn phím tiếng Việt hoàn chỉnh** mà người dùng
dám đặt làm bàn phím mặc định, trong đó **lớp chánh niệm (sóng `~` + chuông) là bản sắc**, không
phải tính năng phụ. "Thành công" = người dùng gõ mượt như Laban **và** thỉnh thoảng dừng lại một
nhịp vì con sóng — mà không hề cảm thấy bị chấm điểm.

> ⚠️ Cố ý **không** đặt mục tiêu kiểu "tăng X% retention" — đó là tư duy gamification/growth mà
> hiến chương tránh. Thước đo là *chất lượng trải nghiệm*, không phải *chỉ số giữ chân*.

---

## 4. Thách thức Solution-Bias: "clone Laban 80%" thật ra là gì?

Đào cái WHY sau "giống Laban":

| Cái người dùng NÓI | Cái thật sự CẦN (root) | Hệ quả thiết kế |
|---|---|---|
| "Giống Laban" | Bàn phím **quen tay, đáng tin, không phải học lại** | Kế thừa *mẫu tương tác* Laban (layout, segmented, slider, preview sống) |
| "Cửa hàng theme" | Được **cá nhân hóa cho thấy 'của mình'** | Giữ cơ chế theme, **bỏ** ví xu/đếm tải/đua cộng đồng (game hóa) |
| "Nhiều tính năng" | **Không thua kém** bàn phím thương mại | Đủ lõi (Telex/VNI, sửa lỗi, gợi ý từ) — nhưng vuốt phím/macro để round sau |
| (ngầm) | Một sản phẩm **có hồn riêng**, không phải Laban nhái | Lớp chánh niệm (sóng/chuông/nhật ký) là thứ Laban KHÔNG có → đó mới là 80%→100% |

**Kết luận thách thức:** "80% Laban" đúng nghĩa = **80% sự quen thuộc về công cụ gõ**, còn 20%
còn lại (và là *linh hồn*) là lớp chánh niệm mà Laban không có. Không phải "sao chép 80% màn hình
Laban". Phần game hóa của Laban **không** nằm trong 80% đó.

---

## 5. Laban qua lăng kính hiến chương (giữ / đổi / bỏ) — 3 cụm trong phạm vi

| Yếu tố Laban | Quyết định | Cắm insight chánh niệm vào đâu |
|---|---|---|
| Onboarding kích hoạt (số bước + coach-mark 🌐 + fallback web) | ✅ **Kế thừa nguyên** | Thêm 1 màn "vì sao Full Access" cho con sóng (đã có ở EXPERIENCE Màn 02) |
| Preview bàn phím sống + slider trực tiếp | ✅ **Kế thừa nguyên** | Preview cũng để thử tông theme trung tính |
| Layout bàn phím, Telex/VNI, sửa lỗi, gợi ý từ | ✅ **Kế thừa** (engine C++ dùng chung) | **Thanh gợi ý = "đất" đặt con sóng `~`** (khe tự nhiên nhất) |
| Cửa hàng theme + ví xu + đếm tải + rating | ❌ **BỎ phần game hóa** | Theme chỉ còn cá nhân hóa tông trung tính |
| Theme màu bão hòa (BTS neon, Halloween) | ⚠️ **Đổi palette** về tông NOW BRAND trung tính | — |
| Ghi chú tô xanh/vàng, mặt cười onboarding | ❌ **Bỏ** (mã màu + emoji chấm điểm phạm 2.2) | Màn "Quản lý ghi chú" của Laban → khung tái dùng cho **nhật ký tâm trạng** (Round 3), nhưng bỏ mã màu |
| **Preset "Âm" khi gõ** (Water_Drop, Wood, Tock…) | ✅ Kế thừa cơ chế | **Khe tự nhiên cho "tiếng chuông chánh niệm"** — thêm 1 preset âm, không phá gì |

> **2 khe vàng cho insight (từ MOBILE-UX-ANALYSIS §3.2 + teardown Laban):**
> 1. **Thanh gợi ý trên bàn phím** → con sóng `~` biến hình theo biên độ (Phương án A — "gợn sóng
>    nhắc", ambient, không chặn). Đây là biểu hiện iOS của Feature #1.
> 2. **Preset Âm + màn Hiệu ứng&Âm thanh** → tiếng chuông chánh niệm như một âm tùy chọn.

---

## 6. Edge Cases đã quét (failure modes)

- **Ô mật khẩu (secure field):** tuyệt đối không đọc/log/hiện sóng — kể cả Round 2 (riêng tư mặc định).
- **Chưa Full Access:** gõ vẫn chạy (insert/delete không cần quyền); chỉ sóng (Round 2) mới cần → không chặn.
- **Extension bị iOS kill vì RAM:** rủi ro kỹ thuật thật, không phải UX — bàn phím "chết" giữa chừng. Giảm bằng UI nhẹ + macro rỗng mặc định + đo Instruments sớm.
- **Bật rồi tắt lại bàn phím:** iOS không cho app biết → heartbeat chỉ đoán "đã từng chạy", chấp nhận, không khẳng định sai.
- **Model sentiment sai (báo động giả):** sóng gợn khi câu thật ra bình thường → phải "quan sát nhẹ", không kết luận; sai số không gây hại vì *không chặn*, chỉ nhắc.
- **Deep link Cài đặt hỏng (iOS đổi scheme):** fallback hướng dẫn tĩnh, không tô đỏ, không chữ "Lỗi".

---

## 7. Assumptions (giả định — cần validate trước khi thi công sâu)

- **A1:** iOS 16.0 làm sàn tối thiểu (khớp SDK đã thực nghiệm) — chưa xác nhận có hạ để đỡ máy cũ.
- **A2:** Bundle ID `vn.gnh.mindfulkey.ios*` + App Group `group.vn.gnh.mindfulkey` — mới là đề xuất.
- **A3:** Round đầu vẫn ký ad-hoc/simulator, chưa cần Apple Developer Program.
- **A4:** "Tiếng chuông" hiểu theo 2 nghĩa cùng lúc: (a) preset âm khi gõ, (b) chuông nhắc nghỉ định kỳ (như `BellMac` macOS). Cần chủ dự án chốt nghĩa nào là chính cho iOS.
- **A5:** Model sentiment Round 2 dùng **lexicon on-device** trước (nhẹ RAM), PhoBERT ONNX để sau nếu trần RAM cho phép.
- **A6:** Vuốt phím + gõ tắt (macro) **ngoài** phạm vi đợt này (chủ dự án không chọn) → xếp Round sau.

## 8. Dependencies
- `core/engine` (đóng băng, tiêu thụ qua API) + `core/mood` (`MoodBuffer`, `BreathingPause` — có sẵn hợp đồng C++).
- `platforms/apple/shared/` dùng chung với đội macOS → mọi thay đổi cần review chéo, chạy `make build` macOS.
- DESIGN.md (token + WCAG đã verify) — nguồn thị giác chuẩn.

---

## 9. Open Questions (chặn move-to-design cho Round 2/3 — gom vào decision queue Pha 4)

| # | Câu hỏi | Chủ | Chạm |
|---|---|---|---|
| Q1 | Map `send-risk 0..1` → biên độ sóng: đường cong nào? ngưỡng "mặt hồ phẳng" ở đâu? | Chủ dự án | Nhận diện |
| Q2 | Có kèm **câu quan sát** ("Mặt hồ đang gợn sóng") cùng sóng không? hiện/ẩn khi nào? | Chủ dự án | Nhận diện |
| Q3 | "Tiếng chuông" = preset âm khi gõ, hay chuông nhắc nghỉ định kỳ, hay cả hai? (A4) | Chủ dự án | Sản phẩm |
| Q4 | Nhật ký iOS hiện **chính xác** gì? ("đủ tự nhận ra" vs "dashboard") | Chủ dự án | Nhận diện + riêng tư |
| Q5 | Nút "Xoá tất cả" nhật ký đặt đâu, xác nhận 2 bước thế nào (không nút đỏ mặc định)? | Chủ dự án | Nhận diện + riêng tư |
| Q6 | Soi lại cuối ngày = 1 màn, 1 push notification, hay cả hai? (notification chạm "nhắc chủ động") | Chủ dự án | Nhận diện |
| Q7 | Bundle ID + App Group tên thật? (A2) | Chủ dự án | Kỹ thuật |
| Q8 | Mockup 2 màn onboarding: cung cấp file thật hay để dev dựng theo mô tả FR-003? | Chủ dự án | Thiết kế |
| Q9 | Sync cloud: cho sync theme không? (nhật ký cảm xúc **tuyệt đối không rời máy**) | Chủ dự án | Riêng tư |
| Q10 | Giọng copy 3 màn onboarding + glyph sóng chính thức + wordmark/logo? | Chủ dự án | Nhận diện |
| Q11 | Model sentiment: lexicon trước rồi PhoBERT sau, có đúng ý? (A5) | Chủ dự án | Kỹ thuật |

---

## Next Steps
- [x] Sổ cái input (`00-input-ledger.md`) — đã có.
- [ ] Chuyển discovery → requirements truy vết (`problem-based-srs` Step 0→5, file 02→08).
- [ ] Đưa toàn bộ Open Questions Q1–Q11 vào decision queue `09-bmad-reconcile.md`.

---
*Pha 1/4 — Discovery. Khung ask-why-ba (Thế Minh, BA Zone). Kế tiếp: `02-business-context.md`.*
