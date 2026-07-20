# Hướng dẫn dùng Understand-Anything cho mindful-key

> Plugin ngoài (`understand-anything@understand-anything`, cài 2026-07-18,
> scope **project** — chỉ áp dụng cho repo `mindful-key` này, không kéo theo
> project khác). Tạo bản đồ tri thức (knowledge graph) của code để đọc hiểu
> nhanh. **Chỉ đọc hiểu, không sửa code.** Tài liệu tự học — không phải HIẾN
> CHƯƠNG, không ràng buộc agent nào phải tuân theo.
>
> Nguồn: https://github.com/Egonex-AI/Understand-Anything (MIT).

---

## 1. Tư duy cốt lõi trước khi học cú pháp

Hình dung code của `mindful-key` giống 1 thành phố có `core/` (bộ não C++
dùng chung) làm trung tâm, tỏa ra nhiều khu `platforms/` (vỏ macOS/Windows/
Android/iOS). Đọc code trực tiếp giống đi bộ dò từng con hẻm — chậm và dễ lạc.
Understand-Anything khảo sát cả thành phố 1 lần rồi vẽ ra **bản đồ tương tác**:
click vào 1 tòa nhà (file/hàm/class) là biết nó làm gì, nối với ai, thuộc khu
nào (layer kiến trúc).

Cách nó vẽ: phần "đường xá" (import, gọi hàm, kế thừa) dùng tree-sitter đọc
thẳng cú pháp — chắc chắn, không bịa. Phần "mô tả tòa nhà" (file này để làm
gì) do AI đọc code rồi viết tiếng người — **có thể sai**, vì là suy diễn chứ
không phải phân tích tĩnh.

**Quan hệ với tài liệu đã có:** dự án đã có `docs/OPENKEY-MAP.md`,
`docs/BREATHING-PAUSE-CONTRACT.md`... viết tay, xác minh kỹ theo dòng số cụ
thể. Understand-Anything **không thay thế** mấy file đó — dùng nó như tấm
gương đối chiếu: nếu bản đồ AI vẽ ra khác với những gì tài liệu tay đã ghi,
đó là dấu hiệu lệch pha, ghi vào `docs/FRICTION-LOG.md` chứ đừng sửa tài liệu
gốc theo AI ngay. Đúng luật "CẤM đoán" trong CLAUDE.md — coi output của nó là
gợi ý định hướng, verify lại code thật trước khi quyết định.

## 2. Cú pháp gọi lệnh

Gõ thẳng dạng slash command trong Claude Code, không cần cài thêm gì (plugin
đã ở scope project, tự nhận trong repo này):

```
/understand              → quét code, dựng/cập nhật bản đồ
/understand-dashboard    → mở lại bản đồ trực quan (web, chạy trên máy)
/understand-chat "..."   → hỏi nhanh về code
/understand-explain <file/hàm>  → đào sâu 1 điểm cụ thể trước khi sửa
/understand-diff         → soi impact trước khi commit/push
/understand-domain       → vẽ luồng nghiệp vụ (business flow)
/understand-onboard      → sinh tài liệu onboarding đầy đủ
```

(`/understand-knowledge` và `/understand-figma` không áp dụng cho repo này —
dành cho wiki dạng Karpathy-pattern và file thiết kế Figma, dự án không có.)

## 3. Cơ chế lưu & chi phí token — điều hay quên nhất

**Lưu ở đâu:** không nằm trong bộ nhớ hội thoại Claude Code — nằm thẳng trên
đĩa, thư mục `.ua/` tại gốc repo (`.ua/knowledge-graph.json` là bản đồ chính,
`.ua/meta.json` nhớ đã quét tới commit nào). Giống viết ra sổ tay để trên bàn
thay vì nhớ trong đầu — mở cửa sổ Claude Code mới (session mới), sổ vẫn còn
nguyên, không phải viết lại.

**Có tốn token quét lại mỗi lần không? Không, trừ 1 trường hợp:**
- Chưa đổi commit nào từ lần quét trước → nó chỉ hỏi ông muốn làm gì, không
  tự đốt token.
- Có sửa code → chỉ quét lại đúng file đã đổi (incremental) — rẻ hơn nhiều so
  với lần đầu.
- Chỉ khi tự gõ `--full` mới bắt buộc quét lại toàn bộ, tốn như lần đầu.

**Các lệnh hỏi/xem** (`understand-chat`, `understand-dashboard`,
`understand-diff`, `understand-explain`, `understand-onboard`) **không** chạy
lại dàn agent quét — chỉ đọc file `knowledge-graph.json` có sẵn (grep tìm
đúng chỗ, không nhồi cả file vào ngữ cảnh) → gần như miễn phí. Trước khi trả
lời, nó tự so `gitCommitHash` lưu trong graph với `git rev-parse HEAD` hiện
tại — lệch thì cảnh báo thẳng "có thể thiếu phần mới sửa", không tự âm thầm
quét lại hay bịa.

**Nên bật `/understand --auto-update`** — gắn hook chạy sau mỗi commit, tự vá
bản đồ (incremental) mà không cần nhớ tay gọi lại.

## 4. Bảng tra cứu nhanh (tình huống → lệnh → mục đích)

| Tình huống | Lệnh | Mục đích |
|---|---|---|
| Lần đầu / lâu rồi chưa quét | `/understand` | Dựng hoặc vá bản đồ tri thức |
| Muốn xem lại bản đồ trực quan | `/understand-dashboard` | Mở web dashboard, không quét lại |
| Thắc mắc nhanh lúc code | `/understand-chat "câu hỏi"` | Trả lời dựa trên bản đồ đã có |
| Sắp sửa 1 file/hàm lạ | `/understand-explain <path>` | Đào sâu: vai trò, láng giềng, luồng dữ liệu |
| Trước khi commit/push | `/understand-diff` | Soi thay đổi rung dây chuyền tới đâu |
| Muốn xem luồng nghiệp vụ (không phải luồng code) | `/understand-domain` | Vẽ domain/flow/step — đối chiếu tài liệu tay |
| Cần tài liệu tổng quan dễ đọc | `/understand-onboard` | Sinh Markdown: layer, tour, file map, điểm phức tạp |
| Sau lần quét lớn đầu tiên | `/understand --auto-update` | Bật tự vá bản đồ mỗi commit |

## 5. Quy trình dùng thực tế cho dự án này

```
Lần đầu:  /understand
          → DUYỆT .understandignore trước khi xác nhận quét thật (xem mục 6)
          → xong tự bật /understand-dashboard, lướt tổng quan trước
          → /understand-onboard 1 lần, lưu ra docs/ONBOARDING.md nếu ưng

Hằng ngày:
          Sắp sửa 1 chỗ lạ  → /understand-explain <file>
          Có thắc mắc       → /understand-chat "..."
          Trước khi push    → /understand-diff  (cộng thêm make test + make build đã có)

Định kỳ:  /understand --auto-update  (bật 1 lần, khỏi phải nhớ)
          /understand-domain         (thỉnh thoảng đối chiếu với OPENKEY-MAP.md)
```

## 6. Riêng cho mindful-key — chỗ cần chỉnh tay

Repo này là monorepo trộn nhiều thứ khác bản chất: `core/` + `platforms/`
(code kỹ thuật thật) nằm chung với `site/` (web marketing), `build/`,
`release-out/`, `models/` (build artifact/binary). Quét chung hết sẽ loãng
bản đồ, tốn token vô ích. Khi `.ua/.understandignore` hiện ra để duyệt (Phase
0.5 của `/understand`), loại các thư mục sau:

```
site/
build/
release-out/
models/
```

Giữ lại `core/`, `platforms/`, `docs/`, `bmad-output/` — vì đó mới là "vì sao"
đằng sau code kỹ thuật.

`.gitignore` hiện **chưa** chặn `.ua/` — nên thêm 2 dòng sau để khỏi commit
rác tạm, nhưng **giữ lại** `knowledge-graph.json` + `meta.json` để commit
thật (đổi máy hoặc kéo thêm người vào đội macOS/iOS thì `git pull` là có sẵn
bản đồ, khỏi tốn token quét lại):

```gitignore
.ua/intermediate/
.ua/diff-overlay.json
```

Nếu sau này chạy lệnh này từ trong 1 git worktree (harness của dự án có dùng
worktree để chạy song song) — nó tự chuyển chỗ lưu về repo chính, vì worktree
bị xóa là mất bản đồ theo. Không cần tự tay xử lý việc này.

## 7. Vận hành / khắc phục sự cố

- **Nơi lưu artifact:** `.ua/` tại gốc repo (`/Users/now/Projects/mindful-keyboard/mindful-key/.ua/`).
- **Cài đặt:** scope `project`, chỉ áp dụng repo này — không cộng thêm token
  always-on vào project khác (khác với plugin BMAD cài scope `user`, xem
  `docs/BMAD-SKILLS-GUIDE.md` mục 7).
- **Không thấy `/understand-dashboard` mở được:** kiểm tra `.ua/knowledge-graph.json`
  đã tồn tại chưa — nếu chưa, `/understand` vẫn đang chạy dở hoặc chưa chạy
  lần nào.
- **Nghi ngờ mô tả graph sai:** đọc lại source thật tại `filePath` ghi trong
  node đó — phần mô tả là AI suy diễn, không phải nguồn sự thật.
- **Xem đầy đủ tài liệu gốc:** `~/.claude/plugins/marketplaces/understand-anything/README.md`.
