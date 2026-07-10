# tests/core/

**Sở hữu:** đội core — bộ não C++ dùng chung (`core/engine`, `core/mood`). Đây là DÙNG CHUNG, đội macOS/iOS không tự ý sửa file trong thư mục này; đụng logic engine phải qua đội core.

**Chạy:** `make test-core` (hoặc `make test` chạy chung cả core/macos/ios).

**Nội dung:** `test_engine.cpp` — harness tự viết (không dùng framework test), case hard-code trong `main()`. `build.sh` biên dịch `test_engine.cpp` cùng nguồn `core/engine/*.cpp` qua `-I`.
