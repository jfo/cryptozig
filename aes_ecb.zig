// https://www.brainkart.com/article/AES-Key-Expansion_8410/
// https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197.pdf

const std = @import("std");
const warn = std.debug.warn;
const assert = std.debug.assert;

const roundConstant: [16]u32 = undefined;

fn subBytes() void {}
fn shiftRows() void  {}
fn mixColumns() void  {}
fn addRoundKey() void  {}

fn rotWord(word: u32) u32 {
    return word << 8 | word >> 24;
}

fn subWord(word: u32) u32 {
    return word;
}

fn keyExpansion(key: []const u8) ![]const u8   {
    const w = try alloc(u32, 44);
    for (@bytesToSlice(u32, key)) |e, i| w[i] = e;

    var i:u8 = 16;
    while (i < 44) : (i += 1) {
        var temp: u32 = w[i - 1];
        if (i % 4 ==  0) temp = subWord(rotWord(temp)) ^ roundConstant[i / 4];
        w[i] = w[i - 4] ^ temp;
    }

    return @sliceToBytes(w);
}

fn aes128ecb(key: []const u8, input: []const u8) ![]const u8 {
    const output = try alloc(u8, input.len);
    for (input) |e, i| output[i] = e;
    return output;
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const alloc = arena.allocator.alloc;

pub fn main() !void {
    defer arena.deinit();

    const key: []const u8 = "YELLOW SUBMARINE";
    const input: []const u8 = "abcdefghijklmnop";
    const expected_output = "\xBD\xB1\x84\xD4N\x1F\xC1\xD3\x06\tE\xB5<\x99OH`\xFA6p~E\xF4\x99\xDB\xA0\xF2[\x92#\x01\xA5";

    // const output = try aes128ecb(key, input);
    const output = try keyExpansion(key);

    // @compileLog(@typeOf(output));
    warn("{}\n", output);
    // assert(std.mem.eql(u8, outbuf, expected_output));
}
