# 09 — Nối vào BMAD + Decision Queue

> **Pha 4/4.** Chỉ rõ gói phân tích này khớp luồng BMAD hiện tại thế nào, gom mọi câu hỏi treo
> để chủ dự án chốt 1 lượt, và liệt kê follow-up dọn doc-drift. **2026-07-11.**

---

## 1. Gói phân tích này quan hệ với BMAD ra sao

- **Không thay thế, mà mở rộng.** Workspace iOS là **Quick Flow** (1 tech-spec cho Round 1).
  Gói `analysis/` này cung cấp **tầm nhìn đa chặng** (17 FR, 4 round) mà một tech-spec Round 1
  cố ý không phủ. Nó là *lớp phân tích sâu*, nối vào chứ không đá nhau.
- **tech-spec.md = lát Round 1** của tầm nhìn. Ma trận map (`08` §4): tech-spec phủ 5/17 FR
  (FR-001..005 ↔ FR-A03/A01/A04-05/A06/A17). 12 FR còn lại là R2+.
- **Một nguồn sự thật:** khi có mâu thuẫn, `00-input-ledger.md` (đối chiếu code thật) thắng tài liệu.

## 2. Bước kế tiếp đề xuất (theo Quick Flow, KHÔNG tự chạy)

1. **Chủ dự án duyệt** SPEC/tech-spec/DESIGN/EXPERIENCE (đang "draft chờ duyệt") + gói `analysis/` này.
2. **Chốt decision queue §3** (đặc biệt Q7, Q8 để mở khóa hoàn tất R1).
3. **Hoàn tất Round 1** theo `tech-spec.md` §Story List (Mốc B là việc lõi) — dev trực tiếp, 1 luồng.
4. Khi mở **Round 2**: chạy `bmad-tech-spec` (Update) hoặc mở tech-spec R2 mới bám `ROADMAP.md` R2 +
   FR-A08/A09/A10; nếu scope R2 phình > 15 story → cân nhắc đổi track **bmad-method** (bmad-prd + bmad-architecture).
5. Khi cần chẻ việc song song: `bmad-epics-and-stories` sinh `stories/` từ FR đã chốt (hiện `stories/` trống).

> ⛔ Ranh giới giữ nguyên theo chỉ đạo cũ: **không** tự chạy `bmad-epics-and-stories`/`bmad-parallel-plan`
> ở bước phân tích này. Đây là tài liệu phân tích, không phải lệnh khởi công.

## 3. DECISION QUEUE — chủ dự án chốt 1 lượt

> Gom từ Discovery Q1–Q11 (`01`) + EXPERIENCE Future B1/B2/B3 + Dev Handoff + MOBILE-UX §5 +
> tech-spec Assumptions/Risks. Cột "Chặn" = round nào không khởi công được nếu chưa chốt.

### Nhóm A — Mở khóa hoàn tất Round 1 — ✅ ĐÃ CHỐT 2026-07-11 (xem decision-log)
| # | Câu hỏi | Trả lời |
|---|---|---|
| Q7 ✅ | Bundle ID + App Group | DÙNG bản đề xuất: `vn.gnh.mindfulkey.ios` / `.keyboard` / group `group.vn.gnh.mindfulkey` |
| Q8 ✅ | Mockup 2 màn onboarding | Không cần file — dev dựng theo `EXPERIENCE.md` (v0.3) |
| Q10a ✅ | Sàn iOS tối thiểu | GIỮ 16.0 |

### Nhóm B — Chạm NHẬN DIỆN, chốt trước Round 2 (hiến chương bắt buộc hỏi)
| # | Câu hỏi | Chặn | Nguồn |
|---|---|---|---|
| Q1 | Map `send-risk 0..1` → biên độ sóng: đường cong nào? ngưỡng "mặt hồ phẳng" ở đâu? | R2 (FR-A08) | EXPERIENCE B1 |
| Q2 | Có kèm câu quan sát ("Mặt hồ đang gợn sóng") không? hiện/ẩn khi nào? | R2 (FR-A08) | EXPERIENCE B1 |
| Q3 | "Tiếng chuông" = preset âm khi gõ, chuông nhắc nghỉ định kỳ, hay cả hai? | R2 (FR-A10) | Discovery A4 |
| Q10b | Giọng copy onboarding + glyph sóng chính thức + wordmark/logo? | R2 (nhận diện) | EXPERIENCE Dev Handoff |
| Q11 | Model sentiment: lexicon trước rồi PhoBERT ONNX sau — đúng ý? | R2 (FR-A09, RAM) | Discovery A5 |

### Nhóm C — Chạm NHẬN DIỆN + RIÊNG TƯ, chốt trước Round 3
| # | Câu hỏi | Chặn | Nguồn |
|---|---|---|---|
| Q4 | Nhật ký iOS hiện **chính xác** gì? (ranh giới "đủ tự nhận ra" vs "dashboard") | R3 (FR-A13) | EXPERIENCE B2 |
| Q5 | Nút "Xóa tất cả" đặt đâu, xác nhận 2 bước thế nào (không nút đỏ mặc định)? | R3 (FR-A13) | EXPERIENCE B2 |
| Q5b | App Group nhật ký: extension ghi / container đọc (hay ngược lại)? ai sở hữu file mã hóa? | R3 (FR-A13, kiến trúc) | EXPERIENCE B2 ❓3 |
| Q6 | Soi lại cuối ngày = 1 màn, 1 push notification, hay cả hai? | R3 (FR-A14) | EXPERIENCE B3 |
| Q9 | Sync cloud: cho sync theme không? (nhật ký cảm xúc tuyệt đối không rời máy) | R3/R4 (FR-A16) | MOBILE-UX §5 |

### Nhóm D — Đã có khuyến nghị, chỉ cần xác nhận
| # | Câu hỏi | Khuyến nghị |
|---|---|---|
| D1 | iOS chỉ "nhắc" (Phương án A) trong khi macOS/Android "chặn" — chấp nhận không đồng đều? | **Có** — chánh niệm là *tự nhận ra*, không *bị chặn*; iOS "nhắc" đúng tinh thần hơn (MOBILE-UX §3.6) |
| D2 | Nút "Để sau" ở Full Access: giữ hay bỏ? | **Giữ** — đúng riêng-tư-mặc-định (EXPERIENCE) |
| D3 | Vuốt phím + macro: xác nhận để Round 4 (ngoài đợt này)? | **Đồng ý hoãn** (chủ dự án đã không chọn) |

## 4. Follow-up dọn doc-drift — ✅ ĐÃ LÀM 2026-07-11 (sau khi chủ dự án duyệt)

| # | File | Sửa gì |
|---|---|---|
| DD1 ✅ | `platforms/apple/ios/README.md` | Đã đổi "Chưa mở code" → "Round 1 Mốc A đã committed" + nêu Mốc B chưa làm |
| DD2 ✅ | `platforms/apple/shared/README.md` | Đã đổi "Chưa mở" → liệt kê EngineDefaults/EngineKeyMap/BrandPalette đã rút |
| DD3 ✅ | `tech-spec.md` §Key Components | Đã thêm ghi chú 2026-07-11: target iOS đã có trong project.yml, còn verify `xcodegen generate` |
| DD4 ✅ | `bmad-output/ios/README.md` | Đã cập nhật: workspace Quick Flow + liệt kê artifact + thư mục `analysis/` |

> Đã sửa 2026-07-11 (chỉ doc, không đụng code). Nên gom 1 commit "docs: sync iOS READMEs + tech-spec với code thật".

## 5. Trạng thái các artifact liên quan (nhắc)
| Artifact | Trạng thái |
|---|---|
| SPEC.md, tech-spec.md, DESIGN.md, EXPERIENCE.md | draft — **chờ chủ dự án duyệt** |
| `analysis/00`→`09` + ROADMAP | mới tạo — chờ chủ dự án đọc/duyệt |
| `stories/` | trống (cố ý — chưa sharding) |

## 6. Bản đồ bắc cầu F↔Module + doc-sync 2026-07-11 (audit đồng bộ 3 nguồn)

Sau khi soi chéo khung L (Laban) · gói `analysis/` · specs (`EXPERIENCE.md`/`DESIGN.md`): **không có
xung đột nền tảng** — cả ba nhất trí phần hồn (sóng theo biên độ, không màu valence, không gamify,
soi lại lấy câu hỏi làm chính, iOS chỉ nhắc không chặn). Vá xong các drift cơ học; còn 1 quyết định
thật (tiering "gõ tắt") để chủ dự án chốt.

**Vì sao đọc thấy "lệch":** gói `analysis/` mô tả sản phẩm bằng **8 chủ đề F1–F8** (lăng kính yêu
cầu), còn specs mô tả bằng **6 module + 3 bề mặt** (lăng kính màn hình/điều hướng). Hai bản đồ CÙNG
một vùng đất, trước nay THIẾU bảng bắc cầu. Bổ sung tại đây (nguồn chân lý UX = specs; `analysis/`
trỏ về specs):

| Chủ đề F (analysis) | Module (EXPERIENCE) | Ghi chú |
|---|---|---|
| F1 · Lõi gõ | M2 Bàn phím + M5 (Cài đặt bàn phím: kiểu gõ) | Mốc B đã làm phần lõi |
| F2 · Onboarding & quyền | M1 Vào cửa | story #5 |
| F3 · Riêng tư | M2 (ô mật khẩu) + xuyên suốt (copy Full Access ở M1) | không phải 1 màn riêng |
| F4 · Sóng cảm xúc | **M4 Lớp cảm xúc** + M2 trạng thái (b) | Round 2, chờ Q1/Q2 |
| F5 · Tiếng chuông | M4 + M5 (Âm & rung + Chuông) | Round 2, chờ Q3 |
| F6 · Cá nhân hóa | M3 Ngôi nhà + M5 Cài đặt chi tiết + **M6 Nền cá nhân** | preview sống + theme + nền |
| F7 · Nhật ký & soi lại | M4 (tab Mặt hồ: nhật ký + soi lại) | Round 3, chờ Q4–Q6 |
| F8 · Nâng cao | (chưa có module riêng — vuốt/macro/sync nằm dưới M5 khi tới R4) | xem tiering "gõ tắt" |

**3 tính năng "mồ côi" (có trong specs, CHƯA có FR-A tương ứng — cần chính thức hoá khi tới round):**
- **Nền cá nhân** (M6: chọn nền + ảnh + slider làm mờ) — gần `FR-A12` (theme màu) nhưng KHÁC (nền/ảnh).
  Cần FR riêng khi vào Round 3.
- **Lớp nhịp thở** (M2 thẻ mời thở + M4 full-screen mức Cuộn) — hiện chỉ là hộp `core/mood`
  BreathingPause trong sơ đồ kiến trúc, chưa thành FR-A người-dùng. Cần FR khi vào Round 2.
- **Màn Giới thiệu (credit GPL / Mai Vũ Tuyên)** (M5) — nghĩa vụ pháp lý, chưa có FR. Cần FR khi vào
  Round 1–2 (làm cùng cụm Cài đặt).

**⚠️ 1 MÂU THUẪN THẬT — chờ chủ dự án chốt (chưa sửa):** tiering "gõ tắt" (macro chữ). EXPERIENCE để
ở **M5, Round 1–2**; `analysis` (F8/`FR-A15`) gộp với "vuốt phím" đẩy xuống **Round 4/Won't**. Cùng 1
tính năng, 2 đầu lộ trình. Đề xuất soi: tách macro-chữ (engine đã có `Macro.cpp`, rẻ) về R2, để riêng
vuốt-phím (khó) ở R4.

## 7. Drift cơ học đã vá 2026-07-11 (audit đồng bộ)

| # | File | Sửa gì |
|---|---|---|
| S1 ✅ | `DESIGN.md` §2.1, §2.4 | `radius.control` 12pt → **8pt** (sót của lần reconcile trước, lệch `tokens.json`) |
| S2 ✅ | `DESIGN.md` §2.12 | Tab "Mặt hồ" round-tier: Round 3 → **Round 2–3** (khớp EXPERIENCE) |
| S3 ✅ | `EXPERIENCE.md` §6 module | Thêm cảnh báo "L (lô thiết kế) ≠ mức sóng cảm xúc 1–5" |
| S4 ✅ | `ROADMAP.md` | Cập nhật Mốc B XONG: FR-A01/A17 ✅, R1 ~30%→~55% |
| S5 ✅ | `09` §6 (file này) | Thêm bảng bắc cầu F↔Module + ghi chú 3 FR mồ côi |

---
*Pha 4/4 xong. Gói phân tích `bmad-output/ios/analysis/` hoàn tất. Audit đồng bộ 2026-07-11: specs =
nguồn chân lý UX, analysis trỏ về specs, khung L = giàn giáo quy trình trực giao. Còn 1 quyết định mở:
tiering "gõ tắt".*
