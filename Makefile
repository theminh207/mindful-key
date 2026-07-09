# mindful-key — lệnh build/test/release chuẩn hoá.
XCODEPROJ := platforms/apple/MindfulKey.xcodeproj
SCHEME    := MindfulKey
CONFIG    := Debug
DERIVED   := platforms/apple/build
VERSION   := $(shell . ./version.env >/dev/null 2>&1; grep '^VERSION=' version.env | cut -d= -f2)

.PHONY: help generate test build run universal brand version clean
help:
	@echo "make generate | test | build | run | universal | brand | version | clean   (v$(VERSION))"

generate:        ## Sinh .xcodeproj từ platforms/apple/project.yml (XcodeGen)
	cd platforms/apple && xcodegen generate

test:            ## Regression engine (bộ não dùng chung)
	bash tests/engine/build.sh
	./tests/engine/test_engine

build: generate  ## Build app macOS (ký ad-hoc)
	xcodebuild -project "$(XCODEPROJ)" -scheme "$(SCHEME)" -configuration "$(CONFIG)" build

run: build       ## Build rồi mở app dev
	xcodebuild -project "$(XCODEPROJ)" -scheme "$(SCHEME)" -configuration "$(CONFIG)" -derivedDataPath "$(DERIVED)" build
	open "$(DERIVED)/Build/Products/$(CONFIG)/"*.app

universal:       ## Build bản chạy được cả máy chip M lẫn Intel (chưa ký thật, xem scripts/README.md)
	ARCHES="arm64 x86_64" bash scripts/package_app.sh release

brand:           ## Xuất lại brand-asset từ SVG nguồn
	bash brand/export.sh

version:
	@echo "$(VERSION)"

clean:
	rm -rf "$(DERIVED)" "$(XCODEPROJ)" tests/engine/test_engine
