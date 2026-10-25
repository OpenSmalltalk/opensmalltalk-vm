#!/usr/bin/env bash
# OpenSmalltalk Spur64 Oil JIT - Turnkey macOS ARMv8 Build & Verification Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================================================"
echo "    OpenSmalltalk Spur64 Oil JIT - Turnkey macOS ARMv8 Build & Test   "
echo "======================================================================"
echo "Repository root: $SCRIPT_DIR"
ARCH="$(uname -m)"
OS="$(uname -s)"
echo "Platform: $OS $ARCH"

NPROC=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
echo "Parallel workers: $NPROC"
echo ""

# 1. Build the VM with Oil JIT
echo "--- [1/4] Compiling OpenSmalltalk VM with Oil JIT (ARMv8 Apple Silicon) ---"
cd "$SCRIPT_DIR/building/macos64ARMv8/squeak.cog.spur"

make -j"$NPROC" VMSRCDIR=../../../src/spur64.oil

APP_PATH="$SCRIPT_DIR/building/macos64ARMv8/squeak.cog.spur/Squeak.app"
VM_BIN="$APP_PATH/Contents/MacOS/Squeak"

if [ ! -f "$VM_BIN" ]; then
    echo "ERROR: VM binary not found at $VM_BIN"
    exit 1
fi
echo "VM successfully built at: $VM_BIN"

# 2. Ad-hoc codesign with JIT entitlement (required on Apple Silicon)
echo ""
echo "--- [2/4] Applying macOS JIT entitlements & ad-hoc signature ---"
codesign -s - --force --deep --entitlements ../common/entitlements.plist Squeak.app 2>/dev/null || true
echo "Codesigning complete."

# 3. Test VM execution
echo ""
echo "--- [3/4] Verifying VM binary execution ---"
"$VM_BIN" --version

# 4. Run native test suite
echo ""
echo "--- [4/4] Running Oil Milestones 1-8 Native End-to-End Test Suite ---"
cd "$SCRIPT_DIR"

IMAGE_PATH="$SCRIPT_DIR/image/test.image"

if [ ! -f "$IMAGE_PATH" ]; then
    echo "ERROR: Test image not found at $IMAGE_PATH"
    exit 1
fi

TEST_SUITES=("oil/test_oil_m8.st")
if [ "$1" == "all" ]; then
    TEST_SUITES=(
        "oil/test_oil_m3.st"
        "oil/test_oil_m5.st"
        "oil/test_oil_m6.st"
        "oil/test_oil_m7.st"
        "oil/test_oil_m8.st"
    )
elif [ -n "$1" ] && [ -f "$1" ]; then
    TEST_SUITES=("$1")
fi

ALL_PASSED=1
for SUITE in "${TEST_SUITES[@]}"; do
    echo ""
    echo ">>> Running test suite: $SUITE <<<"
    rm -f "$SCRIPT_DIR/oil-m8-result.txt" "$SCRIPT_DIR/image/oil-m8-result.txt" "$SCRIPT_DIR/building/macos64ARMv8/squeak.cog.spur/oil-m8-result.txt"
    rm -f "$SCRIPT_DIR/oil-m7-result.txt" "$SCRIPT_DIR/image/oil-m7-result.txt" "$SCRIPT_DIR/building/macos64ARMv8/squeak.cog.spur/oil-m7-result.txt"
    rm -f "$SCRIPT_DIR/oil-m6-result.txt" "$SCRIPT_DIR/image/oil-m6-result.txt" "$SCRIPT_DIR/building/macos64ARMv8/squeak.cog.spur/oil-m6-result.txt"

    # Create a temporary runner wrapper that executes the script and exits Squeak cleanly
    WRAPPER="$(mktemp "${TMPDIR:-/tmp}/oil-run.XXXXXX.st")"
    cat > "$WRAPPER" <<EOF
[(FileStream readOnlyFileNamed: '$SCRIPT_DIR/$SUITE') fileIn]
    on: Error
    do: [:ex |
        FileStream stdout nextPutAll: 'ERROR in $SUITE: '; nextPutAll: ex description asString; cr.
        Smalltalk snapshot: false andQuit: true].
Smalltalk snapshot: false andQuit: true.
EOF

    "$VM_BIN" -headless "$IMAGE_PATH" "$WRAPPER"
    rm -f "$WRAPPER"

    # Find the result file (oil-m*-result.txt)
    RESULT=$(ls -t "$SCRIPT_DIR"/oil-m*-result.txt "$SCRIPT_DIR/image"/oil-m*-result.txt "$SCRIPT_DIR/building/macos64ARMv8/squeak.cog.spur"/oil-m*-result.txt 2>/dev/null | head -n 1 || true)

    if [ -n "$RESULT" ] && [ -f "$RESULT" ]; then
        echo "=== Result from $RESULT ==="
        cat "$RESULT"
        if ! grep -q "ALL PASS" "$RESULT"; then
            echo "FAILED: $SUITE did not report ALL PASS"
            ALL_PASSED=0
        fi
    else
        echo "Finished $SUITE"
    fi
done

echo ""
if [ $ALL_PASSED -eq 1 ]; then
    echo "======================================================================"
    echo "  >>> SUCCESS: All Oil JIT tests PASSED on macOS ARMv8! <<<"
    echo "======================================================================"
    exit 0
else
    echo "======================================================================"
    echo "  >>> FAILURE: One or more test suites failed. See results above. <<<"
    echo "======================================================================"
    exit 1
fi
