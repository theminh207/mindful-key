# 08 — Traceability Matrix (CP → CN → FR) + Zigzag Validation

> **Pha 2/4 · problem-based-srs.** Chuỗi truy vết đầy đủ + validate ZigZag (BẮT BUỘC sau Step 5).
> Mục tiêu: **không FR mồ côi**, **không CP không được phục vụ**. **2026-07-11.**

---

## 1. Ma trận CP → CN → FR

| CP (WHY) | CN (WHAT) | FR (HOW) | Nhóm | BMAD map |
|---|---|---|---|---|
| CP-01 Gõ Việt quen tay | CN-01 | FR-A01 | F1 | ⊃ FR-002 |
| CP-01 | CN-02 | FR-A02 | F1 | mới |
| (nền F1 build) | — | FR-A03 | F1 | = FR-001 |
| CP-01 (verify) | CN-01 | FR-A17 | F1 | = FR-005 |
| CP-02 Vượt cửa kích hoạt | CN-03 | FR-A04 | F2 | ⊃ FR-003 |
| CP-02, CP-03 | CN-04 | FR-A05 | F2 | ⊃ FR-003 |
| CP-02 | CN-05 | FR-A06 | F2 | = FR-004 |
| CP-03 Không lộ nội dung | CN-06 | FR-A07 | F3 | mới |
| CP-04 Không bị phán xét | CN-07 | FR-A08 | F4 | mới |
| CP-05 Khoảng lặng trước khi gửi | CN-07 | FR-A08, FR-A09 | F4 | mới |
| CP-06 Cá nhân hóa | CN-09 | FR-A11, FR-A12 | F6 | mới |
| CP-07 Tự nhìn lại | CN-10 | FR-A13 | F7 | mới |
| CP-07 | CN-11 | FR-A14 | F7 | mới |
| CP-08 Nhịp chuông | CN-08 | FR-A10 | F5 | mới |
| CP-09 Tiện ích nâng cao | CN-12 | FR-A15 | F8 | mới (hoãn) |
| CP-10 Đồng bộ | CN-13 | FR-A16 | F8 | mới (hoãn) |

## 2. Ma trận NFR → canh red-line → FR áp dụng

| NFR | Canh (M#) | Áp FR |
|---|---|---|
| NFR-01 RAM | — (kỹ thuật) | mọi FR extension |
| NFR-02 Độ trễ | — | FR-A01, FR-A09 |
| NFR-03 Riêng tư | **M3** | FR-A07, FR-A09, FR-A13 |
| NFR-04 Không màu cảm xúc | **M1** | FR-A08 |
| NFR-05 Không gamification | **M1** | FR-A11, FR-A12, FR-A13, FR-A14 |
| NFR-06 Copy quan sát | **M2** | FR-A04, FR-A05, FR-A08, FR-A13 |
| NFR-07 core đóng băng | **M4** | FR-A01, FR-A09 |
| NFR-08 Không vỡ macOS | **M5** | mọi FR chạm `shared/` |
| NFR-09 WCAG AA | — | mọi FR có UI |
| NFR-10 Full Access minh bạch | — | FR-A05 |
| NFR-11 iOS không chặn | **M6** | FR-A08 |

---

## 3. ZigZag Validation (toàn chuỗi — BẮT BUỘC sau Step 5)

### 3.1 Xuôi: mọi CP có được phục vụ tới FR?
| CP | → CN | → FR | Phục vụ? |
|---|---|---|---|
| CP-01 | CN-01,02 | FR-A01,A02,A03,A17 | ✅ |
| CP-02 | CN-03,04,05 | FR-A04,A05,A06 | ✅ |
| CP-03 | CN-04,06 | FR-A05,A07 | ✅ |
| CP-04 | CN-07 | FR-A08 | ✅ |
| CP-05 | CN-07 | FR-A08,A09 | ✅ |
| CP-06 | CN-09 | FR-A11,A12 | ✅ |
| CP-07 | CN-10,11 | FR-A13,A14 | ✅ |
| CP-08 | CN-08 | FR-A10 | ✅ |
| CP-09 | CN-12 | FR-A15 | ✅ (hoãn có chủ đích) |
| CP-10 | CN-13 | FR-A16 | ✅ (hoãn có chủ đích) |

→ **0 CP mồ côi.**

### 3.2 Ngược: mọi FR truy về được CP?
| FR | → CN | → CP | Mồ côi? |
|---|---|---|---|
| FR-A01 | CN-01 | CP-01 | Không |
| FR-A02 | CN-02 | CP-01 | Không |
| FR-A03 | (nền build F1) | CP-01 (điều kiện tiên quyết) | Không |
| FR-A04 | CN-03 | CP-02 | Không |
| FR-A05 | CN-04 | CP-02,03 | Không |
| FR-A06 | CN-05 | CP-02 | Không |
| FR-A07 | CN-06 | CP-03 | Không |
| FR-A08 | CN-07 | CP-04,05 | Không |
| FR-A09 | CN-07 | CP-05 | Không |
| FR-A10 | CN-08 | CP-08 | Không |
| FR-A11 | CN-09 | CP-06 | Không |
| FR-A12 | CN-09 | CP-06 | Không |
| FR-A13 | CN-10 | CP-07 | Không |
| FR-A14 | CN-11 | CP-07 | Không |
| FR-A15 | CN-12 | CP-09 | Không |
| FR-A16 | CN-13 | CP-10 | Không |
| FR-A17 | CN-01 | CP-01 | Không |

→ **0 FR mồ côi** (FR-A03 là điều kiện tiên quyết kỹ thuật cho CP-01, ghi rõ để không hiểu lầm là "trên trời").

### 3.3 Kết luận validate
✅ **PASS.** Chuỗi CP→CN→FR khép kín cả 2 chiều. Mọi red-line hiến chương M1–M6 có NFR canh giữ
(§2). Không phát hiện gap traceability.

---

## 4. Map sang BMAD tech-spec (chống trùng, rõ kế thừa/mở rộng)
| tech-spec FR | Analysis FR | Quan hệ |
|---|---|---|
| FR-001 Target iOS | FR-A03 | = trùng |
| FR-002 Gõ Telex qua engine | FR-A01 | ⊃ mở rộng (thêm VNI, thay Mốc A thô) |
| FR-003 Onboarding + Full Access | FR-A04, FR-A05 | ⊃ tách 2 FR |
| FR-004 App Group heartbeat | FR-A06 | = trùng |
| FR-005 tests/ios | FR-A17 | = trùng |
| (không có) | FR-A07..A16 | mới — thuộc tầm nhìn R2+ mà tech-spec (Round 1) cố ý chưa phủ |

→ Tech-spec hiện tại phủ **5/17 FR** = đúng phần Round 1. 12 FR còn lại là tầm nhìn R2+, sẽ nối
vào BMAD qua `09-bmad-reconcile.md`.

---
*Pha 2/4 xong (Step 0→5 + 2 lần zigzag PASS). Kế tiếp: `ROADMAP.md` (Pha 3 — deliverable chính).*
