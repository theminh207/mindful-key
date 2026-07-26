# ADR-0002 — Một monorepo cho mọi nền tảng

- **Trạng thái:** Đã chốt
- **Ngày:** không ghi lại ngày cụ thể
- **Liên quan:** `../tasks/REPO-TOPOLOGY.md`, [HĐ-5](../04-contracts.md)

## Bối cảnh

Câu hỏi đặt ra khi chuẩn bị mở nhánh mobile: iOS và Android nên nằm chung repo hay tách riêng.

Kiến trúc sản phẩm là *"một bộ não, nhiều vỏ"* — engine tiếng Việt và lớp cảm xúc dùng chung cho mọi
hệ điều hành, chỉ tầng vỏ khác nhau.

## Quyết định

**Mọi nền tảng nằm trong một monorepo**, kể cả iOS và Android.

```
core/{engine,mood}/        một bộ não C++ dùng chung
platforms/apple/{macos,ios}/
platforms/{windows,android,linux}/
brand/                     một nguồn nhận diện
```

## Đánh đổi đã chấp nhận

Repo lớn hơn, và mỗi lần đụng vào phải phân biệt rõ ranh giới bộ não với vỏ — kỷ luật đó phải tự
giữ, không có ranh giới vật lý nào ép.

Đổi lại, tách repo sẽ buộc phải chọn một trong hai điều tệ hơn: nhân đôi bộ não, hoặc kéo nó qua
submodule và gánh thuế điều phối phiên bản chéo. Cả hai đều phá đúng mục tiêu "không fork logic gõ".

## Hệ quả

- Đổi màu ở `brand/tokens.json` một chỗ thì mọi vỏ thấy ngay.
- Ranh giới bộ não và vỏ trở thành **hợp đồng cứng** thay vì ranh giới thư mục: lỗi riêng một hệ
  điều hành không được sửa trong `core/`, và mọi thay đổi nhắm một vỏ phải để `git diff core/` rỗng.
- Vỏ khác nhau **được phép** có tập tính năng khác nhau. Chung repo là để chia sẻ cái chia sẻ được,
  không phải để ép mọi vỏ giống nhau.

## Khi nào xét lại

Khi một nền tảng có **đội riêng và nhịp phát hành riêng**, và chi phí điều phối một repo lớn hơn lợi
ích code chung. Kể cả lúc đó, engine vẫn chia sẻ qua package chứ không fork.
