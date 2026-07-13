# mindful-key — lệnh build/test/release chuẩn hoá.
XCODEPROJ := platforms/apple/MindfulKey.xcodeproj
SCHEME    := MindfulKey
CONFIG    := Debug
DERIVED   := platforms/apple/build
IOS_SIM   ?= iPhone 17
IOS_DD    := build/ios-dd
IOS_APPID := vn.gnh.mindfulkey.ios
VERSION   := $(shell . ./version.env >/dev/null 2>&1; grep '^VERSION=' version.env | cut -d= -f2)

.PHONY: help generate test test-core test-macos test-ios build run run-ios universal brand brand-lint hooks version clean
help:
	@echo "make generate | test | build | run | run-ios | universal | brand | brand-lint | hooks | version | clean   (v$(VERSION))"

generate:        ## Sinh .xcodeproj từ platforms/apple/project.yml (XcodeGen)
	cd platforms/apple && xcodegen generate

test: test-core test-macos test-ios  ## Chạy test cả 3 đội (core + macos + ios)

test-core:       ## Regression engine (bộ não dùng chung, đội core sở hữu)
	bash tests/core/build.sh
	./tests/core/test_engine

test-macos:      ## Test riêng vỏ macOS (đội macOS sở hữu) — chưa có test tự động, no-op
	@echo "tests/macos: chưa có test tự động (xem tests/macos/README.md)"

test-ios:        ## Test riêng vỏ iOS: bridge Telex (host) + mood bridge (host) + build-smoke extension (iphonesimulator)
	bash tests/ios/build.sh
	./tests/ios/bridge_test
	bash tests/ios/mood_bridge_build.sh
	./tests/ios/mood_bridge_test
	bash tests/ios/build_smoke.sh

build: generate  ## Build app macOS (ký ad-hoc)
	xcodebuild -project "$(XCODEPROJ)" -scheme "$(SCHEME)" -configuration "$(CONFIG)" build

run: build       ## Build rồi mở app dev
	xcodebuild -project "$(XCODEPROJ)" -scheme "$(SCHEME)" -configuration "$(CONFIG)" -derivedDataPath "$(DERIVED)" build
	open "$(DERIVED)/Build/Products/$(CONFIG)/"*.app

run-ios: generate  ## Build + cài + mở container app iOS trên Simulator (IOS_SIM="iPhone 17")
	xcodebuild -project "$(XCODEPROJ)" -scheme MindfulKeyiOS -configuration "$(CONFIG)" \
	  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=$(IOS_SIM)' \
	  -derivedDataPath "$(IOS_DD)" CODE_SIGNING_ALLOWED=NO build
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

brand-lint:      ## Ràng buộc nhận diện NOW BRAND OS (chặn đỏ/xanh cảm xúc, emoji chấm điểm, gamification, hardcode màu)
	bash scripts/brand-lint.sh

hooks:           ## Bật git pre-commit chạy brand-lint (mỗi máy chạy 1 lần)
	git config core.hooksPath .githooks
	@echo "✓ đã bật .githooks — pre-commit sẽ chạy brand-lint"

version:
	@echo "$(VERSION)"

clean:
	rm -rf "$(DERIVED)" "$(XCODEPROJ)" tests/core/test_engine
