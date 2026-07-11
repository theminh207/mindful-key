# Definition of Done cho test — "test coi là xong khi nào"

> Adapt từ "Definition of Done" trong Anh Tester testing-kit (bản gốc cho Playwright/Selenium) →
> sang bối cảnh mindful-key (`make test` engine C++ + `xcodebuild` macOS/iOS, không browser).
> Khớp cổng **Zero-Technical-Debt** trong `mindful-key/CLAUDE.md`.

## ✅ Cổng bắt buộc (mọi thay đổi engine/mood)
- [ ] `make test` XANH — 0 case fail (regression bộ não C++). Đây là trọng tài, không phải trí nhớ.
- [ ] `make build` / `xcodebuild` sạch — 0 error, **KHÔNG thêm warning mới** so với baseline.
- [ ] CI `.github/workflows/macos.yml` xanh (chạy đúng `make test` + `xcodebuild` Debug).
- [ ] **Debt delta = 0** — số error/warning/fail không tăng so với trước task.

## ✅ Chất lượng ca test
- [ ] Test data **cụ thể**, không placeholder: `"tieengs vieetj" → "tiếng việt"`, KHÔNG "gõ chuỗi hợp lệ".
- [ ] Kỳ vọng đã **verify bằng chạy thật**, không chép từ trí nhớ (xem `telex-vni-edge-cases.md`).
- [ ] Có ca biên, không chỉ happy path — ít nhất phủ đúng "loại nhập" đang đụng (dấu/biến hình/backspace/xen Anh-Việt).
- [ ] Mỗi ca độc lập — không phụ thuộc thứ tự chạy (harness `runCase` đã `startNewSession` mỗi ca — giữ vậy).
- [ ] Tái dùng 5 ca gốc làm mỏ neo, ca mới không mâu thuẫn chúng.

## ✅ Riêng cho test iOS (khi có — Round 2+) — chống chập chờn (flaky)
- [ ] Test phụ thuộc RAM/lifecycle extension: **PASS ổn định ≥ 2 lần liên tiếp** (ý "flaky" của kit gốc).
- [ ] KHÔNG sleep cứng chờ mood async — chờ **tín hiệu debounce hoàn tất**, không delay cố định.
- [ ] Đo RAM extension bằng Instruments, ghi kết quả vào `tests/ios/README.md` (chưa assert tự động được — hành vi OS).

## ✅ Bất biến hiến chương (không được vỡ)
- [ ] `git diff core/` **rỗng** — không sửa bộ não để vá riêng 1 OS.
- [ ] Ô mật khẩu: không đọc/log/hiện sóng (test cả điều KHÔNG được xảy ra).
- [ ] 0 network call mang nội dung gõ; App Group chỉ timestamp/bool.
- [ ] Báo cáo test **mô tả, không gamify**: PASS/FAIL/SKIP + lý do; KHÔNG điểm/streak/xếp hạng/mã màu đỏ-xanh cảm xúc.

## ✅ Dọn dẹp trước khi commit
- [ ] Không để `printf` debug tạm, không code chết, không `// TODO`/`#if 0` trong file đã commit.
- [ ] Rác do chính thay đổi tạo ra (case mồ côi, biến thừa) → tự dọn.
- [ ] Ghi ca đã chứng minh vào `docs/TEST_MATRIX.md`; chỗ phải đoán → `docs/FRICTION-LOG.md`.

## Báo cáo cuối (mẫu, giọng mô tả)
```
Test summary:
- make test: 8/8 PASS (5 gốc + 3 ca mới Loại 6 backspace)
- xcodebuild: sạch, 0 warning mới
- Ca mới đã verify bằng make test, đã khóa regression
- git diff core/: rỗng ✅
```

---
*Adapt từ Anh Tester testing-kit (MIT). Bản gốc cho web automation — đã dịch sang C++/ObjC + hiến chương mindful-key.*
