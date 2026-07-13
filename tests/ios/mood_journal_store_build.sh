#!/usr/bin/env bash
# Test tự động cho MoodJournalStore (Round 3, story 3.1: kho nhật ký cảm xúc on-device mã hóa +
# consent) — build + chạy trên HOST macOS, y hệt settings_bridge_build.sh (không cần Simulator).
# MoodJournalStore.mm thuần Foundation + CommonCrypto + Security (không đụng core/engine/core/mood)
# nên không cần link engine sources — nhưng CẦN link -framework Security cho SecItemAdd/
# SecItemCopyMatching/SecRandomCopyBytes (CommonCrypto tự có sẵn qua libSystem, không cần
# -framework riêng, giống MoodStoreMac.mm không khai báo gì thêm cho CommonCrypto).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
SHARED="$ROOT/platforms/apple/shared"

clang++ -std=c++14 -fobjc-arc \
  -I "$SHARED" \
  "$HERE/mood_journal_store_test.mm" "$SHARED/MoodJournalStore.mm" \
  -framework Foundation -framework Security \
  -o "$HERE/mood_journal_store_test"
echo "OK -> $HERE/mood_journal_store_test"
