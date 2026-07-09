# Hướng dẫn dùng bộ skill BMAD Planning & Orchestrator

> Bộ skill ngoài (plugin `bmad-planning-orchestrator@bmad-method-harness`, cài
> 2026-07-09, scope **user** — áp dụng mọi project, không riêng repo này).
> **Chỉ lập kế hoạch, không viết code.** Đây là tài liệu tự học — không phải
> HIẾN CHƯƠNG, không ràng buộc agent nào phải tuân theo.

Tác giả gốc phương pháp: BMAD Code Organization (https://github.com/bmad-code-org/BMAD-METHOD).
Plugin này là harness cộng đồng đóng gói lại cho Claude Code, không phải sản phẩm chính thức.

---

## 1. Tư duy cốt lõi trước khi học cú pháp

BMAD tách rời **"nghĩ cái gì"** khỏi **"viết code"**. Bốn giai đoạn:

```
PHÂN TÍCH (tùy chọn) → LẬP KẾ HOẠCH → GIẢI PHÁP/KIẾN TRÚC → ĐIỀU PHỐI
                                                                  │
                                          ready-for-dev story + handoff-manifest.json
                                                                  │
                                                                  ▼
                                                    công cụ code thật (Claude Code, harness riêng...)
```

Sản phẩm cuối cùng BMAD tạo ra luôn là **văn bản** (PRD, kiến trúc, story file) —
không bao giờ là code, test, hay build. Nếu bạn thấy mình đang yêu cầu nó "sửa
file .cpp giùm tôi" — sai chỗ, quay lại `engine-agent`/`platform-shell-agent`.

## 2. Cú pháp gọi skill

**Cách 1 — tự nhiên (khuyên dùng hằng ngày):** gõ đúng ý định bằng tiếng Việt
hoặc Anh, Claude tự nhận diện skill phù hợp. Ví dụ: "giúp tôi viết PRD cho tính
năng X" → tự gọi `bmad-prd`.

**Cách 2 — gọi thẳng khi biết chính xác muốn skill nào:**
```
/bmad-planning-orchestrator:<tên-skill>
```
Ví dụ: `/bmad-planning-orchestrator:bmad-init`

**Lệnh định hướng, dùng bất cứ lúc nào bí:**
```
/bmad-planning-orchestrator:bmad-help
```
Nó tự quét thư mục `bmad-output/` xem đã có gì, suy ra đang ở giai đoạn nào,
và nói bước kế tiếp nên chạy skill gì. Coi đây là "trợ lý điều hướng" — mở đầu
mỗi phiên làm việc BMAD bằng lệnh này nếu quên mình đang ở đâu.

## 3. Lộ trình tự học — 4 buổi, học từ từ

Đừng học hết 20 skill cùng lúc. Gợi ý chia theo buổi, mỗi buổi thực hành ngay
(xem mục 5 — có bài tập thật trên chính dự án này):

**Buổi 1 — Khung xương (2 skill):** `bmad-init`, `bmad-help`.
Mục tiêu: hiểu track (Quick Flow / BMad Method / Enterprise) và vòng lặp
"chạy `bmad-help` → được gợi ý → chạy skill được gợi ý → quay lại `bmad-help`".

**Buổi 2 — Từ ý tưởng ra yêu cầu (4 skill):** `bmad-brainstorm`,
`bmad-product-brief`, `bmad-spec` (bản rút gọn), `bmad-prd` (bản đầy đủ).
Mục tiêu: phân biệt khi nào cần PRD đầy đủ (FR/NFR, epic, MoSCoW) và khi nào
chỉ cần `SPEC.md` 5 mục cho việc nhỏ.

**Buổi 3 — Từ yêu cầu ra kiến trúc + story chia việc song song (3 skill):**
`bmad-architecture`, `bmad-epics-and-stories`, `bmad-parallel-plan`.
Mục tiêu: hiểu vì sao BMAD nhấn mạnh "1 kiến trúc chung" + "story sở hữu file
riêng" — đây là cơ chế chống việc nhiều agent code song song đá nhau.

**Buổi 4 — Bàn giao + việc phát sinh giữa chừng (3 skill):**
`bmad-readiness-check`, `bmad-handoff`, `bmad-correct-course`.
Mục tiêu: biết khi nào kế hoạch "đủ chín" để giao việc, và cách xử lý khi
khách/bản thân đổi ý giữa chừng mà không phải code lại từ đầu.

Các skill còn lại (`bmad-research`, `bmad-prfaq`, `bmad-ux`, `bmad-tech-spec`,
`bmad-sprint-planning`, `bmad-investigate`, `bmad-document-project`,
`bmad-builder`) — tra ở bảng mục 4 khi cần, không cần học trước.

## 4. Bảng tra cứu nhanh (tình huống → skill → kết quả)

| Tình huống | Skill | Kết quả |
|---|---|---|
| Mới cài, chưa biết bắt đầu đâu | `bmad-init` | scaffold `bmad-output/` + chọn track |
| Không biết bước kế tiếp | `bmad-help` | gợi ý skill nên chạy |
| Chưa rõ ý tưởng, cần vắt óc | `bmad-brainstorm` | ý tưởng theo SCAMPER/SWOT/5-Whys |
| Cần khảo sát thị trường/kỹ thuật có trích nguồn | `bmad-research` | báo cáo có citation |
| Có ý tưởng, cần chốt "sản phẩm là gì" | `bmad-product-brief` | product brief |
| Muốn kiểu Amazon "viết press release trước" | `bmad-prfaq` | PR/FAQ working-backwards |
| Việc nhỏ, chỉ cần lõi 5 mục | `bmad-spec` | `SPEC.md` |
| Viết yêu cầu chi tiết, chia epic, ưu tiên MoSCoW | `bmad-prd` | `prd.md` + `addendum.md` |
| Track Quick Flow, khỏi cần PRD | `bmad-tech-spec` | tech spec gọn |
| Có UI, cần token thiết kế + hành trình dùng | `bmad-ux` | `DESIGN.md` + `EXPERIENCE.md` |
| Cần 1 kiến trúc chung tránh đá nhau khi code song song | `bmad-architecture` | `architecture.md` + ADR |
| Chia PRD thành story cụ thể, mỗi story 1 vùng file riêng | `bmad-epics-and-stories` | `{epic}.{story}.{slug}.story.md` |
| Trước khi giao việc, kiểm tra đã sẵn sàng chưa | `bmad-readiness-check` | PASS / CONCERNS / FAIL |
| Cần lịch trình thứ tự làm | `bmad-sprint-planning` | `sprint-status.yaml` |
| Nhiều story độc lập, muốn chạy song song an toàn | `bmad-parallel-plan` | các "wave" + nhánh git |
| Sẵn sàng giao cho công cụ code thật | `bmad-handoff` | `handoff-manifest.json` |
| Đang làm giữa chừng, đổi scope | `bmad-correct-course` | re-plan, không đụng code đã viết |
| Bug/sự cố cần điều tra trước khi fix | `bmad-investigate` | story điều tra có bằng chứng |
| Dự án cũ (brownfield), cần tài liệu hiện trạng | `bmad-document-project` | tài liệu read-only |
| Muốn tự tạo thêm skill lập kế hoạch riêng | `bmad-builder` | scaffold skill mới |

## 5. Bài tập thực hành thật — dùng chính mindful-keyboard

Học BMAD bằng ví dụ ngẫu nhiên sẽ mau quên. Dự án này đang có sẵn 1 việc thật,
đủ lớn, đúng lúc cần lập kế hoạch: **cổng Windows** (đã ghi trong `CLAUDE.md`:
*"dự án chuẩn bị bước sang giai đoạn build app Windows thật"*). Dùng nó làm
bài tập xuyên suốt 4 buổi ở mục 3:

```
Buổi 1:  bmad-init
         → chọn track "BMad Method" (không phải Quick Flow — port sang 1 OS
           mới, đụng hook bàn phím + tray + toàn bộ vỏ, không phải việc <15 story)

Buổi 2:  bmad-product-brief  → chốt: MVP Windows cần gì, KHÔNG cần gì
         bmad-prd            → FR/NFR cho win32/ (hook, tray, popup cảm xúc)

Buổi 3:  bmad-architecture       → 1 kiến trúc: win32/ dùng engine chung ra sao,
                                    không fork logic gõ (đúng cột trụ HIẾN CHƯƠNG)
         bmad-epics-and-stories  → chẻ: "hook bàn phím Win32", "tray icon",
                                    "cổng gác gửi tin trên Windows", mỗi story
                                    sở hữu file riêng để platform-shell-agent
                                    nhận từng phần mà không đụng engine/

Buổi 4:  bmad-readiness-check   → PASS trước khi giao
         bmad-handoff           → handoff-manifest.json
         → đưa từng story cho platform-shell-agent (qua skill platform-porting)
           thực thi thật
```

Lưu ý khi thực hành: BMAD sẽ hỏi bạn nhiều quyết định (phạm vi, ưu tiên, đánh
đổi). Những quyết định **chạm nhận diện/pháp lý** (đèn xanh-đỏ, gamification,
GPL v3, credit OpenKey...) — theo đúng HIẾN CHƯƠNG, đừng để BMAD tự quyết, luôn
xác nhận lại với bạn trước khi ghi vào PRD/kiến trúc.

## 6. Ba thứ đang bị gọi chung là "Harness" — đừng nhầm

Chữ "harness" xuất hiện ở **3 chỗ khác nhau** trong dự án này, dễ tưởng là 1:

| | ① Meta-skill `harness` (`harness@harness-marketplace`) | ② `mindful-keyboard-harness` | ③ BMAD (`bmad-method-harness`) |
|---|---|---|---|
| Nó là gì | "Nhà máy" dựng team agent — cho 1 câu mô tả domain, nó sinh ra bộ agent + skill tương ứng | Kết quả cụ thể mà ① đã dựng ra **riêng cho dự án này** (2026-07-08, xem changelog CLAUDE.md) | Plugin lập kế hoạch theo phương pháp BMAD, cài **riêng, không liên quan** gì tới ① hay ② |
| Phạm vi | Tổng quát — dùng cho bất kỳ domain/dự án nào cần chia chuyên gia | Chỉ riêng mindful-keyboard: 3 chuyên gia engine/mood/platform | Tổng quát — dùng cho bất kỳ dự án nào cần lập PRD/kiến trúc, không biết gì về mindful-keyboard |
| Đầu ra | 1 bộ agent + skill mới (vd chính là ②) | Code diff thật trong `OpenKey/Sources/...`, do agent chuyên trách sửa | Văn bản kế hoạch (`.md`/`.yaml`/`.json`) trong `bmad-output/`, **không đụng code** |
| Khi nào dùng | Khi cần dựng 1 harness **mới** cho domain khác (hiếm khi cần lại) | Mỗi khi việc trong dự án này chạm code — để không sửa nhầm mảng (vd sửa mood-layer mà lại đụng engine dùng chung) | Trước khi bắt tay code 1 tính năng lớn, còn mơ hồ, cần nghĩ rõ trước |

Nói ngắn: **① là cái máy dựng harness, ② là "sản phẩm" cụ thể do máy đó dựng ra
cho riêng dự án này, ③ là 1 plugin lập kế hoạch mua ngoài, tình cờ cũng tự gọi
mình là "harness" nhưng chẳng liên quan gì đến ① và ②.** Bạn hầu như sẽ không
bao giờ cần đụng vào ① nữa (đã dùng để dựng ② rồi) — hằng ngày chỉ cần nhớ
phân biệt ② (thực thi code) và ③ (lập kế hoạch).

**Thứ tự hợp lý cho việc lớn:** BMAD (③) lập kế hoạch → xong mới gọi
`mindful-keyboard-harness` (②) để phân việc cho đúng chuyên gia thực thi. Việc
nhỏ, rõ ràng (sửa 1 dòng, 1 bug cụ thể) thì bỏ qua BMAD, gọi thẳng ② hoặc skill
chuyên biệt như bình thường — không phải việc gì cũng cần lập kế hoạch hình thức.

## 7. Vận hành / khắc phục sự cố

- **Nơi lưu artifact:** mặc định `bmad-output/` (tương đối theo project đang
  mở). Đổi qua `/plugin configure bmad-planning-orchestrator@bmad-method-harness`.
- **Chi phí token:** cộng thêm ~7.5k token always-on vào *mọi* phiên Claude Code
  (vì cài scope user). Nếu chỉ muốn dùng cho vài project, tắt riêng ở project
  khác bằng `claude plugin disable bmad-planning-orchestrator@bmad-method-harness`.
- **Bug đã vá (2026-07-09):** bản 0.5.0 có lỗi `Duplicate hooks file detected`
  do khai thừa `"hooks": "./hooks/hooks.json"` trong manifest — đã sửa trực
  tiếp trong cache local (`~/.claude/plugins/cache/bmad-method-harness/...`).
  Bản vá này **mất khi plugin cập nhật lên version mới** — nếu sau này thấy lại
  lỗi "failed to load", quay lại đây, xóa dòng `"hooks": "./hooks/hooks.json"`
  trong `plugin.json` của bản mới, rồi `claude plugin disable` → `enable` lại.
- **Xem đầy đủ danh mục + sơ đồ luồng gốc:** README của plugin tại
  `~/.claude/plugins/cache/bmad-method-harness/bmad-planning-orchestrator/<version>/README.md`.
