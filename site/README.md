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
- **Nút "Tải cho macOS"** → `releases/latest/download/MindfulKey.dmg` — bấm phát tải luôn, không thả
  người dùng vào trang Releases đầy `.zip`/`.dSYM.zip`/`.exe` bắt họ đoán (đối tượng của app không
  phải dev). Link cố định được vì `scripts/release.sh` publish kèm **bản copy tên không đổi**
  `MindfulKey.dmg` bên cạnh bản có version — xem `docs/RELEASE.md`. Đổi repo thì sửa link trong `index.html`.
- **Nút "Tải cho Windows"** → còn là trang Releases + nhãn "sắp có". Bộ cài `MindfulKey-setup.exe`
  (link cố định đối xứng) đã được `release.yml` sinh sẵn, **nhưng chưa bản phát hành nào chứa nó**
  — nối nút vào bây giờ là ra lỗi 404. Đợi tag đầu tiên có Windows publish xong rồi mới nối,
  cùng lúc bỏ nhãn "sắp có".
- ⚠️ Release đăng ở dạng **nháp (draft)** — `releases/latest/download/...` chỉ sống sau khi vào tab
  Releases bấm **Publish**. Nháp chưa publish = nút tải trên web gãy.
- Không webfont, không ảnh ngoài — nhẹ, tự chứa.

## Test tại chỗ
```bash
cd site && python3 -m http.server 8080   # rồi mở http://localhost:8080
```

Chi tiết: `docs/REPO-TOPOLOGY.md §6` · `docs/ROADMAP.md` Giai đoạn 1.
