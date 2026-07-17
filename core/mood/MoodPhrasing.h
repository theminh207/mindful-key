//
//  MoodPhrasing.h
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ: macOS · iOS · Windows)
//
//  [MINDFUL] Đọc HÌNH DẠNG một ngày rồi kể lại thành câu. Quan sát, KHÔNG phán xét.
//
//  VÌ SAO Ở ĐÂY (2026-07-17): logic này sinh ra ở `platforms/apple/macos/MoodPhrasingMac.mm`, và
//  chính comment trong file đó đã tự cảnh báo — nó được gom về một chỗ vì "giữ bản chép riêng là
//  sắp có 3 bản trôi lệch nhau". Đội macOS đã tự vấp bài học đó và tự sửa. Nhưng nó dừng ở ranh
//  giới vỏ macOS, nên vỏ Windows tới lượt mình lại phải chép — thành đúng cái vừa đi sửa.
//  Đây là lần THỨ BA dự án gặp mô hình này (lexicon send-risk, bảng màu brand, nay là câu chữ).
//  Nay: logic + chữ ở đây, vỏ chỉ bọc lại theo API chuỗi của mình.
//
//  RÀNG BUỘC HIẾN CHƯƠNG (đừng "cải tiến" mất):
//  - Không có mẫu nào -> nói THẲNG là chưa có, KHÔNG suy ra "hôm nay êm". Im lặng của bàn phím
//    không phải bằng chứng của sự bình yên.
//  - "phần lớn êm" CHỈ nói khi đúng là phần lớn. Nói bừa cho dịu tai là phán xét trá hình, và sai
//    sự thật một lần thì người dùng hết tin mọi câu khác của app.
//  - Mô tả THỜI ĐIỂM trong ngày, KHÔNG mô tả độ lớn bằng số (DESIGN.md §1.2/§2.2 "KHÔNG nhãn số").
//
#ifndef MoodPhrasing_h
#define MoodPhrasing_h

#include <string>
#include <vector>

// Tiền tố `MoodPhrasingCore_` chứ không `MoodPhrasing_`: vỏ macOS phơi ra hàm CÙNG TÊN nhưng
// trả NSString (MoodPhrasingMac.h). C++ không cho hai hàm trùng tên khác kiểu trả về, nên bản
// core mang tên riêng và vỏ BỌC lại nó.

// Một điểm trên dòng sông: thời điểm + biên độ đã chuẩn hoá [0,1].
struct MoodSample {
    long long ts = 0;      // epoch giây
    double    value = 0.0; // biên độ 0..1 (KHÔNG phải valence — không có tốt/xấu ở đây)
};

// Ranh giới buổi — NGUỒN DUY NHẤT: sáng 5-11 · trưa 11-13 · chiều 13-18 · tối 18-24.
// PHẢI khớp `kAxisHour*` đang đặt nhãn trục dòng sông (EmotionRiverView.mm bên macOS). Đổi ở đây
// mà quên bên đó là câu chữ và trục thời gian nói ngược nhau trên cùng một màn hình.
// Dạng DÀI ("buổi sáng") — dùng khi đứng một mình.
std::wstring MoodPhrasingCore_TimeOfDayLabel(long long epochSeconds);

// Kể hình dạng ngày: "Chưa có nhịp nào hôm nay" · "Hôm nay tới giờ vẫn êm" ·
// "Sáng và chiều có gợn" · "Sáng, trưa và chiều có gợn, phần lớn êm".
//
// `rippleThreshold` TRUYỀN VÀO chứ không tự đọc: ngưỡng đến từ độ nhạy người dùng chọn, mà cài đặt
// nằm ở registry (Windows) / UserDefaults (Apple) — `core/` không được biết tới hai thứ đó. Vỏ đọc
// rồi đưa vào. Vỏ PHẢI đưa đúng ngưỡng đang dùng cho chuông, không thì chuông và câu chữ nói ngược
// nhau về cùng một ngày.
std::wstring MoodPhrasingCore_DayShapeSentence(const std::vector<MoodSample>& todaySamples,
                                           double rippleThreshold);

#endif /* MoodPhrasing_h */
