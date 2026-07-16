//
//  NotesHistoryMac.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] "Chồng ghi chú" — đọc lại những dòng người dùng đã tự viết (2026-07-16).
//
//  Vì sao tồn tại: `DECISION-daily-note-v1.md` §2.5 chốt "đọc lại được", nhưng v1 hoãn sang "đợt
//  sau" vì cách CHỌN NGÀY là quyết định nhận diện riêng (rất dễ trượt thành lịch/dashboard —
//  HIẾN CHƯƠNG §5.7 cấm). Chủ dự án chốt 2026-07-16: lối đọc lại = **chồng ghi chú, CHỈ ngày CÓ
//  viết**, không phải lịch, không phải mũi tên lùi từng ngày.
//
//  Ràng buộc CỨNG của màn này (đừng "cải tiến" mà phá):
//   · CHỈ hiện ngày CÓ chữ. Ngày không viết KHÔNG được xuất hiện dưới bất kỳ dạng nào — không ô
//     trống, không dấu "—", không khoảng lặng có chú thích. §2.4: "Trống = im lặng". Thấy được
//     chỗ mình bỏ lỡ chính là chuỗi-ngày trá hình.
//   · CẤM đếm: không "N ngày đã ghi", không "chuỗi", không tổng số dòng.
//   · KHÔNG sóng, KHÔNG số đo, KHÔNG điểm. Màn này chỉ có CHỮ NGƯỜI VIẾT + ngày + câu hỏi hôm đó.
//     Đặt sóng cạnh chữ là mời người ta đối chiếu "hôm đó máy chấm mình bao nhiêu" — sai hẳn trục.
//   · CẤM chạy sentiment/model lên nội dung note (§3.5). Màn này chỉ ĐỌC và HIỆN.
//   · Chưa consent ô ghi ⇒ không có gì để đọc ⇒ đừng mở màn, đừng hiện lối vào.
//

#ifndef NotesHistoryMac_h
#define NotesHistoryMac_h

#import <Cocoa/Cocoa.h>   // BOOL — header phải tự đứng vững, không dựa vào thứ tự import ở .mm

#ifdef __cplusplus
extern "C" {
#endif

// Mở màn "Những dòng bạn đã viết". Tự lo trường hợp chưa consent / chưa có dòng nào.
void NotesHistoryMac_Show(void);

// Có ít nhất 1 ghi chú để đọc lại không — dùng để QUYẾT ĐỊNH CÓ HIỆN LỐI VÀO hay không.
// Chưa viết dòng nào ⇒ NO ⇒ lối vào phải biến mất hẳn, không hiện dạng mờ/disabled: một lối vào
// xám ngoét cũng là một lời nhắc "bạn chưa viết gì" (§2.4).
BOOL NotesHistoryMac_HasAnyNote(void);

#ifdef __cplusplus
}
#endif

#endif /* NotesHistoryMac_h */
