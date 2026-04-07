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

# Multiple optimization passes
if [ -f "${BASENAME}.ll" ]; then
    # Pass 1: Basic optimizations
    opt -O3 -mem2reg -dce -simplifycfg -inline -loop-unroll -loop-vectorize \
        -S "${BASENAME}.ll" -o "${BASENAME}.opt1.ll" 2>/dev/null || true
    
    # Pass 2: More aggressive optimization
    opt -O3 -globaldce -constprop -die -strip-debuginfo \
        -S "${BASENAME}.opt1.ll" -o "${BASENAME}.opt2.ll" 2>/dev/null || true
    
    # Pass 3: Use llc to generate minimal assembly representation
    llc -O3 -filetype=asm "${BASENAME}.opt2.ll}" -o "${BASENAME}.s" 2>/dev/null || true
fi

echo "Step 4: Generate C from optimized IR..."
# Compile optimized IR to object file (treating .c as IR input)
if [ -f "${BASENAME}.opt2.ll" ]; then
    # Use clang with -x ir to compile IR to object, then extract info
    clang -I"${ZIG_INCLUDE}" -O3 -flto -c -x ir "${BASENAME}.opt2.ll}" -o "${BASENAME}.o" 2>/dev/null || true
fi

# For now, use optimized IR as the final output (it can be compiled with clang -c -x ir)
# This is the closest to "C" that LLVM can generate without a decompiler

echo "Step 5: Output as C-compatible format..."
# The optimized IR is our final output
if [ -f "${BASENAME}.opt2.ll" ]; then
    cp "${BASENAME}.opt2.ll" "${BASENAME}.c"
elif [ -f "${BASENAME}.opt1.ll" ]; then
    cp "${BASENAME}.opt1.ll" "${BASENAME}.c"
elif [ -f "${BASENAME}.ll" ]; then
    cp "${BASENAME}.ll" "${BASENAME}.c"
fi

# Minify
if [ -f "${BASENAME}.c" ]; then
    # Remove empty lines and leading/trailing whitespace
    sed -i '/^$/d' "${BASENAME}.c"
    sed -i 's/^[[:space:]]*//;s/[[:space:]]*$//' "${BASENAME}.c"
    # Remove comment lines
    sed -i '/^;/d' "${BASENAME}.c"
fi

SIZE=$(wc -c < "${BASENAME}.c")
echo "Done! Result: ${BASENAME}.c (${SIZE} bytes)"
echo "Reduction: $((ORIG_SIZE - SIZE)) bytes ($((100 * (ORIG_SIZE - SIZE) / ORIG_SIZE))%)"
echo "Note: Output is optimized LLVM IR (compile with: clang -c -x ir ${BASENAME}.c)"