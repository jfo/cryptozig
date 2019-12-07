// https://www.brainkart.com/article/AES-Key-Expansion_8410/
// https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197.pdf

const std = @import("std");
const warn = std.debug.warn;
const assert = std.debug.assert;

const roundConstant = [_]u8{ '\x01', '\x02', '\x04', '\x08', '\x10', '\x20', '\x40', '\x80', '\x1B', '\x36' };

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

fn rotWord(word: []u8) ![]u8 {
    var out = try alloc(u8, 4);
    for (word) |b, i| out[i] = b;
    const temp = out[0];
    out[0] = out[1];
    out[1] = out[2];
    out[2] = out[3];
    out[3] = temp;

    return out[0..];
}

fn subWord(word: []u8) ![]u8 {
    var out = try alloc(u8, 4);

    for (word) |w, i| {
        out[i] = sBox[(w & 240) >> 4][w & 15];
    }

    return out;
}

fn keyExpansion(key: []const u8) ![]const u8 {
    const w = try alloc(u8, 176);
    for (key) |e, i| w[i] = e;

    var i: u16 = 16;
    while (i < 176) : (i += 4) {
        var temp = w[i - 4 .. i];
        if (i % 16 == 0) {
            temp = try subWord(try rotWord(temp));
            temp[0] ^= roundConstant[i / 16 - 1];
        }

        w[i] = temp[0] ^ w[i - 16];
        w[i + 1] = temp[1] ^ w[i - 15];
        w[i + 2] = temp[2] ^ w[i - 14];
        w[i + 3] = temp[3] ^ w[i - 13];
    }

    return w;
}

fn aes128ecb(key: []const u8, input: []const u8) ![]const u8 {
    const output = try alloc(u8, input.len);
    for (input) |e, i| output[i] = e;
    return output;
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const alloc = arena.allocator.alloc;
const create = arena.allocator.create;

pub fn main() !void {
    defer arena.deinit();

    // const key: []const u8 = "YELLOW SUBMARINE";
    // const key: []const u8 = "Thats my Kung Fu";
    // const input: []const u8 = "abcdefghijklmnop";

    const key: []const u8 = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f";
    const expectedExpandedKey = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\xd6\xaa\x74\xfd\xd2\xaf\x72\xfa\xda\xa6\x78\xf1\xd6\xab\x76\xfe\xb6\x92\xcf\x0b\x64\x3d\xbd\xf1\xbe\x9b\xc5\x00\x68\x30\xb3\xfe\xb6\xff\x74\x4e\xd2\xc2\xc9\xbf\x6c\x59\x0c\xbf\x04\x69\xbf\x41\x47\xf7\xf7\xbc\x95\x35\x3e\x03\xf9\x6c\x32\xbc\xfd\x05\x8d\xfd\x3c\xaa\xa3\xe8\xa9\x9f\x9d\xeb\x50\xf3\xaf\x57\xad\xf6\x22\xaa\x5e\x39\x0f\x7d\xf7\xa6\x92\x96\xa7\x55\x3d\xc1\x0a\xa3\x1f\x6b\x14\xf9\x70\x1a\xe3\x5f\xe2\x8c\x44\x0a\xdf\x4d\x4e\xa9\xc0\x26\x47\x43\x87\x35\xa4\x1c\x65\xb9\xe0\x16\xba\xf4\xae\xbf\x7a\xd2\x54\x99\x32\xd1\xf0\x85\x57\x68\x10\x93\xed\x9c\xbe\x2c\x97\x4e\x13\x11\x1d\x7f\xe3\x94\x4a\x17\xf3\x07\xa7\x8b\x4d\x2b\x30\xc5";

    const expandedKey = try keyExpansion(key);
    // warn("{}", expandedKey);
    assert(std.mem.eql(u8, expandedKey, expectedExpandedKey));
}
