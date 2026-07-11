// test_engine.cpp
// Harness build-thử: chứng minh "bộ não" OpenKey gõ tiếng Việt được trên WSL (Linux),
// và mô phỏng "màn hình ảo" — chính là chỗ sau này lớp cảm xúc sẽ nghe lén.
//
// Build: xem build.sh (cần -DLINUX để engine ăn platforms/linux.h).

#include <cstdio>
#include <string>
#include <vector>
#include <map>
#include "Engine.h"   // kéo theo DataType.h -> platforms/linux.h

using namespace std;

// ── 1. Các biến cấu hình mà "vỏ" PHẢI định nghĩa (Engine.h chỉ khai báo extern) ──
int vLanguage = 1;            // 1 = tiếng Việt
int vInputType = 0;           // 0 = Telex
int vFreeMark = 0;
int vCodeTable = 0;           // 0 = Unicode dựng sẵn
int vSwitchKeyStatus = 0;
int vCheckSpelling = 1;
int vUseModernOrthography = 1;
int vQuickTelex = 0;
int vRestoreIfWrongSpelling = 1;
int vFixRecommendBrowser = 0;
int vUseMacro = 0;
int vUseMacroInEnglishMode = 0;
int vAutoCapsMacro = 0;
int vUseSmartSwitchKey = 0;
int vUpperCaseFirstChar = 0;
int vTempOffSpelling = 0;
int vAllowConsonantZFWJ = 0;
int vQuickStartConsonant = 0;
int vQuickEndConsonant = 0;
int vRememberCode = 0;
int vOtherLanguage = 1;
int vTempOffOpenKey = 0;

// ── 2. ASCII -> mã phím Linux (lấy từ platforms/linux.h) ──
static map<char, Uint16> KEYMAP = {
    {'a',KEY_A},{'b',KEY_B},{'c',KEY_C},{'d',KEY_D},{'e',KEY_E},{'f',KEY_F},
    {'g',KEY_G},{'h',KEY_H},{'i',KEY_I},{'j',KEY_J},{'k',KEY_K},{'l',KEY_L},
    {'m',KEY_M},{'n',KEY_N},{'o',KEY_O},{'p',KEY_P},{'q',KEY_Q},{'r',KEY_R},
    {'s',KEY_S},{'t',KEY_T},{'u',KEY_U},{'v',KEY_V},{'w',KEY_W},{'x',KEY_X},
    {'y',KEY_Y},{'z',KEY_Z},
    {'1',KEY_1},{'2',KEY_2},{'3',KEY_3},{'4',KEY_4},{'5',KEY_5},
    {'6',KEY_6},{'7',KEY_7},{'8',KEY_8},{'9',KEY_9},{'0',KEY_0},
    {' ',KEY_SPACE},{'.',KEY_DOT},{',',KEY_COMMA},
    {'\b',KEY_DELETE},   // sentinel: '\b' trong chuỗi runCase = bấm phím ⌫ (xóa lùi)
};

// ── 3. codepoint -> UTF-8 ──
static string toUtf8(unsigned int cp) {
    string s;
    if (cp < 0x80) s += (char)cp;
    else if (cp < 0x800) { s += (char)(0xC0|(cp>>6)); s += (char)(0x80|(cp&0x3F)); }
    else { s += (char)(0xE0|(cp>>12)); s += (char)(0x80|((cp>>6)&0x3F)); s += (char)(0x80|(cp&0x3F)); }
    return s;
}

// ── 4. "Màn hình ảo": lưu các codepoint đang hiển thị ──
static vector<unsigned int> screen;
static vKeyHookState* st = nullptr;
static int gFail = 0;   // đếm ca sai — để make test THẬT SỰ đỏ được (CI mới gate được)

// giải mã 1 phần tử charData (chế độ Unicode, vCodeTable=0) — y hệt logic vỏ Win/Mac
static unsigned int decodeChar(Uint32 t) {
    if (t & PURE_CHARACTER_MASK) return t & 0xFFFF;
    if (!(t & CHAR_CODE_MASK))   return keyCodeToCharacter(t); // mã phím thô -> tra bảng
    return t & 0xFFFF;                                          // đã là Unicode
}

static string screenStr() {
    string s; for (auto cp : screen) s += toUtf8(cp); return s;
}

// gõ 1 ký tự ASCII, mô phỏng đúng cách vỏ diễn giải HookState
static void typeChar(char c) {
    auto it = KEYMAP.find(c);
    if (it == KEYMAP.end()) return;
    Uint16 keycode = it->second;

    vKeyHandleEvent(vKeyEvent::Keyboard, vKeyEventState::KeyDown, keycode, 0, false);

    if (st->code == vDoNothing) {
        // ⌫: engine trả vDoNothing (tự lùi buffer nội bộ), KHÔNG báo qua backspaceCount —
        // vỏ phải tự xóa 1 ký tự trên màn hình (mirror KeyboardBridge.mm vDoNothing+KEY_DELETE).
        if (keycode == KEY_DELETE) {
            if (!screen.empty()) screen.pop_back();
        } else {
            screen.push_back((unsigned int)c);       // phím đi thẳng ra app
        }
    } else if (st->code == vWillProcess || st->code == vRestore ||
               st->code == vRestoreAndStartNewSession) {
        for (int i = 0; i < st->backspaceCount; i++)  // xóa lùi
            if (!screen.empty()) screen.pop_back();
        for (int i = st->newCharCount - 1; i >= 0; i--) // ký tự mới (charData xếp ngược)
            screen.push_back(decodeChar(st->charData[i]));
        if (st->code == vRestore || st->code == vRestoreAndStartNewSession) {
            unsigned int kc = keyCodeToCharacter(keycode);
            if (kc) screen.push_back(kc);
        }
        if (st->code == vRestoreAndStartNewSession) startNewSession();
    }
    // vReplaceMaro / vBreakWord: bỏ qua cho bài test gõ thường
}

static void runCase(const char* telex, const char* expect) {
    screen.clear();
    startNewSession();
    for (const char* p = telex; *p; ++p) typeChar(*p);

    string got = screenStr();
    bool ok = (got == expect);
    if (!ok) gFail++;
    printf("  gõ Telex: %-22s -> \"%s\"   [mong đợi: \"%s\"]  %s\n",
           telex, got.c_str(), expect, ok ? "✅" : "❌ SAI");

    // 🎧 Đây chính là chỗ lớp cảm xúc sẽ "nghe lén": câu hoàn chỉnh nằm sẵn ở đây.
    printf("       └─ [MoodBuffer nghe được]: \"%s\"\n", got.c_str());
}

int main() {
    st = (vKeyHookState*)vKeyInit();

    printf("=== BUILD-THỬ ENGINE OPENKEY TRÊN WSL (Telex -> Unicode) ===\n\n");
    runCase("xin chaof cacs banj", "xin chào các bạn");
    runCase("tieengs vieetj",      "tiếng việt");
    runCase("tooi ddang vui",      "tôi đang vui");
    runCase("tooi ddang buoonf",   "tôi đang buồn");
    runCase("hoom nay meejt quas", "hôm nay mệt quá");

    // ── Ca biên bổ sung (ma trận Telex — skill mindful-test-design) ──
    // Kỳ vọng dưới đây được VERIFY bằng chính make test (engine là trọng tài),
    // không chép từ trí nhớ. Ca PROBE (undo) chạy để đọc hành vi engine thật rồi khóa.
    printf("\n--- Loại 1: nguyên âm/phụ âm biến hình ---\n");
    runCase("nawm", "năm");                 // aw -> ă
    runCase("hown", "hơn");                 // ow -> ơ
    runCase("tuw",  "tư");                  // uw -> ư
    printf("\n--- Loại 2: dấu thanh ---\n");
    runCase("as", "á");                     // sắc
    runCase("af", "à");                     // huyền
    printf("\n--- Loại 3: undo (PROBE — đọc output engine rồi khóa) ---\n");
    runCase("dddi", "ddi");                 // gõ modifier đ lần 2 = trả chữ gốc?
    runCase("ass",  "as");                  // gõ thanh sắc lần 2 = bỏ dấu + trả 's'?
    printf("\n--- Loại 8: xen tiếng Anh (SmartSwitchKey OFF) ---\n");
    runCase("hello", "hello");              // không bỏ dấu bừa vào từ Anh

    printf("\n--- Loại 6: backspace / sửa giữa từ (⌫ = '\\b') ---\n");
    runCase("vieetj\b",   "việ");           // gõ "việt" rồi ⌫ 1 lần → bỏ 't'
    // ⚠️ QUIRK (đã verify, khóa làm mốc): sau ⌫ về rỗng qua 1 âm tiết CÓ DẤU, biến hình aw→ă
    // KHÔNG tái kích hoạt → "nawm" ra thô "nawm" (không phải "năm"). Xem docs/FRICTION-LOG.md.
    runCase("as\b\bnawm", "nawm");          // á, ⌫⌫ về rỗng, gõ "nawm" → engine không transform lại
    runCase("tooi\bs",    "tố");            // "tôi", ⌫ bỏ 'i' → "tô", rồi 's' (sắc) → "tố" (đúng)

    if (gFail == 0)
        printf("\n=== XONG — TẤT CẢ PASS ===\n");
    else
        printf("\n=== XONG — %d CA SAI (make test sẽ đỏ) ===\n", gFail);
    return gFail == 0 ? 0 : 1;   // exit code != 0 để CI/make gate được khi có regression
}
