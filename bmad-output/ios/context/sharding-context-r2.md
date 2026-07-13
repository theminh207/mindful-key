# Sharding Context — iOS Round 2 (Epic 2)

> Ngữ cảnh chung cho story-author compile story `2.x`. Đọc file này + `tech-spec-r2.md` TRƯỚC.
> **Track: Quick Flow (mở rộng) · Sizing: 1 dev-day/story.** Output → `bmad-output/ios/stories/2.{story}.{slug}.story.md`.

## Nguồn (đọc để trích dẫn)
- `bmad-output/ios/tech-spec-r2.md` — **nguồn chính**: 6 story (2.1–2.6), AC seed, owned scope, deps, model, và 4 quyết định đã chốt.
- `bmad-output/ios/decision-log.md` (2026-07-13) — Q1/Q2/Q3/Q11 chốt + phương án B (analyzer).
- `bmad-output/ios/EXPERIENCE.md` Future B1 · `analysis/07-functional-requirements/_index.md` (FR-A08/A09/A10/A11/A15a) · `analysis/07-non-functional/_index.md` (NFR).
- `docs/SEND-RISK-MODEL-SPEC.md` (lexicon send-risk) · `core/mood/{MoodBuffer,BreathingPause}.h` · `platforms/apple/macos/MoodWatchMac.mm` (bảng lexicon để rút — approach B).

## Quyết định bake vào mọi story Track B (KHÔNG hỏi lại)
- Q1: biên độ sóng = **ngưỡng chết ~0.3 + dâng mượt** (liên tục, không bậc). Q2: **CHỈ sóng, không chữ**.
- Q3: chuông = **nhắc nghỉ sau N câu căng liên tiếp + cooldown** (mô hình NudgeCoordinator macOS), tùy chọn bật/tắt.
- Q11: **lexicon on-device** (PhoBERT sau). Approach B: analyzer ở `platforms/apple/shared/`, rút lexicon từ `MoodWatchMac.mm`, KHÔNG đụng `core/`.

## RÀNG BUỘC CỨNG (mọi story)
- `core/` ĐÓNG BĂNG — `git diff core/` rỗng. Chỉ sửa `platforms/apple/ios/**`, `platforms/apple/shared/**`, `tests/**`.
- CẤM `platforms/apple/macos/*.mm` (chỉ ĐỌC để rút lexicon, KHÔNG sửa). project.yml chỉ block iOS.
- Hiến chương: KHÔNG đỏ/xanh valence, KHÔNG gamify, copy "mô tả không phán xét". Secure field (`mk_isSecureField`) → không đọc/sóng/chuông. On-device, không network. Model cảm xúc chạy async cuối câu, không chen mạch gõ.

## Learnings R1 (pattern ĐÃ CÓ — tái dùng, đừng dựng lại)
- **Bridge gõ:** `KeyboardBridge_HandleKeyTap/HandleSpace/HandleBackspace` → `applyBridgeResult` (deleteBackward×N + insertText). `EngineKeyMap_CharacterToKeyCode()` tra phím. (story 1.2/1.3)
- **Custom keyboard PHẢI có height constraint** (`self.view.heightAnchor = 260`, priority 999) — thiếu là bàn phím trắng (bug đã vá b5f2eac). Thanh gợi ý story 2.1 cộng thêm vào chiều cao này.
- **Riêng tư:** `-(BOOL)mk_isSecureField` (đọc `textDocumentProxy.secureTextEntry`) là CỔNG — mọi consumer đọc nội dung (MoodBridge story 2.2) PHẢI gọi trước, bỏ qua nếu YES. (story 1.4)
- **App Group:** `AppGroupBridge` (`platforms/apple/shared/`) — chỉ timestamp/bool, không nội dung gõ. Settings đọc/ghi qua đây. (story 1.6)
- **UI onboarding/nhận diện:** `OnboardingUI` (titleLabel/subtitleLabel/primaryCTA/ghostButton), `BrandColorsUIKit` (brandTeal/tealStrong/tealLight/surfacePage), `BrandMarkView` (sóng placeholder). (story 1.7) — dùng lại cho Settings/Track B.
- **Test:** `tests/ios/bridge_test.mm` + `build_smoke.sh` (`make test-ios`). Thêm ca cho tính năng mới, verify bằng `make test` thật (không đoán). `mindful-test-design` skill + `telex-vni-edge-cases.md`.
- Container app = Objective-C. Symbol `.mm`→`.m` cần `FOUNDATION_EXPORT`(extern "C") — pattern repo.

## Phân công story (chi tiết ở tech-spec-r2 §Track A/B — theo đúng owned scope + model ghi ở đó)
| ID | Slug | Track | Model |
|---|---|---|---|
| 2.1 | full-keyboard-suggestion-bar | A | Sonnet |
| 2.2 | moodbridge-send-risk | A | Sonnet (Opus review) |
| 2.3 | keyboard-settings-live-preview | A | Sonnet |
| 2.4 | macro-text-expansion | A | Sonnet |
| 2.5 | emotion-wave-ambient | B | Sonnet + Opus review nhận diện |
| 2.6 | rest-reminder-bell | B | Sonnet + Opus review |

Mỗi story: header (status backlog), Story, AC (LOCKED, đánh số, bake quyết định Q1-Q3 cho 2.5/2.6), Tasks map AC, Dev Notes có `[Source: tech-spec-r2.md#...]`/`[Source: decision-log.md#2026-07-13]` + learnings R1 liên quan, Testing (chiến lược), Dependency Maps (2.5 blocked-by 2.1+2.2; 2.6 blocked-by 2.2), Owned Scope path-precise, Dev Agent Record TRỐNG.
