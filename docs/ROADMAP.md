# Kế hoạch tổng thể + nề nếp nhánh — bám theo để triển khai

> Lộ trình đưa mindful-key từ "tổ chức theo bản năng" về một cấu trúc gọn, deploy được ngay.
> Cấu trúc thư mục & tách brand: `docs/REPO-TOPOLOGY.md`. Release ký/notarize: `docs/RELEASE.md`.

---

## Trước → Sau — ý tổng thể (đọc trước)

> **Cả cuộc dọn này quy về 1 câu:** *một nguồn sự thật cho mỗi thứ* — code có 1 trục `main`,
> brand có 1 `tokens.json`, phiên bản là tag — rồi **mọi đích khác đều SINH RA từ nguồn, không chép tay.**

**A. Tổng thể**

| Khía cạnh | TRƯỚC (theo bản năng) | SAU (có cấu trúc) |
|---|---|---|
| Nhánh | `1.0`/`2.0`/`main` dùng như "phiên bản"; làm trên `2.0` | 1 trục `main` duy nhất; nhánh `feature/*` khi cần |
| `main` | cũ hơn chỗ làm thật 65 commit | luôn là bản mới nhất, luôn deploy được |
| Phiên bản | lẫn với tên nhánh | = TAG `vX.Y.Z` (đã có `v0.2.0`) |
| Người ghé repo thấy | đồ cũ 5 ngày trước | đúng bản hiện hành |
| Landing | artifact rời, chưa vào repo | `site/` trong monorepo |
| Deploy landing | chưa có | Coolify tự deploy khi `site/**` đổi |
| Release | rời rạc | tag `vX.Y.Z` → Actions tự đăng |
| Đồng bộ | sửa nơi này, chạy đi cập nhật nơi kia | 1 repo · 1 push = xong |

**B. Brand (phần bạn hỏi kỹ)**

| | TRƯỚC | SAU |
|---|---|---|
| Nguồn | `tokens.json` nằm **2 bản** (root không-git + mindful-key) — dễ lệch | **1** `brand/tokens.json` + `svg/` duy nhất (SSOT) |
| Asset trong app | xuất thủ công | `make brand` → `platforms/*/Resources` (sinh ra) |
| Asset public | chưa gom | `make public-brand` → `release-out/public-brand/` (sinh ra) |
| Màu trên landing | chép tay vào HTML → **trôi** khỏi tokens | *(tùy chọn)* `make site-css` đọc tokens.json → **hết trôi** |
| Khi đổi 1 màu | sửa nhiều nơi, dễ sót | sửa `tokens.json` → chạy make → **mọi đích ăn theo** |
| Giữ đúng nhận diện | dựa trí nhớ | `brand-lint` tự chặn (đỏ/xanh cảm xúc, emoji, hardcode) |

Cùng một tinh thần lặp lại 3 lần: **1 nguồn → nhiều đích sinh ra.** Code: `main` → tag/deploy.
Brand: `tokens.json` → app + public + landing. Nhờ vậy đổi một chỗ là đồng bộ cả hệ, không lệch pha.

---

## 1. Chẩn đoán nhánh hiện tại (07/2026)

| Nhánh | Vai đang bị gán | Thực tế | Nên là |
|---|---|---|---|
| `2.0` | "phiên bản 2" | Chỗ làm thật, 87 commit, mới nhất | → thành `main` |
| `main` | mặt tiền GitHub | Cũ hơn 2.0 **65 commit**, 0 commit riêng | → kéo lên ngang 2.0 = trục chính |
| `1.0` | "phiên bản 1" | Bản đời cũ, đã nằm gọn trong 2.0 | → tag lưu niệm rồi xóa |
| tag `v0.1.0`, `v0.2.0` | — | Phiên bản THẬT của sản phẩm | ✅ giữ, tiếp tục kiểu này |

**Gốc rối:** *nhánh* bị dùng làm *phiên bản*. Nhánh (branch) là **dòng sông đang chảy** — việc còn
tiếp diễn. Tag là **tấm ảnh chụp** đóng băng một bản đã phát hành. Bạn đã có ảnh (`v0.2.0`) rồi, nên
không cần dòng sông tên `1.0`/`2.0` nữa.

## 2. Mô hình nhánh đích (đơn giản, hợp solo)

- **`main` = trục chính DUY NHẤT.** Luôn ở trạng thái deploy được. Coolify + GitHub Releases đều nhìn
  vào đây. GitHub default = `main`.
- **Phiên bản = TAG** `vX.Y.Z` (đọc từ `version.env`). KHÔNG bao giờ đặt tên nhánh theo phiên bản nữa.
- **Việc mới = nhánh `feature/...` ngắn ngày** → merge vào `main`. *(Lúc còn private/solo, làm thẳng
  trên `main` cũng được. Khi ra công khai (hướng a) thì dùng feature branch + PR để `main` luôn sạch.)*

## 3. Kế hoạch tổng thể theo giai đoạn

### ▶ Giai đoạn 0 — Dọn nhánh  *(BẠN ĐANG Ở ĐÂY — làm trước, là nền cho mọi thứ sau)*
An toàn tuyệt đối vì `main`/`1.0` không có commit riêng nào (không mất gì):
```bash
git checkout main && git merge --ff-only 2.0 && git push origin main   # main = mới nhất
git checkout main                                                       # từ nay làm trên main
git tag gen1-openkey 1.0 && git push origin gen1-openkey                # (tùy) giữ mốc đời 1
git push origin --delete 1.0 && git branch -D 1.0                       # xóa 1.0
# giữ 2.0 vài hôm cho chắc, khi yên tâm:  git push origin --delete 2.0 && git branch -D 2.0
```
Rồi: đổi trigger CI (`.github/workflows/*`) + Coolify sang nhánh `main`.

### ▶ Giai đoạn 1 — Landing + Coolify
- `site/index.html` (từ artifact), nút tải → GitHub Releases.
- `site/Dockerfile` (nginx 2 dòng) cho Coolify.
- Coolify: repo → Base Directory `site` · Static · **Watch Paths `site/**`** · nhánh `main` · domain + TLS.
- Chi tiết: `docs/REPO-TOPOLOGY.md §6`.

### ▶ Giai đoạn 2 — Brand hết trôi màu  *(tùy chọn, nhẹ)*
- `make site-css`: sinh `site/assets/tokens.css` từ `brand/tokens.json` → landing đọc token, hết chép tay.

### ▶ Giai đoạn 3 — Release thật  *(khi có Apple Developer Program)*
- Pipeline ký + notarize đã viết sẵn. Chỉ cần cert → tag `vX.Y.Z` → Actions tự đăng Release.
- Chi tiết + 7 secret cần khai: `docs/RELEASE.md`.

### ▶ Giai đoạn 4 — Công khai (hướng a)  *(khi sẵn sàng ra mắt)*
- README đẹp (hero brand), `LICENSE` GPL v3 + **credit Mai Vũ Tuyên**, đổi repo sang public.
- 1 repo vừa dev vừa public; brand chảy 1 nguồn → 3 đích (`docs/REPO-TOPOLOGY.md §4`).

## 4. Nề nếp git từ nay (quy tắc bám theo)

1. **`main` luôn deploy được.** Đừng đẩy đồ hỏng lên main. Coolify + Releases nhìn vào đây.
2. **Phát hành = 3 bước:** bump `version.env` → cập nhật `CHANGELOG.md` → tag `vX.Y.Z` và push tag.
3. **Việc rủi ro/nhiều commit → nhánh `feature/...`** rồi merge; việc nhỏ solo → thẳng main.
4. **Không đặt tên nhánh theo phiên bản.** Phiên bản là tag, mãi mãi.
5. **2 "đội" macOS/iOS** vẫn chung 1 nhánh, commit đích danh file của mình (đừng `git add -A`).
