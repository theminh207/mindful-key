# 04 — Contracts

> Các bất biến **đang có hiệu lực** mà mọi vỏ phải giữ. Khác với [tầng Decisions](03-decisions/):
> ADR ghi lại một lựa chọn trong quá khứ và không sửa nữa; hợp đồng ràng buộc code hiện tại và vi
> phạm nó là **bug**, không phải khác biệt phong cách.
>
> Mỗi hợp đồng ở đây được viết sao cho **soi được bằng `grep`**. Đó là tiêu chuẩn để một luật được
> nhận vào tầng này: nếu không kiểm được bằng máy hoặc bằng một lệnh tìm kiếm, nó thuộc tầng khác.

---

## HĐ-1 — Nhịp thở: đánh giá thì được, chặn thì không

**Ràng buộc.** Hợp đồng `core/mood/BreathingPause.h` chỉ trả lời hai câu: *có nên hiện gì không* và
*hiện câu chữ gì*. Nó **không có, và không được có**, bất kỳ cơ chế nào ngăn hành động gửi.

```cpp
bool BreathingPause_Evaluate(double sendRisk, BreathingPausePrompt* outPrompt);
void BreathingPause_ReportChoice(BreathingPauseChoice choice);
```

- Trả `false` thì vỏ không làm gì cả — không có khung rỗng.
- Trả `true` **không có nghĩa nút gửi bị khóa**. Trách nhiệm giữ ma sát mềm nằm ở phía vỏ: khung chỉ
  được che tạm, lựa chọn "vẫn gửi" phải hoạt động ngay lập tức.
- Hợp đồng thuần C++, không phụ thuộc framework giao diện, để mọi vỏ tự vẽ mà không phải đoán API.

**Vì sao tách riêng khỏi lớp nhắc thụ động.** Nhắc thụ động xảy ra ngay khi gõ xong một câu; gác
cổng xảy ra khi vỏ phát hiện người dùng bấm gửi. Hai khoảnh khắc này dùng chung con số send-risk
nhưng **không được gộp code**, vì giao diện khác nhau và ngưỡng có thể cần tách khi có dữ liệu thật.

**Hạn chế đã biết, không giấu.** Điểm chèn kiểm tra nằm ngay đầu hook, trước khi engine xử lý ký tự
Enter. Nếu từ cuối câu chưa được chốt thì điểm send-risk tại thời điểm đó có thể chưa tính từ đó.
Đây là đánh đổi có chủ đích để không phải đụng vào hơn 900 dòng logic xử lý tiếng Việt.

**Cách soi.** Mọi nơi gọi `BreathingPause_Evaluate` phải nằm sau một bước phát hiện "sắp gửi", không
phải ở mỗi lần chốt từ.

---

## HĐ-2 — Khởi động an toàn

> Ba bất biến áp cho **mọi vỏ**: macOS, Windows, iOS, và Linux sau này.

Hợp đồng này sinh ra sau khi một loại lỗi tái phát **độc lập** qua hai vỏ khác nhau. Trên macOS là
gọi tự tắt ngay trong hàm khởi động xong, khiến hàm dọn dẹp chạm vào một hàng đợi còn rỗng và gây
lỗi bộ nhớ. Trên Windows là mở hộp thoại xin đồng ý ngay trong hàm khởi tạo, trước khi icon khay và
vòng lặp thông điệp tồn tại, khiến hộp thoại mở sau lưng cửa sổ khác và chặn cứng phần còn lại.

Cùng một bệnh: **làm một việc lớn — chặn, modal, tự tắt, hoặc giành quyền — trong lúc khởi động,
trước khi giao diện và vòng lặp và tài nguyên dùng chung được dựng xong.** Cả ba vỏ đều fork từ cùng
bộ khung khởi động nên **thừa hưởng cùng cái bẫy**, và sẽ cứ mỗi vỏ vấp lại một lần nếu không chốt
luật ở một chỗ.

### #1 — Không hành động nặng trước khi ứng dụng dựng xong

Trong đường khởi động, trước khi giao diện, vòng lặp sự kiện và tài nguyên dùng chung tồn tại:
**không** modal chặn, **không** tự thoát, **không** giành quyền, **không** gọi đồng bộ chặn. Cần làm
thì **hoãn ra sau khi launch xong**.

Cách hoãn theo từng vỏ: macOS dùng `dispatch_async` hoặc `dispatch_after`; Windows dùng `PostMessage`
chứ không phải `SendMessage`; iOS không tự tắt được nên tương đương là không chạm tài nguyên chung
trong `viewDidLoad` mà không có guard.

### #2 — Không đường thoát nào được chết câm

Mọi nhánh thoát sớm lúc khởi động phải để lại một dấu vết **người dùng đọc được**. Ứng dụng tiện ích
không cửa sổ mà lặng lẽ biến mất thì người dùng bó tay, tưởng ứng dụng hỏng. "Đúng ý đồ" mà không
nói gì **vẫn là bug**.

Ngoại lệ phải được chốt bằng một quyết định có ghi lại, không phải do bỏ sót.

### #3 — Mọi dọn dẹp phải chịu được trạng thái nửa khởi tạo

Hàm dọn dẹp có thể chạy khi ứng dụng mới dựng một phần. Mọi tài nguyên đụng tới ở đó phải guard
NULL hoặc guard chưa-khởi-tạo.

### Cách soi

```bash
# Hành động nặng trong đường khởi động
grep -nE "terminate|exit\(|_exit|ExitProcess|PostQuitMessage|MessageBox|DialogBox|NSAlert" <vỏ>
```

Mỗi kết quả phải trả lời được ba câu: nó nằm trước hay sau khi ứng dụng dựng xong; nếu là đường
thoát thì có dấu vết đọc được không; nếu là dọn dẹp thì có guard nửa-khởi-tạo không.

---

## HĐ-3 — Hợp đồng send-risk

**Chữ ký ổn định:**

```
câu (chuỗi) → risk (số thực trong [0, 1])
```

Đơn vị là *"gửi đi thì hại tới đâu"*, **không phải** phân loại nhiều nhãn cảm xúc.

Thay cách tính bên trong thì được — lexicon hôm nay, model on-device ngày mai. Đổi chữ ký hoặc đổi ý
nghĩa của con số thì **không**, vì mọi tầng phía sau (nhịp thở, gác cổng, kho dữ liệu, câu chữ) chỉ
tiêu thụ con số này và không quan tâm nó được tính bằng gì.

Kèm theo hai ràng buộc vận hành:

- Phải chạy **ngoài** luồng hook bàn phím. Chặn luồng hook là làm khựng gõ, và trên Windows còn bị
  hệ điều hành âm thầm gỡ hook.
- Khi thay bằng model: đặt **timeout cứng**, vượt timeout thì rơi về lexicon ngay cho câu đó. Model
  lỗi hoặc không tải được cũng rơi về lexicon. Không có nhánh thứ ba, không được crash, không được
  chặn luồng gõ.

---

## HĐ-4 — Copy chuỗi trước khi rời luồng

Callback chốt từ của engine truyền tham chiếu tới một biến sống trên ngăn xếp của luồng gọi. Mọi vỏ
phải **copy sâu** trước khi đẩy sang luồng khác.

Bẫy này đã cắn iOS rồi cắn macOS trước khi thành luật. Quy ước dập tắt nó là đặt **cùng một tên
biến** ở mọi vỏ để một lệnh `grep` soi được cả hai:

```bash
grep -rn "wordCopy" platforms/
```

Đây là lần thứ nhất trong hai lần dự án gặp mô hình "một cái bẫy nhảy giữa các vỏ"; lần thứ hai là
HĐ-2. Cả hai được dập bằng cùng cách: viết luật một lần, đặt tên giống nhau, soi bằng một lệnh.

---

## HĐ-5 — Ranh giới bộ não và vỏ

**Lỗi riêng của một hệ điều hành không bao giờ được sửa trong `core/`.**

`core/engine` và `core/mood` là bộ não dùng chung. Sửa ở đó để vá một vỏ nghĩa là ba vỏ còn lại
nhận thay đổi mà không ai kiểm. Đúng chỗ sửa là `platforms/<os>/`.

**Cách soi.** Mọi thay đổi chỉ nhắm một vỏ phải để lại `git diff core/` **rỗng**. Đây là câu kiểm
được lặp lại trong hầu hết dòng bằng chứng của dự án, và nên tiếp tục như vậy.

Hệ quả kèm theo: khi hai vỏ cần cùng một logic, viết một bản trong `core/` chứ không chép hai bản.
Dự án đã trả giá cho việc này — hai bản từ điển cảm xúc từng trôi lệch nhau, khiến cùng một câu được
cảm nhận khác nhau trên hai hệ điều hành.

---

## HĐ-6 — Không bịa dữ liệu

Áp cho mọi thứ hiển thị cho người dùng về chính họ.

- Nhịp không gõ thì **không ghi mẫu**, khác hẳn với ghi giá trị 0.
- Hai mẫu cách nhau quá 1.5 lần nhịp thì đồ thị **ngắt nét**, không nội suy — quãng rời máy là quãng
  trống thật.
- Không có mẫu nào trong ngày thì câu chữ nói "chưa có nhịp nào", **không** nói "hôm nay êm". Im
  lặng của bàn phím không phải bằng chứng của bình yên.
- Câu xoa dịu chỉ được nói khi dữ liệu thật sự đỡ. Nói bừa cho dịu tai là phán xét trá hình.
- Câu chữ sinh **tất định**: cùng dữ liệu luôn ra cùng câu. Không AI sinh câu, không random.
