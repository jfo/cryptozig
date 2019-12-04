// https://www.brainkart.com/article/AES-Key-Expansion_8410/
// https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197.pdf

const std = @import("std");
const warn = std.debug.warn;
const assert = std.debug.assert;

const roundConstant = [_]u32{ '\x01', '\x02', '\x04', '\x08', '\x10', '\x20', '\x40', '\x80', '\x1B', '\x36' };

const sBox = [16][16]u8{
    [_]u8{ '\x63', '\x7c', '\x77', '\x7b', '\xf2', '\x6b', '\x6f', '\xc5', '\x30', '\x01', '\x67', '\x2b', '\xfe', '\xd7', '\xab', '\x76' },
    [_]u8{ '\xca', '\x82', '\xc9', '\x7d', '\xfa', '\x59', '\x47', '\xf0', '\xad', '\xd4', '\xa2', '\xaf', '\x9c', '\xa4', '\x72', '\xc0' },
    [_]u8{ '\xb7', '\xfd', '\x93', '\x26', '\x36', '\x3f', '\xf7', '\xcc', '\x34', '\xa5', '\xe5', '\xf1', '\x71', '\xd8', '\x31', '\x15' },
    [_]u8{ '\x04', '\xc7', '\x23', '\xc3', '\x18', '\x96', '\x05', '\x9a', '\x07', '\x12', '\x80', '\xe2', '\xeb', '\x27', '\xb2', '\x75' },
    [_]u8{ '\x09', '\x83', '\x2c', '\x1a', '\x1b', '\x6e', '\x5a', '\xa0', '\x52', '\x3b', '\xd6', '\xb3', '\x29', '\xe3', '\x2f', '\x84' },
    [_]u8{ '\x53', '\xd1', '\x00', '\xed', '\x20', '\xfc', '\xb1', '\x5b', '\x6a', '\xcb', '\xbe', '\x39', '\x4a', '\x4c', '\x58', '\xcf' },
    [_]u8{ '\xd0', '\xef', '\xaa', '\xfb', '\x43', '\x4d', '\x33', '\x85', '\x45', '\xf9', '\x02', '\x7f', '\x50', '\x3c', '\x9f', '\xa8' },
    [_]u8{ '\x51', '\xa3', '\x40', '\x8f', '\x92', '\x9d', '\x38', '\xf5', '\xbc', '\xb6', '\xda', '\x21', '\x10', '\xff', '\xf3', '\xd2' },
    [_]u8{ '\xcd', '\x0c', '\x13', '\xec', '\x5f', '\x97', '\x44', '\x17', '\xc4', '\xa7', '\x7e', '\x3d', '\x64', '\x5d', '\x19', '\x73' },
    [_]u8{ '\x60', '\x81', '\x4f', '\xdc', '\x22', '\x2a', '\x90', '\x88', '\x46', '\xee', '\xb8', '\x14', '\xde', '\x5e', '\x0b', '\xdb' },
    [_]u8{ '\xe0', '\x32', '\x3a', '\x0a', '\x49', '\x06', '\x24', '\x5c', '\xc2', '\xd3', '\xac', '\x62', '\x91', '\x95', '\xe4', '\x79' },
    [_]u8{ '\xe7', '\xc8', '\x37', '\x6d', '\x8d', '\xd5', '\x4e', '\xa9', '\x6c', '\x56', '\xf4', '\xea', '\x65', '\x7a', '\xae', '\x08' },
    [_]u8{ '\xba', '\x78', '\x25', '\x2e', '\x1c', '\xa6', '\xb4', '\xc6', '\xe8', '\xdd', '\x74', '\x1f', '\x4b', '\xbd', '\x8b', '\x8a' },
    [_]u8{ '\x70', '\x3e', '\xb5', '\x66', '\x48', '\x03', '\xf6', '\x0e', '\x61', '\x35', '\x57', '\xb9', '\x86', '\xc1', '\x1d', '\x9e' },
    [_]u8{ '\xe1', '\xf8', '\x98', '\x11', '\x69', '\xd9', '\x8e', '\x94', '\x9b', '\x1e', '\x87', '\xe9', '\xce', '\x55', '\x28', '\xdf' },
    [_]u8{ '\x8c', '\xa1', '\x89', '\x0d', '\xbf', '\xe6', '\x42', '\x68', '\x41', '\x99', '\x2d', '\x0f', '\xb0', '\x54', '\xbb', '\x16' },
};

fn subBytes() void {}
fn shiftRows() void {}
fn mixColumns() void {}
fn addRoundKey() void {}

fn rotWord(word: u32) u32 {
    return word << 8 | word >> 24;
}

fn subWord(word: u32) u32 {
    const wordSlice = @sliceToBytes(([_]u32{word})[0..]);
    var outBuf = [_]u8{ 0, 0, 0, 0 };
    for (wordSlice) |w, i| {
        outBuf[i] = sBox[(w & 240) >> 4][w & 15];
    }

    var out: u32 = 0;
    out = (out | outBuf[0]) << 8;
    out = (out | outBuf[1]) << 8;
    out = (out | outBuf[2]) << 8;
    out = (out | outBuf[3]);
    return out;
}

fn keyExpansion(key: []const u8) ![]const u8 {
    const w = try alloc(u32, 44);
    for (@bytesToSlice(u32, key)) |e, i| w[i] = e;

    var i: u8 = 4;
    while (i < 44) : (i += 1) {
        var temp: u32 = w[i - 1];
        if (i % 4 == 0) temp = subWord(rotWord(temp)) ^ (roundConstant[i / 4 - 1]);
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

    // const key: []const u8 = "YELLOW SUBMARINE";
    // const key: []const u8 = "Thats my Kung Fu";
    const key: []const u8 = "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff";
    const input: []const u8 = "abcdefghijklmnop";
    const expected_output = "\xBD\xB1\x84\xD4N\x1F\xC1\xD3\x06\tE\xB5<\x99OH`\xFA6p~E\xF4\x99\xDB\xA0\xF2[\x92#\x01\xA5";

    // // const output = try aes128ecb(key, input);
    const output = try keyExpansion(key);

    // @compileLog(@typeOf(output));
    warn("{}\n", output);
    // assert(std.mem.eql(u8, outbuf, expected_output));
}
