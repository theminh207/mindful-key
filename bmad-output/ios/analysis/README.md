# analysis/ — Gói phân tích sản phẩm Mindful Key iOS

Phân tích sâu để nâng iOS từ *walking skeleton* → **sản phẩm bàn phím đầy đủ** (giống Laban ~80%
phần công cụ + lớp chánh niệm: sóng `~`, chuông, nhật ký). Dùng bộ skill `analysis` (discovery +
problem-based-srs). **Nơi lưu:** hòa với workspace BMAD iOS, coi SPEC/tech-spec cũ là input.

> ⚖️ Luật tối cao vẫn là HIẾN CHƯƠNG (`docs/AGENT-BRIEF.md`). Gói này là **phân tích/tài liệu** —
> không code, không sửa `core/`, không sửa README lạc hậu (chỉ ghi nhận ở `09` để chờ duyệt).

## Đọc theo thứ tự

| File | Pha | Nội dung |
|---|---|---|
| [`00-input-ledger.md`](00-input-ledger.md) | 0 | **Đã có / cần làm** — đối chiếu tài liệu ↔ code thật. Bắt đầu ở đây. |
| [`01-discovery-findings.md`](01-discovery-findings.md) | 1 | Discovery — thách thức "clone Laban", 5 lớp BABOK, Open Questions |
| [`02-business-context.md`](02-business-context.md) | 2 | Business context + hiến chương M1–M6 |
| [`03-customer-problems.md`](03-customer-problems.md) | 2 | CP (WHY) — 10 vấn đề |
| [`04-software-glance.md`](04-software-glance.md) | 2 | Bức phác giải pháp (Mermaid) |
| [`05-customer-needs.md`](05-customer-needs.md) | 2 | CN (WHAT) — 13 nhu cầu + zigzag CP→CN |
| [`06-software-vision.md`](06-software-vision.md) | 2 | Vision + 8 nhóm tính năng F1–F8 (Mermaid) |
| [`07-functional-requirements/`](07-functional-requirements/_index.md) | 2 | FR-A01..A17 (HOW) |
| [`07-non-functional/`](07-non-functional/_index.md) | 2 | NFR-01..11 — mỗi red-line M1–M6 có 1 NFR canh |
| [`08-traceability-matrix.md`](08-traceability-matrix.md) | 2 | CP→CN→FR + zigzag PASS 2 chiều + map BMAD |
| [`ROADMAP.md`](ROADMAP.md) | 3 | ⭐ **Deliverable chính** — 4 round, trạng thái ✅/🟡/⬜ mỗi FR |
| [`09-bmad-reconcile.md`](09-bmad-reconcile.md) | 4 | Nối BMAD + **Decision Queue** (Q1–Q11) + doc-drift |

## Kết luận 1 dòng
Round 1 mới ~30% (khung + gỡ rủi ro engine); **lớp chánh niệm — linh hồn sản phẩm — chưa bắt
đầu (R2+)**. 12/17 FR chờ khởi công; nhiều phần chạm nhận diện nên **chờ chủ dự án chốt Decision
Queue** (`09`) trước khi làm sâu.
