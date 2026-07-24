#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

OS="${1:-linux}"
ARCH="${2:-x86_64}"
NATIVE_DIR="$PROJECT_DIR/build/generated-resources/native/$OS-$ARCH"

case "$OS" in
    linux)   NATIVE_LIB="libtidesdb_jni.so" ;;
    macos)   NATIVE_LIB="libtidesdb_jni.dylib" ;;
    windows) NATIVE_LIB="tidesdb_jni.dll" ;;
    *) echo "Unknown OS: $OS"; exit 1 ;;
esac

LIB_PATH="$NATIVE_DIR/$NATIVE_LIB"
if [ ! -f "$LIB_PATH" ]; then
    echo "ERROR: Native library not found: $LIB_PATH"
    exit 1
fi

echo "=== Verifying: $LIB_PATH ==="

case "$OS" in
    linux)
        echo ""
        echo "--- ldd output ---"
        ldd "$LIB_PATH"

        echo ""
        echo "--- Checking for forbidden dynamic deps ---"
        FORBIDDEN=("libtidesdb" "libzstd" "liblz4" "libsnappy" "libs3" "libcurl" "libssl" "libcrypto")
        LDD_OUT=$(ldd "$LIB_PATH" 2>&1)
        for dep in "${FORBIDDEN[@]}"; do
            if echo "$LDD_OUT" | grep -qi "$dep"; then
                echo "FAIL: Forbidden dynamic dependency detected: $dep"
                exit 1
            fi
        done
        echo "PASS: No forbidden dynamic dependencies."

        echo ""
        echo "--- readelf -d (NEEDED entries) ---"
        readelf -d "$LIB_PATH" | grep 'NEEDED' || echo "(no NEEDED entries)"

        # RPATH/RUNPATH check
        echo ""
        echo "--- RPATH/RUNPATH check ---"
        if readelf -d "$LIB_PATH" | grep -qiE '(RPATH|RUNPATH).*(/tmp|/home|/build|/vcpkg)'; then
            echo "FAIL: Suspicious RPATH/RUNPATH entry detected."
            exit 1
        fi
        echo "PASS: No suspicious RPATH/RUNPATH entries."
        ;;

    macos)
        echo ""
        echo "--- otool -L ---"
        otool -L "$LIB_PATH"
        FORBIDDEN=("tidesdb" "zstd" "lz4" "snappy" "homebrew" "opt/" "Cellar")
        OTOOL_OUT=$(otool -L "$LIB_PATH" 2>&1)
        for dep in "${FORBIDDEN[@]}"; do
            if echo "$OTOOL_OUT" | grep -qi "$dep"; then
                echo "FAIL: Forbidden dynamic dependency detected: $dep"
                exit 1
            fi
        done
        echo "PASS: No forbidden dynamic dependencies."
        ;;

    windows)
        echo ""
        echo "--- dumpbin /DEPENDENTS ---"
        dumpbin /DEPENDENTS "$LIB_PATH" 2>/dev/null || \
            llvm-objdump -p "$LIB_PATH" 2>/dev/null | grep -i "DLL Name" || \
            echo "(dumpbin/llvm-objdump not available — manual check needed)"
        ;;
esac

echo ""
echo "=== Native verification complete: $LIB_PATH ==="
