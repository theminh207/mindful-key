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

---
*Pha 4/4 xong. Gói phân tích `bmad-output/ios/analysis/` hoàn tất — chờ chủ dự án duyệt + chốt decision queue.*
