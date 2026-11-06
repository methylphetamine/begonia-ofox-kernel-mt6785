#!/usr/bin/env bash
# MT6785 Kernel Builder - Using Clang 15
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
OUT_DIR="${OUT_DIR:-$BUILD_DIR/out}"
PATCH_DIR="${PATCH_DIR:-$ROOT_DIR/patches}"

export CC="${CC:-clang-15}"
export CXX="${CXX:-clang++-15}"
export AR="${AR:-llvm-ar-15}"
export NM="${NM:-llvm-nm-15}"
export OBJCOPY="${OBJCOPY:-llvm-objcopy-15}"
export OBJDUMP="${OBJDUMP:-llvm-objdump-15}"
export STRIP="${STRIP:-llvm-strip-15}"
export LD="${LD:-ld.lld-15}"

log() { printf '\033[1;32m[*] %s\033[0m\n' "$*"; }
err() { printf '\033[1;31m[-] %s\033[0m\n' "$*"; }

verify_toolchain() {
    if ! command -v $CC >/dev/null 2>&1; then
        err "ERROR: Clang not found"
        exit 1
    fi
    $CC --version | head -1
}

main() {
    verify_toolchain
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUT_DIR"
    
    log "Generating kernel configuration (begonia_user_defconfig)..."
    make begonia_user_defconfig ARCH=arm64 CC="$CC" CLANG_TRIPLE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 2>&1 | tail -5 || true
    
    scripts/config --disable COMPAT 2>/dev/null || true
    scripts/config --disable CC_STACKPROTECTOR_STRONG 2>/dev/null || true
    scripts/config --disable CC_STACKPROTECTOR 2>/dev/null || true
    
    log "Running olddefconfig..."
    make olddefconfig ARCH=arm64 CC="$CC" CLANG_TRIPLE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 2>&1 | tail -5
    
    JOBS=$(nproc)
    log "Building kernel Image.gz with $JOBS jobs..."
#!/usr/bin/env bash
# MT6785 Kernel Builder - Using standard Linux cross-compiler
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
OUT_DIR="${OUT_DIR:-$BUILD_DIR/out}"
PATCH_DIR="${PATCH_DIR:-$ROOT_DIR/patches}"

export CC="${CC:-aarch64-linux-gnu-gcc}"
export CXX="${CXX:-aarch64-linux-gnu-g++}"
export AR="${AR:-aarch64-linux-gnu-ar}"
export LD="${LD:-aarch64-linux-gnu-ld}"
export AS="${AS:-aarch64-linux-gnu-as}"
export NM="${NM:-aarch64-linux-gnu-nm}"

log() { printf '\033[1;32m[*] %s\033[0m\n' "$*"; }
err() { printf '\033[1;31m[-] %s\033[0m\n' "$*"; }

verify_toolchain() {
    if ! $CC --target=aarch64-linux-gnu -v >/dev/null 2>&1; then
        err "ERROR: Cross-compiler does not support aarch64-linux-gnu target"
        err "This is required for MT6785 kernel build (Linux target, not Android)"
        exit 1
    fi
}

main() {
    verify_toolchain
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUT_DIR"
    
    log "Generating kernel configuration (begonia_user_defconfig)..."
    make begonia_user_defconfig ARCH=arm64 CC="$CC" CROSS_COMPILE=aarch64-linux-gnu- 2>&1 | tail -5 || true
    
    scripts/config --disable COMPAT 2>/dev/null || true
    scripts/config --disable CC_STACKPROTECTOR_STRONG 2>/dev/null || true
    scripts/config --disable CC_STACKPROTECTOR 2>/dev/null || true
    
    log "Running olddefconfig..."
    make olddefconfig ARCH=arm64 CC="$CC" CROSS_COMPILE=aarch64-linux-gnu- 2>&1 | tail -5
    
    JOBS=$(nproc)
    log "Building kernel Image.gz with $JOBS jobs..."
    make -j$JOBS Image.gz ARCH=arm64 CC="$CC" CROSS_COMPILE=aarch64-linux-gnu- 2>&1
    
    log "Verifying build output..."
    ls -la arch/arm64/boot/
    
    if [[ -f arch/arm64/boot/Image.gz ]]; then
        echo ""
        log "✅ Kernel build successful!"
    else
        err "❌ Kernel build failed - Image.gz not found"
        exit 1
    fi
}

main "$@"
    
    log "Verifying build output..."
    ls -la arch/arm64/boot/
    
    if [[ -f arch/arm64/boot/Image.gz ]]; then
        echo ""
        log "✅ Kernel build successful!"
    else
        err "❌ Kernel build failed - Image.gz not found"
        exit 1
    fi
}

main "$@"