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
ORIG_SIZE=$(wc -c < "${BASENAME}.c")
echo "Original C: ${ORIG_SIZE} bytes"

echo "Step 2: Compile with LLVM optimizations to get reduced IR..."
clang -I"${ZIG_INCLUDE}" -O3 -flto -c "${BASENAME}.c" -o "${BASENAME}.bc" -w 2>/dev/null || \
clang -I"${ZIG_INCLUDE}" -O3 -c "${BASENAME}.c" -o "${BASENAME}.o" -w

echo "Step 3: Generate LLVM IR from optimized bitcode..."
if [ -f "${BASENAME}.bc" ]; then
    llvm-dis "${BASENAME}.bc" -o="${BASENAME}.ll" 2>/dev/null || true
fi

echo "Step 4: Optimize IR..."
if [ -f "${BASENAME}.ll" ]; then
    opt -O3 "${BASENAME}.ll" -o "${BASENAME}.opt.ll" 2>/dev/null || true
fi

echo "Step 5: Generate minimal C from optimized bitcode..."
clang -I"${ZIG_INCLUDE}" -O3 -flto -S -emit-c "${BASENAME}.bc" -o "${BASENAME}.c" 2>/dev/null || true

echo "Step 6: Apply C-level minification..."
if [ -f "${BASENAME}.c" ]; then
    sed -i 's|/\*[^*]*\*\([^/][^*]*\*\)*/| |g' "${BASENAME}.c"
    sed -i 's|//.*||g' "${BASENAME}.c"
    sed -i 's/[[:space:]]\+/ /g' "${BASENAME}.c"
    sed -i '/^$/d' "${BASENAME}.c"
    sed -i 's/ \([{};,()=]\)/\1/g; s/\([{};,(=]\) /\1/g' "${BASENAME}.c"
fi

SIZE=$(wc -c < "${BASENAME}.c")
echo "Done! Result: ${BASENAME}.c (${SIZE} bytes, use clang manually to compile)"
echo "Reduction: $((ORIG_SIZE - SIZE)) bytes ($((100 * (ORIG_SIZE - SIZE) / ORIG_SIZE))%)"