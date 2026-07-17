# mindful-key — lệnh build/test/release chuẩn hoá.
XCODEPROJ := platforms/apple/MindfulKey.xcodeproj
SCHEME    := MindfulKey
CONFIG    := Debug
DERIVED   := platforms/apple/build

# [MINDFUL] 2026-07-16 — MỘT nơi build, MỘT nơi cài. Trước đây `build` không kèm
# -derivedDataPath (app rơi vào ~/Library/Developer/Xcode/DerivedData/MindfulKey-<hash>/)
# còn `run` thì có (app rơi vào platforms/apple/build/) → 2 bản khác nhau ở 2 nơi, và
# `make clean` chỉ dọn được 1. Hậu quả thật: vá lỗi bằng `make build` rồi mở bản ở đường
# kia = chạy bản CŨ, tưởng đã vá. Xem docs/FRICTION-LOG.md 2026-07-16.
APP_BUILT     := $(DERIVED)/Build/Products/$(CONFIG)/MindfulKey.app
APP_INSTALLED := /Applications/MindfulKey.app
IOS_SIM   ?= iPhone 17
IOS_DD    := build/ios-dd
IOS_APPID := vn.gnh.mindfulkey.ios
VERSION   := $(shell . ./version.env >/dev/null 2>&1; grep '^VERSION=' version.env | cut -d= -f2)

.PHONY: help generate test test-core test-macos test-ios build install run doctor run-ios universal brand public-brand brand-lint hooks version clean
help:
	@echo "make generate | test | build | install | run | doctor | run-ios | universal | brand | public-brand | brand-lint | hooks | version | clean   (v$(VERSION))"
	@echo ""
	@echo "  Vòng lặp dev macOS:  make run     (build → cài /Applications → mở)"
	@echo "  Nghi ngờ chạy nhầm bản:  make doctor"

generate:        ## Sinh .xcodeproj từ platforms/apple/project.yml (XcodeGen)
	cd platforms/apple && xcodegen generate

test: test-core test-macos test-ios  ## Chạy test cả 3 đội (core + macos + ios)

test-core:       ## Regression bộ não dùng chung (đội core sở hữu): engine Telex/VNI + chấm điểm send-risk
	bash tests/core/build.sh
	./tests/core/test_engine
	bash tests/core/send_risk_build.sh
	./tests/core/test_send_risk
	bash tests/core/phrasing_build.sh
	./tests/core/test_phrasing

test-macos:      ## Test riêng vỏ macOS (đội macOS sở hữu): E2E tầng dữ liệu chuỗi nhịp lấy mẫu (gõ→nhịp→ghi→đọc, host, cô lập kho + keychain)
	bash tests/macos/mood_pipeline_build.sh

test-ios:        ## Test riêng vỏ iOS: bridge Telex (host) + mood bridge (host) + settings bridge (host) + emotion wave amplitude (host) + nudge coordinator/chuông nhắc nghỉ (host) + mood journal store (host) + build-smoke extension (iphonesimulator)
	bash tests/ios/build.sh
	./tests/ios/bridge_test
	bash tests/ios/mood_bridge_build.sh
	./tests/ios/mood_bridge_test
	bash tests/ios/settings_bridge_build.sh
	./tests/ios/settings_bridge_test
	bash tests/ios/emotion_wave_build.sh
	./tests/ios/emotion_wave_test
	bash tests/ios/nudge_coordinator_ios_build.sh
	./tests/ios/nudge_coordinator_ios_test
	bash tests/ios/mood_journal_store_build.sh
	./tests/ios/mood_journal_store_test
	bash tests/ios/build_smoke.sh

build: generate  ## Build app macOS (ký ad-hoc) → platforms/apple/build/ (make clean dọn được)
	xcodebuild -project "$(XCODEPROJ)" -scheme "$(SCHEME)" -configuration "$(CONFIG)" -derivedDataPath "$(DERIVED)" build

install: build   ## Thay bản ở /Applications bằng bản vừa build — giữ máy chỉ có ĐÚNG 1 bản
	@pkill -x MindfulKey 2>/dev/null || true
	@sleep 1
	rm -rf "$(APP_INSTALLED)"
	ditto "$(APP_BUILT)" "$(APP_INSTALLED)"
	@echo ""
	@echo "✓ đã cài: $(APP_INSTALLED)  ($(CONFIG))"
	@echo "  ⚠ Bản build mới = chữ ký mới → macOS coi như app lạ và THU HỒI quyền."
	@echo "    Gõ không lên dấu? → System Settings › Privacy & Security ›"
	@echo "    Accessibility + Input Monitoring: tắt/bật lại MindfulKey."

run: install     ## Build + cài + mở — chạy ĐÚNG bản mà Spotlight/Finder sẽ mở
	open "$(APP_INSTALLED)"

doctor:          ## Quét bản MindfulKey.app lạc trên máy (thủ phạm kinh điển của "vá rồi vẫn lỗi")
	@echo "== Bản app trên máy =="
	@find /Applications "$(HOME)/Applications" /Volumes -maxdepth 3 -name "MindfulKey.app" -type d 2>/dev/null \
	  | while read -r p; do printf "  %s\n    build lúc: %s\n" "$$p" "$$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$$p/Contents/MacOS/MindfulKey" 2>/dev/null)"; done
	@echo "== Kho build =="
	@[ -d "$(APP_BUILT)" ] && printf "  %s\n    build lúc: %s\n" "$(APP_BUILT)" "$$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$(APP_BUILT)/Contents/MacOS/MindfulKey" 2>/dev/null)" || echo "  (chưa build)"
	@echo "== DerivedData lạc (đường build CŨ — có bản nào ở đây = tàn dư, xoá được) =="
	@find "$(HOME)/Library/Developer/Xcode/DerivedData" -maxdepth 1 -name "MindfulKey-*" 2>/dev/null | sed 's/^/  /' || true
	@echo "== Đang chạy =="
	@if pgrep -x MindfulKey >/dev/null; then lsof -p $$(pgrep -x MindfulKey) 2>/dev/null | grep -m1 "MacOS/MindfulKey$$" | awk '{print "  "$$NF}'; else echo "  (không chạy)"; fi

run-ios: generate  ## Build + cài + mở container app iOS trên Simulator (IOS_SIM="iPhone 17")
	# KÝ AD-HOC ("-") + KÈM entitlements — KHÔNG dùng CODE_SIGNING_ALLOWED=NO. Lý do: App Group
	# group.vn.gnh.mindfulkey (kho chung app<->keyboard: macro, settings, heartbeat onboarding) chỉ
	# được Simulator cấp phát khi app có chữ ký MANG theo entitlements. Tắt ký hẳn = không có kho
	# chung = macro/onboarding/settings gãy im lặng (đã kiểm chứng 2026-07-13). Ad-hoc đủ cho
	# Simulator, KHÔNG cần Apple Developer Program.
	# ENABLE_DEBUG_DYLIB=NO — Xcode 16+ mặc định tách executable thành vỏ mỏng + .debug.dylib ở
	# Debug. App thường ổn, nhưng tiện ích BÀN PHÍM (app-extension) hay KHÔNG nạp được kiểu tách này
	# → iOS lặng lẽ nhả về bàn phím hệ thống (đã kiểm chứng 2026-07-13). Ép build 1 khối liền.
	xcodebuild -project "$(XCODEPROJ)" -scheme MindfulKeyiOS -configuration "$(CONFIG)" \
	  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=$(IOS_SIM)' \
	  -derivedDataPath "$(IOS_DD)" \
	  CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual \
	  ENABLE_DEBUG_DYLIB=NO \
	  build
	-xcrun simctl boot "$(IOS_SIM)"
	xcrun simctl bootstatus "$(IOS_SIM)" -b
	xcrun simctl install "$(IOS_SIM)" "$$(find $(IOS_DD)/Build/Products -name 'MindfulKeyiOS.app' -maxdepth 3 | head -1)"
	xcrun simctl launch "$(IOS_SIM)" "$(IOS_APPID)"
	open -a Simulator
	@echo ""
	@echo "→ Mindful Key đã mở trên Simulator ($(IOS_SIM))."
	@echo "  Bật bàn phím: Settings › General › Keyboard › Keyboards › Add New Keyboard › Mindful Key"
	@echo "  Rồi: Safari → chạm ô nhập → giữ 🌐 → Mindful Key → gõ 'vieetj' → 'việt'."

universal:       ## Build bản chạy được cả máy chip M lẫn Intel (chưa ký thật, xem scripts/README.md)
	ARCHES="arm64 x86_64" bash scripts/package_app.sh release

brand:           ## Xuất lại brand-asset từ SVG nguồn
	bash brand/export.sh

brand-palette:   ## Sinh lại bảng màu MỌI vỏ (macOS colorset + BrandPalette.h apple/windows) từ brand/tokens.json
	python3 brand/gen-palette.py

brand-palette-check:  ## Báo đỏ nếu bảng màu đã sinh lệch brand/tokens.json (CI chạy cái này)
	python3 brand/gen-palette.py --check

public-brand:    ## Gói bộ nhận diện CÔNG KHAI (tier ③) → release-out/public-brand/ để copy sang repo public
	bash scripts/pack-public-brand.sh

brand-lint:      ## Ràng buộc nhận diện NOW BRAND OS (chặn đỏ/xanh cảm xúc, emoji chấm điểm, gamification, hardcode màu)
	bash scripts/brand-lint.sh

hooks:           ## Bật git pre-commit chạy brand-lint (mỗi máy chạy 1 lần)
	git config core.hooksPath .githooks
	@echo "✓ đã bật .githooks — pre-commit sẽ chạy brand-lint"

version:
	@echo "$(VERSION)"

clean:
	rm -rf "$(DERIVED)" "$(XCODEPROJ)" tests/core/test_engine
