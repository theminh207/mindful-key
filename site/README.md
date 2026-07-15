# site/ — Landing page mindful-key

Trang giới thiệu **tĩnh** (1 file `index.html`, không build, không framework). Bám brand
NOW BRAND OS (`brand/tokens.json`). Deploy bằng **Coolify** nhà trồng.

## Deploy (Coolify)
- Nối Git repo → **Base Directory:** `site`
- **Build Pack:** Static — hoặc **Dockerfile** (file `Dockerfile` nginx kèm đây) cho chắc ăn.
- **Watch Paths:** `site/**` — chỉ redeploy khi landing đổi, commit app không kích build thừa.
- **Branch:** `main` · gắn domain → Coolify tự xin TLS (Let's Encrypt).

## Nội dung
- Hero sóng nước (canvas, phản ứng con trỏ), demo "gác cổng" (bấm Gửi → nhịp thở), thang biên độ An→Cuộn.
- Nút tải → GitHub Releases (`releases/latest/download/MindfulKey.dmg`). Đổi repo thì sửa link trong `index.html`.
- Không webfont, không ảnh ngoài — nhẹ, tự chứa.

## Test tại chỗ
```bash
cd site && python3 -m http.server 8080   # rồi mở http://localhost:8080
```

Chi tiết: `docs/REPO-TOPOLOGY.md §6` · `docs/ROADMAP.md` Giai đoạn 1.
