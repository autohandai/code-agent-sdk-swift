#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(dirname "$SCRIPT_DIR")
MODULE_CACHE=${SWIFTPM_MODULECACHE_OVERRIDE:-"$PROJECT_DIR/.build/swift-module-cache"}
CLANG_CACHE=${CLANG_MODULE_CACHE_PATH:-"$PROJECT_DIR/.build/clang-module-cache"}

cd "$PROJECT_DIR"
SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE" \
  swift build -c release --disable-sandbox --product agent-sdk-benchmark
BIN_DIR=$(SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE" CLANG_MODULE_CACHE_PATH="$CLANG_CACHE" \
  swift build -c release --disable-sandbox --show-bin-path)
FIXTURE="$BIN_DIR/agent-sdk-benchmark-fixture"
cc -O2 -Wall -Wextra -Werror Benchmarks/fixture.c -o "$FIXTURE"
"$BIN_DIR/agent-sdk-benchmark" "$FIXTURE"
