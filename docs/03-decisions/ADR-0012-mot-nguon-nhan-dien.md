# ADR-0012 — Một nguồn nhận diện, ba đích

- **Trạng thái:** Đã chốt
- **Ngày:** 2026-07-17
- **Liên quan:** `../tasks/BRAND-ASSETS.md`, `../tasks/REPO-TOPOLOGY.md` §4,
  [tầng Conventions §3](../05-conventions.md)

## Bối cảnh

Cùng một bộ màu và dấu ấn phải xuất hiện ở ba nơi: asset nhúng trong từng vỏ, landing page, và mặt
tiền repo công khai. Trước đó mỗi nơi giữ một bản chép tay.

Mô hình "nhiều bản chép tay phải tự nhớ giữ khớp" đã đẻ ra lỗi thật ít nhất hai lần trong dự án: hai
bản từ điển cảm xúc trôi lệch nhau trong ba ngày, và ba lớp gác nhận diện mỗi lớp giữ một danh sách
đuôi tệp riêng — cả ba đều thiếu `.cpp`, nên toàn bộ vỏ Windows chưa từng bị quét dù tài liệu mô tả
đó là ràng buộc cứng.

## Quyết định

`brand/tokens.json` cộng `brand/svg/` là **nguồn duy nhất**. Mọi bản khác được **sinh ra**, không
chép tay.

```
[nguồn]  brand/tokens.json + brand/svg/
             │ make brand · make brand-palette        │ make public-brand
             ▼                                         ▼
   platforms/*/Resources + BrandPalette.h      release-out/public-brand/
   (asset và bảng màu trong app)               (mặt tiền repo công khai)
```

Khóa chống trôi lệch: `make brand-palette-check` báo đỏ theo **cả hai chiều** — sửa nguồn mà quên
sinh lại thì bị bắt, mà sửa tay tệp sinh ra cũng bị bắt. Có bước tương ứng trong CI.

Cùng nguyên tắc đó áp cho danh sách "tệp nào là bề mặt nhận diện": một nguồn duy nhất trong
`scripts/brand_lint.py`, các lớp gác khác **không được giữ danh sách riêng** mà phải hỏi lại nó.

## Đánh đổi đã chấp nhận

Đổi một màu không còn là sửa một dòng — phải sửa nguồn, chạy lại lệnh sinh, và commit cả phần sinh
ra. Đổi màu hoặc dấu ấn trở thành **việc lớn**: bump phiên bản brand, ghi CHANGELOG, chạy lại cả hai
đường sinh để app và mặt tiền không lệch tông.

Chấp nhận vì cái giá của việc trôi lệch cao hơn nhiều, và quan trọng hơn là **im lặng** — không ai
biết cho tới khi một người dùng nhìn thấy hai sắc teal khác nhau trên cùng một cửa sổ.

## Hệ quả

- Không hard-code màu ở bất kỳ vỏ nào. `make brand-lint` cảnh báo khi thấy.
- Landing page là **đích thứ ba**, đọc từ cùng nguồn, không tự chép bảng màu vào CSS.
- Brand chỉ tách thành repo riêng khi có **sản phẩm thứ hai** dùng chung nhận diện này. Lúc đó
  `tokens.json` thành hợp đồng liên dự án. Chưa phải bây giờ.
- Nguyên tắc rộng hơn rút ra từ đây, đã ghi ở [tầng Conventions §3](../05-conventions.md): mỗi loại
  thông tin chỉ được có một nguồn, và mọi bản sao phải sinh ra chứ không chép tay.
