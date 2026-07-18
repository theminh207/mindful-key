# Hợp đồng khởi động an toàn (Lifecycle Safety Contract)

> Ba bất biến mà MỌI vỏ (macOS · Windows · iOS · Linux sau này) phải giữ khi khởi động và tắt.
> Sinh ra 2026-07-18 sau khi một loại lỗi tái phát ĐỘC LẬP qua hai vỏ. Cùng khuôn với
> `docs/BREATHING-PAUSE-CONTRACT.md`: viết luật một lần, soi được bằng một `grep` ở mọi vỏ.

## Vì sao có file này

Hai lỗi tưởng khác nhau hoá ra là **một**:

- **macOS (báo cáo 0.2.1, lỗi B):** gọi `[NSApp terminate:]` NGAY TRONG `didFinishLaunching` →
  `applicationWillTerminate` chạm `dispatch_sync` vào một queue CÒN NULL (chưa `MoodWatchMac_Init`)
  → `SIGSEGV @ 0x50`, 4–5 lần.
- **Windows (người dùng thật, 2026-07-18):** `MessageBox` xin consent NGAY TRONG `OpenKeyInit()`,
  trước khi icon khay + vòng lặp thông điệp tồn tại → hộp thoại mở sau lưng cửa sổ khác, chặn cứng
  phần còn lại của khởi động → app "mở rồi biến mất", giữ handle làm bộ cài không xoá được.

Cùng một bệnh: **làm một việc lớn (chặn / modal / tự tắt / giành quyền) TRONG lúc khởi động, trước
khi giao diện + vòng lặp + tài nguyên dùng chung được dựng xong.** Cả ba vỏ đều fork từ cùng bộ
khung khởi động OpenKey (Windows tới giờ còn dùng chung lớp cửa sổ + thứ tự `OpenKeyInit`), nên
chúng **thừa hưởng cùng cái bẫy** và sẽ cứ mỗi vỏ vấp lại một lần nếu không chốt luật một chỗ.

Đây là lần THỨ HAI dự án gặp mô hình "một bẫy nhảy giữa các vỏ": lần trước là `vOnWordCommitted`
trả tham chiếu tới biến cục bộ đã chết — cắn iOS rồi cắn macOS, và được dập tắt bằng đúng cách này:
quy ước `wordCopy` (copy sâu trước khi `dispatch`), đặt TÊN GIỐNG NHAU để một `grep` soi cả hai vỏ.

## Ba bất biến

### #1 — Không hành động nặng trước khi app dựng xong
Trong đường khởi động, TRƯỚC khi giao diện (icon khay / status item / view) + vòng lặp sự kiện +
tài nguyên dùng chung tồn tại: **KHÔNG** modal/hộp thoại chặn, **KHÔNG** tự `terminate`/`exit`,
**KHÔNG** giành quyền (tắt app khác), **KHÔNG** gọi đồng bộ chặn. Cần làm? **Hoãn ra sau khi
launch xong.**
- macOS: `dispatch_async(main_queue, ...)` / `dispatch_after` — vd tự tắt bộ gõ đối thủ
  (`AppDelegate.m`), hỏi consent (`MoodStoreMac_AskConsentIfNeeded` trong `dispatch_async`).
- Windows: `PostMessage` (không `SendMessage`) tới cửa sổ khay để việc chạy trong vòng lặp — vd
  `WM_MK_RIVAL_WARN` cảnh báo bộ gõ đối thủ, `WM_WAVE_ALERT`. Consent hỏi lúc người dùng CHỦ ĐỘNG
  bật (`MoodWatch_Toggle`), không phải trong `OpenKeyInit`.
- iOS: extension không tự tắt được; tương đương là "không chạm App Group / tài nguyên có thể chưa
  sẵn trong `viewDidLoad` mà không guard".

### #2 — Không đường thoát nào được chết câm
MỌI nhánh thoát sớm lúc khởi động (`terminate` / `exit` / `return` / `PostQuitMessage`) PHẢI để lại
một dấu vết NGƯỜI DÙNG ĐỌC ĐƯỢC. App tiện ích không cửa sổ (menu-bar / tray / extension) mà lặng lẽ
biến mất = người dùng bó tay, tưởng app hỏng. "Đúng ý đồ" mà không nói gì vẫn là bug (báo cáo §6.3).
- Đã áp: Windows `win-silent-admin-1` (từ chối UAC → báo rồi thoát), `win-silent-trayfail-1` (không
  tạo được khay → báo rồi thoát).
- Ngoại lệ CÓ CHỦ ĐÍCH, chủ dự án chốt: macOS tự tắt OpenKey khi khởi động là **cố ý im lặng**
  (best-effort notification, không modal — FRICTION-LOG 2026-07-17/18). Ngoại lệ phải được chốt
  bằng quyết định, không phải bỏ sót.

### #3 — Mọi dọn dẹp phải chịu được trạng thái nửa-khởi-tạo
`applicationWillTerminate` / `WM_DESTROY` / `dealloc` / flush có thể chạy khi app MỚI dựng một
phần (chết yểu). Mọi tài nguyên đụng tới ở đó phải guard NULL/chưa-init.
- Đã áp: macOS `MoodWatchMac_Flush()` guard `if (!g_moodQueue) return;` trước `dispatch_sync` —
  đây chính là dòng đã dập lỗi B.

## Cách soi (grep review)

Khi đọc bất kỳ vỏ nào, trước khi coi là xong:
```
# Hành động nặng trong đường khởi động — mỗi hit tự hỏi "trước hay sau khi UI+loop dựng xong?"
grep -nE "terminate|exit\(|_exit|ExitProcess|PostQuitMessage|MessageBox|DialogBox|NSAlert" <vỏ>
# Thoát sớm có để lại dấu vết không?  |  Dọn dẹp có guard NULL không?
```
Mỗi hit phải trả lời được: (a) nó nằm trước hay sau khi app dựng xong (#1); (b) nếu là đường thoát,
có dấu vết đọc được không (#2); (c) nếu là dọn dẹp, có guard nửa-init không (#3).

## Lịch sử
| Ngày | Việc |
|------|------|
| 2026-07-18 | Lập hợp đồng sau audit cross-shell (22 phát hiện, 0 bị bác). Áp #1/#2 cho 3 nhánh Windows + neo #3 vào guard `g_moodQueue` sẵn có của macOS. |
