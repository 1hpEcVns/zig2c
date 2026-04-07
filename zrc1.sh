#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 <file.zig>"
    exit 1
fi

SRC="$1"
BASENAME=$(echo "$SRC" | sed 's/.zig$//')

ZIG_INCLUDE=$(zig env 2>/dev/null | grep 'lib_dir' | sed 's/.*"\(\/[^"]*\)".*/\1/')

echo "Step 1: Zig to C..."
zig build-exe "$SRC" -ofmt=c > "${BASENAME}.c"

echo "Step 2: Compile with LLVM optimizations (O3 + LTO)..."
clang -I"${ZIG_INCLUDE}" -flto -O3 -c "${BASENAME}.c" -o "${BASENAME}.bc" -w 2>/dev/null || \
clang -I"${ZIG_INCLUDE}" -O3 -c "${BASENAME}.c" -o "${BASENAME}.o" -w

echo "Step 3: Extract LLVM IR..."
clang -I"${ZIG_INCLUDE}" -emit-llvm -S -O3 "${BASENAME}.c" -o "${BASENAME}.ll"

echo "Step 4: Optimize with binaryen..."
if command -v wasm-opt &> /dev/null; then
    wasm-opt -O3 "${BASENAME}.ll" -o "${BASENAME}.opt.ll" 2>/dev/null || echo "wasm-opt skipped"
else
    echo "wasm-opt not available"
fi

echo "Step 5: Aggressive minify C code..."
sed -i 's|/\*[^*]*\*\([^/][^*]*\*\)*/| |g' "${BASENAME}.c"
sed -i 's|//.*||g' "${BASENAME}.c"
sed -i 's/[[:space:]]\+/ /g' "${BASENAME}.c"
sed -i '/^$/d' "${BASENAME}.c"
sed -i 's/ \([{};,()]\)/\1/g; s/\([{};,(]\) /\1/g' "${BASENAME}.c"

echo "Step 6: Generate optimized binary artifacts..."
if [ -f "${BASENAME}.o" ]; then
    objdump -d "${BASENAME}.o" > "${BASENAME}.asm" 2>/dev/null
fi

SIZE=$(wc -c < "${BASENAME}.c")
echo "Done! C code: ${BASENAME}.c (${SIZE} bytes, use clang manually to compile)"