# 05 — Conventions

> Lối viết code và làm việc trong dự án. Tầng này lo *cách viết*; điều gì đúng hay sai về bản chất
> thuộc [tầng Intent](01-intent.md), điều gì bắt buộc phải giữ thuộc [tầng Contracts](04-contracts.md).

## 1. Ngôn ngữ

**Định danh tiếng Anh, hiển thị tiếng Việt.** Mọi thứ máy đọc — tên biến, hàm, file, khóa cấu hình,
cột dữ liệu, hằng số, nhánh git — luôn tiếng Anh, kể cả khi sản phẩm phục vụ người dùng Việt. Chỉ
chữ hiện ra cho người dùng mới tiếng Việt.

| Đối tượng | Ngôn ngữ |
|---|---|
| Code, comment trong code, commit message | Tiếng Anh |
| Tên biến, hàm, file, khóa cấu hình, cột dữ liệu | Tiếng Anh |
| Chuỗi hiển thị, nhãn nút, thông báo | Tiếng Việt |
| Tài liệu trong `docs/` | Tiếng Việt, thuật ngữ kỹ thuật giữ tiếng Anh |

Chuỗi giao diện phải tách khỏi code, mặc định tiếng Việt, sẵn sàng cho tiếng Anh.

## 2. Cấu trúc mã nguồn

```
core/engine/        bộ não xử lý tiếng Việt, dùng chung mọi hệ điều hành
core/mood/          lớp cảm xúc, dùng chung mọi hệ điều hành
platforms/apple/    vỏ macOS + iOS + phần dùng chung của hai vỏ này
platforms/windows/  vỏ Windows
platforms/android/  vỏ Android
platforms/linux/    vỏ Linux
brand/              nguồn nhận diện duy nhất
tests/              test theo tầng: core, macos, ios
scripts/            đóng gói, ký, phát hành
site/              landing page tĩnh
```

Toàn bộ nền tảng nằm trong **một monorepo**. Lý do và điều kiện để tách sau này:
[ADR-0002](03-decisions/ADR-0002-monorepo-mot-bo-nao-nhieu-vo.md).

Ranh giới bộ não và vỏ là hợp đồng cứng — xem [HĐ-6](04-contracts.md).

## 3. Nguồn sự thật duy nhất

Mỗi loại thông tin chỉ được có **một** nguồn. Mọi bản sao phải được **sinh ra**, không chép tay.

| Thông tin | Nguồn duy nhất | Bản sinh ra |
|---|---|---|
| Số phiên bản | `version.env` | Info.plist, VERSIONINFO, tên asset |
| Màu, font, hình khối, thang mood | `brand/tokens.json` | colorset macOS, `BrandPalette.h` các vỏ, CSS landing |
| Icon và asset nhận diện | `brand/svg/` | `.icns`, `.ico`, PNG, mipmap Android |
| Cấu hình project Xcode | `platforms/apple/project.yml` | `.xcodeproj` sinh bằng XcodeGen |

Hệ quả: **không commit `.xcodeproj`**, không hard-code màu ở bất kỳ vỏ nào, không chép tay bảng màu.
Có cổng `make brand-palette-check` báo đỏ khi bản sinh lệch nguồn — kiểm cả hai chiều, sửa nguồn mà
quên sinh lại cũng bị bắt, sửa tay file sinh ra cũng bị bắt.

## 4. Cổng chất lượng

Một việc chỉ được coi là **xong** khi mọi cổng dưới đây xanh. Dự án không có `tsc`, `ESLint` hay
`vitest` — đây là bộ cổng tương đương cho stack C++ và Objective-C.

```bash
make test          # regression bộ não + vỏ macOS + vỏ iOS
make build         # build app macOS, ký ad-hoc
make brand-lint    # 0 vi phạm nhận diện
```

Cộng thêm CI: `.github/workflows/macos.yml`, `windows.yml`, `brand-lint.yml` phải xanh.

**Debt delta phải bằng 0.** Số lỗi, cảnh báo và test hỏng không được tăng so với mốc trước khi làm.
Cách đo đúng: `make clean` rồi build hai lượt — một lượt trước khi sửa, một lượt sau — vì cache
incremental build từng làm sai lệch phép đo này.

Những việc **tính là để lại nợ**, đều bị cấm:

- Che cảnh báo compiler bằng ép kiểu ẩu hoặc `#pragma` bịt, thay vì sửa gốc.
- Bỏ chạy `make test` vì "logic không đổi".
- Sửa `core/` để vá lỗi riêng một hệ điều hành.
- Để lại `TODO`, `FIXME`, `#if 0`, hoặc code chết trong file đã commit.

Quy tắc gọn: nếu sửa X mà đẻ ra Y thì sửa Y trước khi commit. Một commit sạch hơn hai commit bừa.

## 5. Sửa như phẫu thuật

Mọi dòng trong diff phải truy được về đúng yêu cầu đang làm.

- Không "tiện tay cải thiện" code, comment hay format bên cạnh. Không refactor thứ không hỏng.
- Không xóa hoặc sửa comment và code chưa hiểu đủ, kể cả khi nó trông thừa.
- Khớp style code hiện có, kể cả khi có lối viết khác được ưa hơn.
- Code chết **có sẵn** thì báo lại, không tự xóa. Rác do **chính thay đổi này** đẻ ra — import,
  biến, hàm mồ côi — thì tự dọn sạch.

## 6. Git

- **Conventional Commits**: `feat`, `fix`, `chore`, `docs`, `refactor`. Kèm phạm vi khi rõ:
  `feat(windows): ...`.
- **SemVer**, bump trong `version.env` cùng lần phát hành, cập nhật `CHANGELOG.md` kèm theo.
- Commit thoải mái như điểm lưu. **Push chỉ khi có yêu cầu rõ ràng** trong lượt ngay trước — im
  lặng, câu hỏi chưa trả lời, lời than, hay chấp thuận cũ cho commit khác đều không tính là đồng ý.
- Trước mỗi lần push: chạy đủ bộ cổng ở mục 4 tại máy. Sau khi push: chờ CI xanh, không giả định
  "push xong là ổn".
- Bật hook nhận diện một lần mỗi máy: `make hooks`.

## 7. Test

Bốn mức bằng chứng và ý nghĩa từng mức: [tầng 02](02-features.md). Nguyên tắc kèm theo:

- **Verify chứ đừng đoán.** Số kỳ vọng trong test lấy từ lần chạy thật hoặc từ nguồn đối chiếu,
  không tự nghĩ ra cho khớp.
- **Kiểm cổng đỏ.** Một test chưa từng đỏ là một test chưa chứng minh được gì. Bẻ một assert, xác
  nhận nó fail, rồi trả lại.
- **Ghi bằng chứng thật.** Cột bằng chứng trong `tasks/TEST_MATRIX.md` phải trỏ tới thứ có thật:
  file test, lệnh chạy, output. Hành vi ghi `implemented` mà bằng chứng để trống là một khoản nợ.
- Mọi thay đổi engine phải có test hồi quy. Không sửa engine mù.

## 8. Xử lý điều chưa biết

- Nêu giả định ra rõ ràng trước khi code. Không chắc thì verify từ nguồn — đọc code, chạy thử, đọc
  tài liệu — hoặc hỏi chủ dự án. **Không bịa "giá trị mặc định hợp lý".**
- Thấy một biên an toàn đang được thêm vào — nới khoảng cho chắc, tăng timeout cho yên tâm, số liệu
  tự chế — nghĩa là **chưa hiểu nguyên nhân gốc**. Dừng lại và đào tiếp. Không tìm ra thì nói thẳng
  "chưa biết X, cần verify từ Y".
- Một yêu cầu có nhiều cách hiểu thì nêu các cách hiểu ra, **không tự chọn trong im lặng**.
- Mỗi lần phải suy diễn vì thiếu luật hoặc thiếu nguồn sự thật thì ghi một dòng vào
  `tasks/FRICTION-LOG.md`. Đó là hàng đợi việc "nên viết luật tiếp theo".
