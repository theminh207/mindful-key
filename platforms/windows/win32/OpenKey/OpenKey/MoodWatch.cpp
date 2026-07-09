//
// MoodWatch.cpp — [MINDFUL] lớp "nghe lén cảm xúc" cho bản Windows.
// Nhận từng từ engine commit -> gom câu gần đây -> đọc cảm xúc (lexicon prototype)
// -> nếu tiêu cực thì hiện popup "nhắc tâm" trên LUỒNG RIÊNG (không làm khựng gõ).
//
// QUAN TRỌNG: OnWord chạy NGAY TRÊN luồng bắt phím toàn hệ thống (low-level hook).
// TUYỆT ĐỐI không file I/O / mạng / chờ ở đây — chỉ quét chuỗi trong RAM; popup đẩy luồng riêng.
//
// Bộ đọc cảm xúc hiện dùng TỪ ĐIỂN 2 TẦNG — sẽ thay bằng model on-device (PhoBERT/ONNX) sau.
//   Tầng 1 (LEX)     : khớp NGUYÊN TỪ (có dấu cách 2 bên) -> an toàn, ít báo nhầm.
//   Tầng 2 (LEX_SUB) : từ tục ĐẶC TRƯNG, khớp DÍNH LIỀN ở bất cứ đâu -> bắt "địtmẹ", "đầubuồi".
// Trước khi dò: bóp gọn ký tự lặp >=3 ("đmmmm"->"đm", "vlllll"->"vl") để bắt kiểu gõ kéo dài.
//
#include "stdafx.h"        // windows.h + Engine.h + OpenKeyHelper.h (APP_SET_DATA)
#include "MoodWatch.h"
#include <vector>
#include <map>

using namespace std;

int vMoodWatch = 1;                    // bật mặc định (nạp lại từ registry lúc khởi động)

static vector<wstring> g_words;
static DWORD g_lastWarn = 0;
static volatile LONG g_popupShowing = 0;

struct Lex { const wchar_t* w; int score; const wchar_t* cat; };

// ============================================================================
// TẦNG 1 — khớp NGUYÊN TỪ (cần dấu cách 2 bên). An toàn, gần như không báo nhầm.
// ============================================================================
static const Lex LEX[] = {
    // ----------------------------------------------------------------- BUỒN
    { L"buồn",-2,L"buồn" },{ L"buồn bã",-2,L"buồn" },{ L"buồn thiu",-2,L"buồn" },{ L"buồn rầu",-2,L"buồn" },
    { L"chán",-2,L"buồn" },{ L"chán nản",-2,L"buồn" },{ L"chán đời",-3,L"buồn" },{ L"chán chường",-2,L"buồn" },
    { L"chán ghét",-2,L"buồn" },{ L"chán ngấy",-2,L"buồn" },{ L"khóc",-2,L"buồn" },{ L"nức nở",-2,L"buồn" },
    { L"nghẹn ngào",-2,L"buồn" },{ L"sụt sùi",-2,L"buồn" },{ L"rưng rưng",-2,L"buồn" },{ L"mít ướt",-1,L"buồn" },
    { L"cô đơn",-2,L"buồn" },{ L"cô độc",-2,L"buồn" },{ L"cô quạnh",-2,L"buồn" },{ L"hiu quạnh",-2,L"buồn" },
    { L"lạc lõng",-2,L"buồn" },{ L"lẻ loi",-2,L"buồn" },{ L"bơ vơ",-2,L"buồn" },{ L"tủi",-2,L"buồn" },
    { L"tủi thân",-2,L"buồn" },{ L"tuyệt vọng",-3,L"buồn" },{ L"vô vọng",-3,L"buồn" },{ L"thất vọng",-2,L"buồn" },
    { L"hụt hẫng",-2,L"buồn" },{ L"trống rỗng",-2,L"buồn" },{ L"trống trải",-2,L"buồn" },{ L"tồi tệ",-2,L"buồn" },
    { L"nản",-2,L"buồn" },{ L"nản lòng",-2,L"buồn" },{ L"nản chí",-2,L"buồn" },{ L"đau",-1,L"buồn" },
    { L"đau lòng",-2,L"buồn" },{ L"đau khổ",-3,L"buồn" },{ L"đau đớn",-2,L"buồn" },{ L"khổ",-2,L"buồn" },
    { L"khổ sở",-2,L"buồn" },{ L"khổ tâm",-2,L"buồn" },{ L"tổn thương",-2,L"buồn" },{ L"xót xa",-2,L"buồn" },
    { L"chua xót",-2,L"buồn" },{ L"đắng lòng",-2,L"buồn" },{ L"nát lòng",-3,L"buồn" },{ L"tan nát",-2,L"buồn" },
    { L"héo hon",-2,L"buồn" },{ L"ủ rũ",-2,L"buồn" },{ L"u sầu",-2,L"buồn" },{ L"sầu",-1,L"buồn" },
    { L"sầu não",-2,L"buồn" },{ L"trầm cảm",-3,L"buồn" },{ L"bi quan",-2,L"buồn" },{ L"tiêu cực",-2,L"buồn" },
    { L"bỏ cuộc",-2,L"buồn" },{ L"buông xuôi",-2,L"buồn" },{ L"gục ngã",-2,L"buồn" },{ L"suy sụp",-3,L"buồn" },
    { L"khủng hoảng",-3,L"buồn" },{ L"bế tắc",-2,L"buồn" },{ L"cùng quẫn",-3,L"buồn" },{ L"lạc lối",-2,L"buồn" },
    { L"vô nghĩa",-2,L"buồn" },{ L"thất bại",-2,L"buồn" },{ L"hối hận",-2,L"buồn" },{ L"ân hận",-2,L"buồn" },
    { L"hối tiếc",-1,L"buồn" },{ L"tiếc nuối",-1,L"buồn" },{ L"dằn vặt",-2,L"buồn" },{ L"day dứt",-2,L"buồn" },
    { L"mất mát",-2,L"buồn" },{ L"nhớ nhung",-1,L"buồn" },{ L"thất tình",-2,L"buồn" },{ L"ngán",-1,L"buồn" },
    { L"ngao ngán",-2,L"buồn" },{ L"đáng thương",-1,L"buồn" },{ L"tội nghiệp",-1,L"buồn" },{ L"muốn chết",-3,L"buồn" },
    { L"không muốn sống",-3,L"buồn" },{ L"chẳng thiết",-2,L"buồn" },{ L"mệt mỏi với đời",-3,L"buồn" },
    // ----------------------------------------------------------------- GIẬN (không tục)
    { L"tức",-2,L"giận" },{ L"tức giận",-3,L"giận" },{ L"tức điên",-3,L"giận" },{ L"tức chết",-3,L"giận" },
    { L"tức anh ách",-2,L"giận" },{ L"tức ói máu",-3,L"giận" },{ L"ói máu",-2,L"giận" },{ L"lộn ruột",-3,L"giận" },
    { L"giận",-2,L"giận" },{ L"giận dữ",-3,L"giận" },{ L"giận dỗi",-2,L"giận" },{ L"nổi giận",-3,L"giận" },
    { L"nóng giận",-3,L"giận" },{ L"nổi điên",-3,L"giận" },{ L"nổi khùng",-3,L"giận" },{ L"phát điên",-3,L"giận" },
    { L"phát khùng",-3,L"giận" },{ L"phát rồ",-3,L"giận" },{ L"phát bực",-2,L"giận" },{ L"điên tiết",-3,L"giận" },
    { L"sôi máu",-3,L"giận" },{ L"phẫn nộ",-3,L"giận" },{ L"phẫn uất",-3,L"giận" },{ L"căm",-2,L"giận" },
    { L"căm ghét",-3,L"giận" },{ L"căm phẫn",-3,L"giận" },{ L"căm hờn",-2,L"giận" },{ L"hậm hực",-2,L"giận" },
    { L"hằn học",-2,L"giận" },{ L"bực",-2,L"giận" },{ L"bực mình",-2,L"giận" },{ L"bực bội",-2,L"giận" },
    { L"bực dọc",-2,L"giận" },{ L"bứt rứt",-1,L"giận" },{ L"bức bối",-2,L"giận" },{ L"cáu",-2,L"giận" },
    { L"cáu gắt",-2,L"giận" },{ L"cáu kỉnh",-2,L"giận" },{ L"gắt",-1,L"giận" },{ L"gắt gỏng",-2,L"giận" },
    { L"quạu",-2,L"giận" },{ L"quạu quọ",-2,L"giận" },{ L"cay cú",-2,L"giận" },{ L"cay",-1,L"giận" },
    { L"hờn",-1,L"giận" },{ L"dỗi",-1,L"giận" },{ L"khó chịu",-2,L"giận" },{ L"khó ở",-1,L"giận" },
    { L"chướng mắt",-2,L"giận" },{ L"gai mắt",-2,L"giận" },{ L"ngứa mắt",-2,L"giận" },{ L"ngứa mồm",-2,L"giận" },
    { L"ghét",-2,L"giận" },{ L"đáng ghét",-2,L"giận" },{ L"ghét cay ghét đắng",-3,L"giận" },{ L"điên",-2,L"giận" },
    { L"khùng",-2,L"giận" },{ L"ức chế",-2,L"giận" },{ L"ức",-1,L"giận" },{ L"uất",-2,L"giận" },
    { L"uất ức",-3,L"giận" },{ L"chịu hết nổi",-3,L"giận" },{ L"hết chịu nổi",-3,L"giận" },{ L"không chịu nổi",-2,L"giận" },
    { L"hết chịu được",-3,L"giận" },{ L"chịu không nổi",-2,L"giận" },{ L"sân si",-2,L"giận" },{ L"cú",-1,L"giận" },
    // ----------------------------------------------------------------- MỆT
    { L"mệt",-1,L"mệt" },{ L"mệt mỏi",-2,L"mệt" },{ L"mỏi mệt",-2,L"mệt" },{ L"mệt lả",-2,L"mệt" },
    { L"mệt rã",-2,L"mệt" },{ L"đuối",-2,L"mệt" },{ L"đuối sức",-2,L"mệt" },{ L"hết sức",-2,L"mệt" },
    { L"hết hơi",-2,L"mệt" },{ L"hết pin",-1,L"mệt" },{ L"kiệt sức",-3,L"mệt" },{ L"kiệt quệ",-3,L"mệt" },
    { L"vắt kiệt",-3,L"mệt" },{ L"rã rời",-2,L"mệt" },{ L"rệu rã",-2,L"mệt" },{ L"bải hoải",-2,L"mệt" },
    { L"phờ phạc",-2,L"mệt" },{ L"bơ phờ",-2,L"mệt" },{ L"uể oải",-2,L"mệt" },{ L"oải",-1,L"mệt" },
    { L"lừ đừ",-1,L"mệt" },{ L"đừ",-1,L"mệt" },{ L"stress",-2,L"mệt" },{ L"căng thẳng",-2,L"mệt" },
    { L"căng",-1,L"mệt" },{ L"áp lực",-2,L"mệt" },{ L"quá tải",-2,L"mệt" },{ L"quá sức",-2,L"mệt" },
    { L"ngộp",-2,L"mệt" },{ L"ngộp thở",-2,L"mệt" },{ L"nghẹt thở",-2,L"mệt" },{ L"đè nặng",-2,L"mệt" },
    { L"gánh nặng",-2,L"mệt" },{ L"cày",-1,L"mệt" },{ L"cày cuốc",-1,L"mệt" },{ L"tăng ca",-1,L"mệt" },
    { L"deadline",-1,L"mệt" },{ L"ngán ngẩm",-2,L"mệt" },{ L"chán ngắt",-1,L"mệt" },{ L"mệt quá",-2,L"mệt" },
    // ----------------------------------------------------------------- LO
    { L"lo",-1,L"lo" },{ L"lo lắng",-2,L"lo" },{ L"lo âu",-2,L"lo" },{ L"lo sợ",-2,L"lo" },
    { L"lo ngại",-2,L"lo" },{ L"lo xa",-1,L"lo" },{ L"sợ",-1,L"lo" },{ L"sợ hãi",-2,L"lo" },
    { L"sợ sệt",-2,L"lo" },{ L"sợ chết khiếp",-2,L"lo" },{ L"khiếp",-1,L"lo" },{ L"khiếp sợ",-2,L"lo" },
    { L"kinh hãi",-2,L"lo" },{ L"kinh hoàng",-3,L"lo" },{ L"hãi",-1,L"lo" },{ L"hãi hùng",-2,L"lo" },
    { L"hoảng",-2,L"lo" },{ L"hoảng sợ",-2,L"lo" },{ L"hoảng loạn",-3,L"lo" },{ L"hốt hoảng",-2,L"lo" },
    { L"bất an",-2,L"lo" },{ L"bất ổn",-2,L"lo" },{ L"hồi hộp",-1,L"lo" },{ L"bồn chồn",-1,L"lo" },
    { L"phấp phỏng",-2,L"lo" },{ L"thấp thỏm",-2,L"lo" },{ L"nơm nớp",-2,L"lo" },{ L"run",-1,L"lo" },
    { L"run rẩy",-2,L"lo" },{ L"rối",-1,L"lo" },{ L"rối bời",-2,L"lo" },{ L"rối trí",-2,L"lo" },
    { L"hoang mang",-2,L"lo" },{ L"hoảng hốt",-2,L"lo" },{ L"áy náy",-1,L"lo" },{ L"băn khoăn",-1,L"lo" },
    { L"trăn trở",-1,L"lo" },{ L"khắc khoải",-2,L"lo" },{ L"ám ảnh",-2,L"lo" },{ L"e ngại",-1,L"lo" },
    { L"ngại",-1,L"lo" },{ L"dè chừng",-1,L"lo" },
    // ----------------------------------------------------------------- TỤC NHẸ / CHỬI THỀ NGUYÊN TỪ
    // (mấy từ tục NẶNG mà hay gõ dính liền -> để TẦNG 2 ở dưới cho khớp được khắp nơi)
    { L"đm",-4,L"giận" },{ L"dm",-4,L"giận" },{ L"đmm",-4,L"giận" },{ L"dmm",-4,L"giận" },
    { L"đcm",-4,L"giận" },{ L"dcm",-4,L"giận" },{ L"đkm",-4,L"giận" },{ L"dkm",-4,L"giận" },
    { L"đcmm",-4,L"giận" },{ L"dkmm",-4,L"giận" },{ L"cmm",-4,L"giận" },{ L"clmm",-4,L"giận" },
    { L"đjt",-4,L"giận" },{ L"đj",-3,L"giận" },{ L"dit",-3,L"giận" },{ L"ditme",-4,L"giận" },
    { L"đụ",-4,L"giận" },{ L"đú",-2,L"giận" },{ L"lồn",-4,L"giận" },{ L"cak",-3,L"giận" },
    { L"kac",-3,L"giận" },{ L"buoi",-3,L"giận" },{ L"dái",-2,L"giận" },{ L"giái",-2,L"giận" },
    { L"cứt",-3,L"giận" },{ L"đéo",-3,L"giận" },{ L"deo",-2,L"giận" },{ L"đếch",-3,L"giận" },
    { L"đách",-3,L"giận" },{ L"đệch",-3,L"giận" },{ L"đệt",-3,L"giận" },{ L"vl",-2,L"giận" },
    { L"vc",-2,L"giận" },{ L"vcđ",-2,L"giận" },{ L"cc",-3,L"giận" },{ L"cl",-3,L"giận" },
    { L"đb",-2,L"giận" },{ L"vãi",-1,L"giận" },{ L"vãi l",-3,L"giận" },{ L"vãi lồn",-4,L"giận" },
    { L"vãi cả lồn",-4,L"giận" },{ L"vãi chưởng",-2,L"giận" },{ L"vãi đái",-2,L"giận" },{ L"vãi nồi",-2,L"giận" },
    { L"vãi cứt",-3,L"giận" },{ L"vãi shit",-2,L"giận" },
    // ----------------------------------------------------------------- CHỬI XÚC PHẠM
    { L"mẹ kiếp",-3,L"giận" },{ L"mịa",-2,L"giận" },{ L"mịe",-2,L"giận" },{ L"mie",-2,L"giận" },
    { L"mả mẹ",-3,L"giận" },{ L"tổ sư",-3,L"giận" },{ L"tổ cha",-3,L"giận" },{ L"sư bố",-3,L"giận" },
    { L"sư cha",-3,L"giận" },{ L"sư nhà mày",-3,L"giận" },{ L"bố mày",-2,L"giận" },{ L"mẹ mày",-2,L"giận" },
    { L"khốn nạn",-3,L"giận" },{ L"khốn kiếp",-3,L"giận" },{ L"đồ khốn",-3,L"giận" },{ L"thằng khốn",-3,L"giận" },
    { L"mất dạy",-3,L"giận" },{ L"vô học",-3,L"giận" },{ L"vô giáo dục",-3,L"giận" },{ L"vô liêm sỉ",-3,L"giận" },
    { L"đểu",-2,L"giận" },{ L"đểu cáng",-3,L"giận" },{ L"đồ đểu",-3,L"giận" },{ L"mặt dày",-2,L"giận" },
    { L"trơ trẽn",-2,L"giận" },{ L"đê tiện",-3,L"giận" },{ L"hèn",-2,L"giận" },{ L"hèn hạ",-3,L"giận" },
    { L"bỉ ổi",-3,L"giận" },{ L"đốn mạt",-3,L"giận" },{ L"táng tận",-3,L"giận" },{ L"đáng khinh",-2,L"giận" },
    { L"khinh bỉ",-2,L"giận" },{ L"đồ chó",-3,L"giận" },{ L"con chó",-3,L"giận" },{ L"thằng chó",-3,L"giận" },
    { L"chó má",-3,L"giận" },{ L"đồ chó má",-3,L"giận" },{ L"óc chó",-3,L"giận" },{ L"não chó",-3,L"giận" },
    { L"óc lợn",-3,L"giận" },{ L"óc bã đậu",-3,L"giận" },{ L"đồ súc vật",-3,L"giận" },{ L"súc vật",-3,L"giận" },
    { L"súc sinh",-3,L"giận" },{ L"đồ giòi",-3,L"giận" },{ L"đồ ngu",-2,L"giận" },{ L"ngu",-2,L"giận" },
    { L"ngu si",-2,L"giận" },{ L"ngu ngốc",-2,L"giận" },{ L"ngu dốt",-2,L"giận" },{ L"ngu như bò",-3,L"giận" },
    { L"ngu như chó",-3,L"giận" },{ L"đần",-2,L"giận" },{ L"đần độn",-2,L"giận" },{ L"dốt",-1,L"giận" },
    { L"dốt nát",-2,L"giận" },{ L"thiểu năng",-3,L"giận" },{ L"tâm thần",-2,L"giận" },{ L"dở hơi",-2,L"giận" },
    { L"hâm",-1,L"giận" },{ L"thằng điên",-2,L"giận" },{ L"con điên",-2,L"giận" },{ L"đồ điên",-2,L"giận" },
    { L"vô dụng",-2,L"giận" },{ L"ăn hại",-2,L"giận" },{ L"đồ ăn hại",-3,L"giận" },{ L"phế vật",-3,L"giận" },
    { L"đồ bỏ đi",-2,L"giận" },{ L"rác rưởi",-3,L"giận" },{ L"cặn bã",-3,L"giận" },{ L"đồ rác",-2,L"giận" },
    { L"chết tiệt",-2,L"giận" },{ L"chết dẫm",-2,L"giận" },{ L"chết đi",-3,L"giận" },{ L"đi chết đi",-3,L"giận" },
    { L"biến",-2,L"giận" },{ L"biến đi",-2,L"giận" },{ L"cút",-3,L"giận" },{ L"cút đi",-3,L"giận" },
    { L"cút xéo",-3,L"giận" },{ L"xéo",-2,L"giận" },{ L"xéo đi",-2,L"giận" },{ L"câm",-2,L"giận" },
    { L"câm mồm",-3,L"giận" },{ L"câm miệng",-3,L"giận" },{ L"im mồm",-3,L"giận" },{ L"im miệng",-2,L"giận" },
    { L"ngậm mồm",-3,L"giận" },{ L"đồ mất nết",-3,L"giận" },{ L"mất nết",-2,L"giận" },{ L"hư hỏng",-2,L"giận" },
    { L"con đĩ",-3,L"giận" },{ L"đĩ điếm",-3,L"giận" },{ L"đĩ thõa",-3,L"giận" },{ L"điếm",-2,L"giận" },
    { L"ghê tởm",-3,L"giận" },{ L"kinh tởm",-3,L"giận" },{ L"tởm",-2,L"giận" },{ L"gớm ghiếc",-2,L"giận" },
    // ----------------------------------------------------------------- TIẾNG ANH (nguyên từ — hay dính chữ khác nên KHÔNG để tầng 2)
    { L"fck",-3,L"giận" },{ L"fuk",-3,L"giận" },{ L"fk",-2,L"giận" },{ L"fu",-2,L"giận" },
    { L"wtf",-3,L"giận" },{ L"omfg",-3,L"giận" },{ L"gtfo",-3,L"giận" },{ L"damn",-2,L"giận" },
    { L"goddamn",-3,L"giận" },{ L"crap",-2,L"giận" },{ L"ass",-2,L"giận" },{ L"jerk",-2,L"giận" },
    { L"idiot",-2,L"giận" },{ L"stupid",-2,L"giận" },{ L"dumb",-2,L"giận" },{ L"moron",-2,L"giận" },
    { L"retard",-3,L"giận" },{ L"suck",-2,L"giận" },{ L"sucks",-2,L"giận" },{ L"dick",-3,L"giận" },
    { L"bastard",-3,L"giận" },{ L"scumbag",-3,L"giận" },{ L"loser",-2,L"giận" },{ L"trash",-2,L"giận" },

    // ----------------------------------------------------------------- TÍCH CỰC (trung hòa câu vui — TRỪ tục nặng)
    { L"vui",2,L"+" },{ L"vui vẻ",2,L"+" },{ L"vui quá",2,L"+" },{ L"hạnh phúc",3,L"+" },{ L"yêu",2,L"+" },
    { L"thích",1,L"+" },{ L"thương",2,L"+" },{ L"tuyệt",2,L"+" },{ L"tuyệt vời",3,L"+" },{ L"tuyệt cú mèo",3,L"+" },
    { L"ổn",1,L"+" },{ L"ổn áp",2,L"+" },{ L"ổn định",1,L"+" },{ L"tạm ổn",1,L"+" },{ L"bình thường",1,L"+" },
    { L"khỏe",1,L"+" },{ L"khỏe re",2,L"+" },{ L"tốt",1,L"+" },{ L"ngon",2,L"+" },{ L"ngon lành",2,L"+" },
    { L"cảm ơn",2,L"+" },{ L"biết ơn",2,L"+" },{ L"trân trọng",2,L"+" },{ L"tự hào",2,L"+" },{ L"bình an",2,L"+" },
    { L"an yên",2,L"+" },{ L"yên tâm",2,L"+" },{ L"yên bình",2,L"+" },{ L"nhẹ nhõm",2,L"+" },{ L"thư giãn",2,L"+" },
    { L"thoải mái",2,L"+" },{ L"dễ chịu",2,L"+" },{ L"hài lòng",2,L"+" },{ L"mãn nguyện",2,L"+" },{ L"mừng",2,L"+" },
    { L"hân hoan",2,L"+" },{ L"phấn khởi",2,L"+" },{ L"hào hứng",2,L"+" },{ L"rộn ràng",2,L"+" },{ L"ấm áp",2,L"+" },
    { L"may mắn",2,L"+" },{ L"đỉnh",2,L"+" },{ L"xịn",2,L"+" },{ L"đẹp",2,L"+" },{ L"sướng",2,L"+" },
    { L"phê",2,L"+" },{ L"chất",2,L"+" },{ L"mê",2,L"+" },{ L"đã đời",2,L"+" },{ L"quá đã",2,L"+" },
    { L"sảng khoái",2,L"+" },{ L"cười",2,L"+" },{ L"haha",2,L"+" },{ L"hihi",1,L"+" },{ L"đáng yêu",2,L"+" },
    { L"dễ thương",2,L"+" },{ L"ok",1,L"+" },{ L"oke",1,L"+" },{ L"okie",1,L"+" },
};

// ============================================================================
// TẦNG 2 — từ tục ĐẶC TRƯNG, khớp DÍNH LIỀN ở BẤT CỨ ĐÂU (không cần dấu cách).
// CHỈ chọn chuỗi gần như không bao giờ nằm trong từ tử tế (tránh báo nhầm).
// LƯU Ý đã CỐ TÌNH BỎ "lồn" (đụng "lồng", "lồng ghép") và "đụ" (đụng "đụng xe") khỏi đây.
// Tất cả đều là tục nặng -> kích hoạt cảnh báo NGAY (hardHit).
// ============================================================================
static const wchar_t* LEX_SUB[] = {
    // Việt
    L"địt", L"cặc", L"buồi", L"đầu buồi", L"đụmá", L"đụmẹ", L"đụcm",
    L"địtmẹ", L"địtmá", L"địtcon", L"địtbà", L"địtcụ", L"địt mẹ", L"địt má", L"địt con",
    L"đụ má", L"đụ mẹ", L"đụ con", L"vcl", L"vkl", L"vlđ", L"vloz", L"vlz", L"vch",
    L"clgt", L"ccgt", L"cmnl", L"vãilồn", L"cáilồn", L"lồnmẹ", L"súcvật", L"khốnnạn",
    // Anh
    L"fuck", L"fucking", L"fucked", L"motherf", L"mothafu", L"shit", L"bullshit",
    L"bitch", L"asshole", L"stfu", L"dickhead",
};

static const wchar_t* warnFor(const wstring& cat) {
    if (cat == L"giận") return L"Câu bạn vừa gõ nghe đang GIẬN.\n\nKhoan gửi đã — lúc nóng giận, tin nhắn rất dễ làm tổn thương rồi khiến mình hối hận.\nThử đặt điện thoại xuống, hít thở 10 giây, rồi hãy quyết định nhé.";
    if (cat == L"buồn") return L"Nghe có vẻ bạn đang BUỒN.\n\nCó chắc muốn gửi ngay không, hay để lòng dịu lại một chút đã?";
    if (cat == L"mệt")  return L"Nghe bạn đang MỆT / căng thẳng.\n\nNghỉ tay vài phút, uống một ngụm nước rồi quay lại nhé.";
    if (cat == L"lo")   return L"Nghe có vẻ bạn đang LO LẮNG.\n\nĐừng vội. Thử viết ra điều đang khiến mình lo — gọi tên nó ra thường thấy nhẹ hơn.";
    return L"Trạng thái đang hơi tiêu cực. Dừng một nhịp, hít thở rồi tiếp tục nhé.";
}

static DWORD WINAPI msgThread(LPVOID p) {
    wstring* msg = (wstring*)p;
    MessageBoxW(NULL, msg->c_str(), L"Nhắc tâm  -  Mindful Keyboard",
                MB_OK | MB_ICONINFORMATION | MB_TOPMOST | MB_SETFOREGROUND);
    delete msg;
    InterlockedExchange(&g_popupShowing, 0);
    return 0;
}

// Bóp gọn ký tự lặp >=3 lần về 1 ("đmmmm"->"đm", "vlllll"->"vl", "nguuu"->"ngu").
// Giữ nguyên cặp đôi (2 lần) để không phá "stress", "good"...
static wstring collapseRuns(const wstring& in) {
    wstring out;
    out.reserve(in.size());
    size_t i = 0;
    while (i < in.size()) {
        wchar_t c = in[i];
        size_t j = i;
        while (j < in.size() && in[j] == c) j++;
        size_t run = j - i;
        if (run >= 3) out += c;            // >=3 -> còn 1
        else out.append(run, c);          // 1 hoặc 2 -> giữ nguyên
        i = j;
    }
    return out;
}

void MoodWatch_OnWord(const wstring& word) {
    if (!vMoodWatch) return;                 // user đã tắt nhận diện cảm xúc
    if (word.empty()) return;
    g_words.push_back(word);
    if (g_words.size() > 15) g_words.erase(g_words.begin());

    // Ghép câu -> HẠ CHỮ THƯỜNG (CharLowerBuffW lo cả tiếng Việt có dấu) -> BÓP ký tự lặp.
    wstring s = L" ";
    for (size_t i = 0; i < g_words.size(); i++) { s += g_words[i]; s += L" "; }
    if (s.size() > 1) CharLowerBuffW(&s[0], (DWORD)s.size());
    s = collapseRuns(s);

    int total = 0;
    bool hardHit = false;                    // tục nặng -> báo ngay dù câu lẫn từ vui
    map<wstring, int> negByCat;

    // --- TẦNG 1: khớp nguyên từ (có dấu cách 2 bên) ---
    for (size_t i = 0; i < sizeof(LEX) / sizeof(LEX[0]); i++) {
        wstring needle = wstring(L" ") + LEX[i].w + L" ";
        if (s.find(needle) != wstring::npos) {
            total += LEX[i].score;
            if (LEX[i].score < 0) negByCat[LEX[i].cat] += -LEX[i].score;
            if (LEX[i].score <= -4) hardHit = true;
        }
    }
    // --- TẦNG 2: từ tục đặc trưng, khớp dính liền khắp nơi ---
    for (size_t i = 0; i < sizeof(LEX_SUB) / sizeof(LEX_SUB[0]); i++) {
        if (s.find(LEX_SUB[i]) != wstring::npos) {
            total += -4;
            negByCat[L"giận"] += 4;
            hardHit = true;
        }
    }

    if (total >= 0 && !hardHit) return;      // không tiêu cực, và không có tục nặng -> bỏ qua

    DWORD now = GetTickCount();
    if (g_lastWarn != 0 && (now - g_lastWarn) < 15000) return;
    if (InterlockedCompareExchange(&g_popupShowing, 1, 0) != 0) return;
    g_lastWarn = now;

    wstring top; int best = 0;
    for (map<wstring, int>::iterator it = negByCat.begin(); it != negByCat.end(); ++it)
        if (it->second > best) { best = it->second; top = it->first; }

    wstring* msg = new wstring(warnFor(top));
    HANDLE h = CreateThread(NULL, 0, msgThread, msg, 0, NULL);
    if (h) CloseHandle(h);
    else { delete msg; InterlockedExchange(&g_popupShowing, 0); }
    g_words.clear();
}

void MoodWatch_Toggle() {
    APP_SET_DATA(vMoodWatch, !vMoodWatch);   // đảo + lưu registry
    if (!vMoodWatch) g_words.clear();
}

void MoodWatch_Init() {
    vOnWordCommitted = MoodWatch_OnWord;
}
