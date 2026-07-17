//
//  MoodPhrasing.cpp
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ)
//
//  Logic + câu chữ RÚT NGUYÊN XI từ platforms/apple/macos/MoodPhrasingMac.mm (chuẩn hành vi).
//  Không diễn giải lại, không "cải tiến" — mọi khác biệt so với bản macOS đều là lỗi của file này.
//
#include "MoodPhrasing.h"

#include <ctime>

using namespace std;

namespace {

enum TimeOfDay { Morning = 0, Noon, Afternoon, Evening, TimeOfDayCount };

// localtime KHÔNG an toàn đa luồng (nó trả con trỏ tới bộ đệm tĩnh dùng chung). Hàm này bị gọi
// từ luồng nền của cả 3 vỏ -> phải dùng bản có bộ đệm riêng. MSVC là localtime_s (đảo tham số so
// với POSIX), phần còn lại là localtime_r.
bool LocalTime(long long epochSeconds, struct tm* out) {
    time_t t = (time_t)epochSeconds;
#ifdef _WIN32
    return localtime_s(out, &t) == 0;
#else
    return localtime_r(&t, out) != nullptr;
#endif
}

TimeOfDay TimeOfDayOf(long long epochSeconds) {
    struct tm lt;
    if (!LocalTime(epochSeconds, &lt))
        return Evening;
    int hour = lt.tm_hour;
    if (hour >= 5 && hour < 11)  return Morning;
    if (hour >= 11 && hour < 13) return Noon;
    if (hour >= 13 && hour < 18) return Afternoon;
    return Evening;
}

// Tên buổi dạng NGẮN để ghép vào câu ("Sáng và chiều có gợn"), khác dạng dài "buổi sáng" dùng khi
// đứng một mình ("Mặt hồ gợn nhiều nhất vào buổi sáng").
const wchar_t* ShortLabel(TimeOfDay t) {
    switch (t) {
        case Morning:   return L"sáng";
        case Noon:      return L"trưa";
        case Afternoon: return L"chiều";
        default:        return L"tối";
    }
}

// Chỉ cần hoa hoá 4 chữ cái đầu có thể gặp: s/t/c (sáng/trưa/tối/chiều). Không dùng bảng hạ-hoa
// tiếng Việt đầy đủ của SendRiskAnalyzer vì ở đây đầu vào là hằng chuỗi của chính file này.
wstring CapitalizeFirst(const wstring& s) {
    if (s.empty()) return s;
    wstring out = s;
    if (out[0] >= L'a' && out[0] <= L'z')
        out[0] = (wchar_t)(out[0] - 32);
    return out;
}

// Nối kiểu người nói: "sáng" · "sáng và chiều" · "sáng, trưa và chiều".
wstring JoinNatural(const vector<const wchar_t*>& parts) {
    if (parts.empty()) return L"";
    if (parts.size() == 1) return parts[0];
    wstring head;
    for (size_t i = 0; i + 1 < parts.size(); i++) {
        if (i) head += L", ";
        head += parts[i];
    }
    return head + L" và " + parts.back();
}

}  // namespace

wstring MoodPhrasingCore_TimeOfDayLabel(long long epochSeconds) {
    switch (TimeOfDayOf(epochSeconds)) {
        case Morning:   return L"buổi sáng";
        case Noon:      return L"buổi trưa";
        case Afternoon: return L"buổi chiều";
        default:        return L"buổi tối";
    }
}

wstring MoodPhrasingCore_DayShapeSentence(const vector<MoodSample>& todaySamples,
                                      double rippleThreshold) {
    if (todaySamples.empty()) {
        // Thật thà: chưa có gì thì nói chưa có gì. KHÔNG suy ra "hôm nay êm" từ chỗ không có dữ
        // liệu — im lặng của bàn phím không phải bằng chứng của sự bình yên.
        return L"Chưa có nhịp nào hôm nay";
    }

    bool rippled[TimeOfDayCount] = { false, false, false, false };
    size_t calmCount = 0;
    for (size_t i = 0; i < todaySamples.size(); i++) {
        if (todaySamples[i].value >= rippleThreshold)
            rippled[TimeOfDayOf(todaySamples[i].ts)] = true;
        else
            calmCount++;
    }

    vector<const wchar_t*> names;
    for (int i = 0; i < TimeOfDayCount; i++) {
        if (rippled[i])
            names.push_back(ShortLabel((TimeOfDay)i));
    }

    if (names.empty())
        return L"Hôm nay tới giờ vẫn êm";

    wstring s = CapitalizeFirst(JoinNatural(names)) + L" có gợn";
    // "phần lớn êm" chỉ nói khi ĐÚNG là phần lớn — nói bừa cho dịu tai là phán xét trá hình, và
    // sai sự thật thì người dùng mất tin vào mọi câu khác của app.
    if (calmCount * 2 > todaySamples.size())
        s += L", phần lớn êm";
    return s;
}

MoodDayShape MoodPhrasingCore_DayShapeOf(double peakAmp, int gatekeeperCount,
                                         double rippleThreshold) {
    // Gác cổng đã phải dừng ít nhất 1 lần = bằng chứng mạnh nhất về ngày đó, thắng mọi thứ khác.
    if (gatekeeperCount > 0) return MoodDayShapeGated;
    if (peakAmp >= rippleThreshold) return MoodDayShapeRippled;
    return MoodDayShapeCalm;
}

wstring MoodPhrasingCore_ReflectionQuestion(MoodDayShape shape, int index) {
    static const wchar_t* kGated[] = {
        L"Có lúc bạn dừng lại trước khi gửi. Lúc đó trong người bạn đang có gì?",
        L"Điều gì đang thật sự nằm sau những lúc căng hôm nay — mệt, áp lực, hay điều gì khác?",
        L"Nếu ngày mai gặp lại đúng tình huống đó, bạn muốn mình phản ứng khác đi thế nào?",
        L"Nhìn lại, khoảng dừng đó đã đổi được gì — hay không đổi gì cả?",
    };
    static const wchar_t* kRippled[] = {
        L"Có lúc mặt hồ gợn lên hôm nay — bạn còn nhớ mình đang làm gì lúc đó không?",
        L"Cơn gợn hôm nay đến từ đâu — người, việc, hay chỉ là mệt?",
        L"Sau lúc gợn nhất, điều gì đã giúp bạn lắng lại?",
        L"Nếu ngày mai gợn lên đúng như vậy, bạn muốn mình để ý điều gì sớm hơn?",
    };
    static const wchar_t* kCalm[] = {
        L"Hôm nay mặt hồ khá phẳng. Điều gì đã giữ cho ngày nhẹ như vậy?",
        L"Ngày êm cũng đáng nhìn lại: hôm nay bạn đã làm gì khác với những ngày căng?",
        L"Có điều gì của hôm nay bạn muốn giữ lại cho ngày mai không?",
        L"Khi ngày trôi êm, bạn thường đang ở cùng ai, làm việc gì?",
    };
    const wchar_t** pool = kCalm;
    if (shape == MoodDayShapeGated)       pool = kGated;
    else if (shape == MoodDayShapeRippled) pool = kRippled;
    if (index < 0) index = -index;
    return pool[index % 4];   // cả 3 rổ đều 4 câu
}
