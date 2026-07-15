# Tổ chức repo & tách brand — dev vs public/release

> Bản đồ "cái gì sống ở đâu trên GitHub": repo phát triển, repo public/release, mọi nền tảng,
> và brand chảy giữa chúng thế nào. Đọc khi phân vân "để cái này vào repo nào".

Hình dung như một **xưởng bếp**: repo dev là **bếp** (bừa bộn, dao thớt, nguyên liệu, công thức);
repo public là **mặt tiền nhà hàng** (thực đơn đẹp, món đã dọn ra đĩa). Khách chỉ thấy mặt tiền.
Brand là bộ nhận diện của quán — logo, màu, biển hiệu — làm **một lần trong bếp**, rồi bày ra mặt tiền.

---

## 1. Hai repo, hai vai

| | Repo **dev** (monorepo) | Repo **public / release** |
|---|---|---|
| Là gì | Nơi code, bừa cũng được | Mặt tiền + chỗ tải bản chạy |
| Chứa | `core/` engine, `platforms/*` mọi OS, `brand/` (nguồn), `bmad-output/`, docs | README đẹp, ảnh brand đã dựng, GitHub Releases (.dmg/.exe), mã nguồn bản phát hành (GPL) |
| Hiện tại | `theminh207/mindful-key` (nhánh `2.0`) | *chưa tạo — bạn sắp mở* |
| Ai đọc | Bạn + agent | Người dùng cuối + người đóng góp |

**⚠️ Sự thật đang có (đọc kỹ trước khi tách):** pipeline release hiện tại (`scripts/release.sh` +
`.github/workflows/release.yml`) đang **phát hành THẲNG từ repo dev** `theminh207/mindful-key` —
gắn tag `vX.Y.Z` là GitHub Actions tự dựng + đăng Release ngay tại đó (kiểu repo tham chiếu
`sonpiaz/haynoi`). Xem `docs/RELEASE.md`.

→ Nghĩa là repo public bạn sắp mở là **một lớp mới**. Có 2 cách khớp nó vào (bạn quyết — chạm pháp lý GPL):

- **(a) Repo public = mã nguồn mở luôn.** Chuyển/đổi tên repo dev thành public, phát triển công khai,
  release tại chỗ. Đơn giản nhất, đúng chuẩn GPL, khớp haynoi. **Khuyên dùng.**
- **(b) Giữ repo dev riêng tư + repo public riêng.** Mỗi lần release thì đẩy mã nguồn bản đó
  sang repo public. Giữ được "sân sau" nhưng thêm việc, và vẫn phải đảm bảo GPL (xem §3).

---

## 2. Mọi nền tảng ở **một** monorepo — kể cả iOS/Android

Đây là câu bạn hỏi: "iOS/Android tổ chức chung được không hay tách?" → **Chung. Đừng tách repo.**

Lý do nằm ở chính kiến trúc *"1 bộ não + nhiều vỏ"*:

- **Bộ não dùng chung.** Engine C++ (Telex/VNI, luật bỏ dấu) + lớp mood (`core/`) là **chung mọi OS**.
  Tách mobile ra repo riêng → hoặc nhân đôi bộ não, hoặc phải kéo qua submodule/package. Cả hai
  đều phá đúng mục tiêu "không fork logic gõ".
- **Một `tokens.json` cho tất cả.** Đổi màu 1 chỗ, mọi vỏ thấy ngay.
- **Team nhỏ** → nhiều repo = thuế điều phối version chéo, không đáng lúc này.

Cách bày (đã đúng như hiện tại):
```
core/{engine,mood}/                    ← 1 bộ não C++ dùng chung
platforms/apple/{macos,ios}/           ← chung engine + Assets
platforms/{windows,android,linux}/
brand/                                 ← 1 nguồn nhận diện
```

**Nhớ khi làm mobile (đừng kỳ vọng copy-paste desktop):** tính năng vương miện — *gác cổng chặn
Enter trong Zalo* — **iOS làm gần như không được** (bàn phím iOS là extension bị nhốt trong hộp cát,
không thấy nút "Gửi" của app khác). Dự án **đã chốt** mandate iOS hẹp lại: **chỉ nhật ký + nhắc thụ
động, KHÔNG gác cổng gửi tin** (xem `docs/FRICTION-LOG.md`, 2026-07-10). Android đỡ hơn nhưng cũng
bị giới hạn IME. → Mobile **dùng chung engine + mood + brand**, nhưng **tính năng từng vỏ khác nhau**
— càng là lý do để chung repo (chia sẻ cái chia sẻ được), chỉ khác ở tầng vỏ.

**Khi nào MỚI tách repo một nền tảng?** Khi nó có **đội riêng + nhịp release riêng** và chi phí điều
phối 1 repo lớn hơn lợi ích code chung. Chưa phải bây giờ. Kể cả lúc đó, engine vẫn share qua
package — không fork.

---

## 3. Cảnh báo định hình repo public: **GPL v3**

Sản phẩm kế thừa GPL v3 từ OpenKey. Luật cốt lõi: **hễ phát hành bản chạy (.dmg/.exe), phải kèm
mã nguồn tương ứng.** Nên repo public **không được là "chỉ binary, giấu code"**.

- Cách (a) ở §1 tự thỏa mãn (code vốn đã mở).
- Cách (b): mỗi Release phải đính kèm/đẩy được mã nguồn của đúng bản đó.
- Luôn giữ **credit Mai Vũ Tuyên** + file `LICENSE` (GPL v3) trong repo public (điều bất khả xâm phạm).

Đây là chỗ chạm pháp lý → nếu còn phân vân cách làm, **chốt với chủ dự án** trước khi public.

---

## 4. Tách brand: **1 nguồn → 3 đích**

Đừng nghĩ "brand để ở repo nào" mà nghĩ "brand chảy từ 1 nguồn ra 3 nơi". Như logo quán: vẽ 1 lần,
in ra biển hiệu, in lên bao bì, đăng lên Facebook — cùng 1 file gốc.

| Tầng | Là gì | Sống ở đâu | Ai sửa |
|---|---|---|---|
| **① Nguồn (SSOT)** | `tokens.json` + `svg/` + `export-*.sh` | **repo dev** `brand/` | Bạn sửa ở ĐÂY, duy nhất |
| **② Brand-trong-app** | `.icns/.ico/PNG` nhúng vào từng vỏ | `platforms/*/Resources` (sinh ra) | Không — chạy `make brand` |
| **③ Brand-cho-public** | hero, social-preview, wordmark, icon | **repo public** (copy vào) | Không — chạy `make public-brand` |

**Nguyên tắc vàng:** chỉ tầng ① sửa được. Tầng ②③ luôn **sinh ra** từ ①. Nhờ vậy mặt tiền public
không bao giờ lệch tông với app — cả hai cùng đọc `tokens.json`.

```
[repo DEV]  brand/svg + brand/tokens.json        ← nguồn thật
                 │ make brand         │ make public-brand
                 ▼                    ▼
      platforms/*/Resources    release-out/public-brand/   ── copy ──▶  [repo PUBLIC] assets/brand/
        (asset trong app)        (readme/, icons/)
```

Khi nào brand thành **repo thứ 3 riêng** (`now-brand-os`)? Chỉ khi **sản phẩm GNH thứ 2** dùng chung
brand này. Lúc đó `tokens.json` tách ra làm hợp đồng chung. Giờ để trong repo dev là đúng.

---

## 5. Runbook

**Làm mới bộ brand public rồi bê sang repo public:**
```bash
make public-brand                       # sinh release-out/public-brand/ (readme/ + icons/)
cp -R release-out/public-brand/. <repo-public>/assets/brand/
# social-preview.png → repo public › Settings › Social preview (upload, không cần commit)
```

**Phát hành bản chạy** (chi tiết ký + notarize: `docs/RELEASE.md`):
```bash
# 1. bump VERSION trong version.env
# 2. cập nhật CHANGELOG.md ([Unreleased] → [X.Y.Z])
# 3. commit 2 file trên
git tag vX.Y.Z && git push origin <nhánh> --tags   # Actions tự dựng + đăng Release
```

> Đổi màu/mark trong brand = việc lớn: bump version brand, ghi CHANGELOG, chạy lại cả `make brand`
> (asset trong app) **và** `make public-brand` (mặt tiền) để hai bên không lệch nhau.

---

## 6. Deploy landing (Coolify) — chốt 2026-07-15

**Landing sống ngay trong monorepo tại `site/`** (brand-lint đã quét sẵn `site/`). Là **HTML tĩnh,
KHÔNG build** → **không dùng Astro** (Astro chỉ đáng khi cần build/nhiều trang). Coolify nhà trồng
trỏ thẳng vào repo, bày file ra là xong.

**Cấu hình Coolify (bản nhẹ nhất):**
- Nối Git repo (repo private → cài Coolify GitHub App).
- **Base Directory:** `site` · Build Pack: **Static** (không cần build command). Nếu static pack kén
  vì thư mục không có `package.json`, thả 1 `site/Dockerfile` 2 dòng nginx là chắc ăn:
  `FROM nginx:alpine` + `COPY . /usr/share/nginx/html` → đổi Build Pack sang Dockerfile.
- Gắn domain → Coolify tự xin Let's Encrypt (TLS).

**Auto-deploy gọn — điểm mấu chốt:** bật auto-deploy on push, nhưng đặt **Watch Paths = `site/**`**.
Nhờ vậy **chỉ khi landing đổi mới redeploy**; commit engine/app (không đụng `site/`) KHÔNG kích build
thừa. Đây là thứ làm "có update là triển khai luôn" mà không ồn ào.

- Coolify theo dõi **nhánh đang làm `2.0`** cho gọn. *(Nâng cấp sau: lập nhánh `main` làm "nhánh đăng"
  — chỉ merge vào main khi muốn công bố, tách rõ "đang làm" vs "đã lên sóng".)*

**Màu (không có Astro nên vẫn là bản chép trong `:root`):** muốn hết trôi mà không cần build server →
sinh `site/assets/tokens.css` từ `brand/tokens.json` bằng 1 bước `make` (output commit vào repo,
Coolify chỉ việc bày). Giữ đúng "1 nguồn → 3 đích": landing là đích thứ 3, đọc từ cùng tokens.json.
