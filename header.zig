const EOF: u8 = 0;

var buf: [1 << 20]u8 = undefined;
var len: usize = 0;
var idx: usize = 0;

var mem: [1 << 16]u8 = undefined;
var mem_idx: usize = 0;

pub fn bufAlloc(size: usize) *u8 {
    const ptr = &mem[mem_idx];
    mem_idx += size;
    return ptr;
}

fn readByte() u8 {
    if (idx >= len) {
        len = std.posix.read(0, &buf) catch 0;
        idx = 0;
        if (len == 0) return EOF;
    }
    const c = buf[idx];
    idx += 1;
    return c;
}

pub fn init() void {
    idx = 0;
    len = 0;
}

pub fn skipSpaces() void {
    var c = readByte();
    while (c == ' ' or c == '\n' or c == '\r' or c == '\t') {
        c = readByte();
    }
    if (c != EOF) idx -= 1;
}

pub fn readInt(comptime T: type) T {
    skipSpaces();
    var sign: T = 1;
    var c = readByte();
    if (c == '-') {
        sign = -1;
        c = readByte();
    }
    var result: T = 0;
    while (c >= '0' and c <= '9') {
        result = result * 10 + (c - '0');
        c = readByte();
    }
    if (c != EOF) idx -= 1;
    return result * sign;
}

pub fn readBytes(_: usize) []u8 {
    skipSpaces();
    var i: usize = 0;
    while (i < buf.len) {
        buf[i] = readByte();
        if (buf[i] == EOF) break;
        i += 1;
    }
    return buf[0..i];
}

pub fn printInt(x: anytype) void {
    const T = @TypeOf(x);
    if (x == 0) {
        _ = std.posix.write(1, "0") catch {};
        return;
    }
    if (x < 0) {
        _ = std.posix.write(1, "-") catch {};
    }
    var val: T = if (x < 0) -x else x;
    var buf2: [32]u8 = undefined;
    var i: usize = 0;
    while (val > 0) {
        const d = @as(u8, @intCast(@rem(val, 10)));
        buf2[i] = d + '0';
        val = @divTrunc(val, 10);
        i += 1;
    }
    var j: usize = i;
    while (j > 0) {
        j -= 1;
        const byte = buf2[j];
        _ = std.posix.write(1, &[_]u8{byte}) catch {};
    }
}

pub fn printChar(c: u8) void {
    _ = std.posix.write(1, &[_]u8{c}) catch {};
}

pub fn printStr(s: []const u8) void {
    _ = std.posix.write(1, s) catch {};
}

const std = @import("std");