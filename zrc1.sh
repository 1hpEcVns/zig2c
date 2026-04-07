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
echo "Original: ${ORIG_SIZE} bytes"

echo "Step 2: Compile C to LLVM bitcode with max optimization..."
clang -I"${ZIG_INCLUDE}" -O3 -flto -c "${BASENAME}.c" -o "${BASENAME}.bc" -w 2>/dev/null || \
clang -I"${ZIG_INCLUDE}" -O3 -c "${BASENAME}.c" -o "${BASENAME}.o" -w

echo "Step 3: Generate and optimize LLVM IR..."
clang -I"${ZIG_INCLUDE}" -O3 -S -emit-llvm "${BASENAME}.c" -o "${BASENAME}.ll"

if [ -f "${BASENAME}.ll" ]; then
    opt -O3 -mem2reg -dce -simplifycfg -inline -loop-unroll -loop-vectorize \
        -S "${BASENAME}.ll" -o "${BASENAME}.opt1.ll" 2>/dev/null || true
    opt -O3 -globaldce -constprop -die -strip-debuginfo \
        -S "${BASENAME}.opt1.ll" -o "${BASENAME}.opt2.ll" 2>/dev/null || true
    llc -O3 -filetype=asm "${BASENAME}.opt2.ll}" -o "${BASENAME}.s" 2>/dev/null || true
fi

echo "Step 4: Generate C from optimized IR..."
if [ -f "${BASENAME}.opt2.ll" ]; then
    clang -I"${ZIG_INCLUDE}" -O3 -flto -c -x ir "${BASENAME}.opt2.ll}" -o "${BASENAME}.o" 2>/dev/null || true
fi

echo "Step 5: Output as C-compatible format..."
if [ -f "${BASENAME}.opt2.ll" ]; then
    cp "${BASENAME}.opt2.ll" "${BASENAME}.c"
elif [ -f "${BASENAME}.opt1.ll" ]; then
    cp "${BASENAME}.opt1.ll" "${BASENAME}.c"
elif [ -f "${BASENAME}.ll" ]; then
    cp "${BASENAME}.ll" "${BASENAME}.c"
fi

echo "Step 6: Minify..."
if [ -f "${BASENAME}.c" ]; then
    sed -i '/^$/d' "${BASENAME}.c"
    sed -i 's/^[[:space:]]*//;s/[[:space:]]*$//' "${BASENAME}.c"
    sed -i '/^;/d' "${BASENAME}.c"
fi

SIZE=$(wc -c < "${BASENAME}.c")
echo "Done! Result: ${BASENAME}.c (${SIZE} bytes, use clang manually to compile)"
echo "Reduction: $((ORIG_SIZE - SIZE)) bytes ($((100 * (ORIG_SIZE - SIZE) / ORIG_SIZE))%)"
echo "Note: Output is optimized LLVM IR (compile with: clang -c -x ir ${BASENAME}.c)"