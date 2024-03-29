// https://www.brainkart.com/article/AES-Key-Expansion_8410/
// https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197.pdf
// https://www.samiam.org/key-schedule.html
// https://www.nayuki.io/page/aes-cipher-internals-in-excel

const std = @import("std");
const warn = std.debug.print;
const assert = std.debug.assert;
const base64 = std.base64;

// TODO: move to general utils
const read = @import("./cryptopals.zig").read_file_into_buf;

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

const sBoxInverse = [16][16]u8{
    [_]u8{ '\x52', '\x09', '\x6a', '\xd5', '\x30', '\x36', '\xa5', '\x38', '\xbf', '\x40', '\xa3', '\x9e', '\x81', '\xf3', '\xd7', '\xfb' },
    [_]u8{ '\x7c', '\xe3', '\x39', '\x82', '\x9b', '\x2f', '\xff', '\x87', '\x34', '\x8e', '\x43', '\x44', '\xc4', '\xde', '\xe9', '\xcb' },
    [_]u8{ '\x54', '\x7b', '\x94', '\x32', '\xa6', '\xc2', '\x23', '\x3d', '\xee', '\x4c', '\x95', '\x0b', '\x42', '\xfa', '\xc3', '\x4e' },
    [_]u8{ '\x08', '\x2e', '\xa1', '\x66', '\x28', '\xd9', '\x24', '\xb2', '\x76', '\x5b', '\xa2', '\x49', '\x6d', '\x8b', '\xd1', '\x25' },
    [_]u8{ '\x72', '\xf8', '\xf6', '\x64', '\x86', '\x68', '\x98', '\x16', '\xd4', '\xa4', '\x5c', '\xcc', '\x5d', '\x65', '\xb6', '\x92' },
    [_]u8{ '\x6c', '\x70', '\x48', '\x50', '\xfd', '\xed', '\xb9', '\xda', '\x5e', '\x15', '\x46', '\x57', '\xa7', '\x8d', '\x9d', '\x84' },
    [_]u8{ '\x90', '\xd8', '\xab', '\x00', '\x8c', '\xbc', '\xd3', '\x0a', '\xf7', '\xe4', '\x58', '\x05', '\xb8', '\xb3', '\x45', '\x06' },
    [_]u8{ '\xd0', '\x2c', '\x1e', '\x8f', '\xca', '\x3f', '\x0f', '\x02', '\xc1', '\xaf', '\xbd', '\x03', '\x01', '\x13', '\x8a', '\x6b' },
    [_]u8{ '\x3a', '\x91', '\x11', '\x41', '\x4f', '\x67', '\xdc', '\xea', '\x97', '\xf2', '\xcf', '\xce', '\xf0', '\xb4', '\xe6', '\x73' },
    [_]u8{ '\x96', '\xac', '\x74', '\x22', '\xe7', '\xad', '\x35', '\x85', '\xe2', '\xf9', '\x37', '\xe8', '\x1c', '\x75', '\xdf', '\x6e' },
    [_]u8{ '\x47', '\xf1', '\x1a', '\x71', '\x1d', '\x29', '\xc5', '\x89', '\x6f', '\xb7', '\x62', '\x0e', '\xaa', '\x18', '\xbe', '\x1b' },
    [_]u8{ '\xfc', '\x56', '\x3e', '\x4b', '\xc6', '\xd2', '\x79', '\x20', '\x9a', '\xdb', '\xc0', '\xfe', '\x78', '\xcd', '\x5a', '\xf4' },
    [_]u8{ '\x1f', '\xdd', '\xa8', '\x33', '\x88', '\x07', '\xc7', '\x31', '\xb1', '\x12', '\x10', '\x59', '\x27', '\x80', '\xec', '\x5f' },
    [_]u8{ '\x60', '\x51', '\x7f', '\xa9', '\x19', '\xb5', '\x4a', '\x0d', '\x2d', '\xe5', '\x7a', '\x9f', '\x93', '\xc9', '\x9c', '\xef' },
    [_]u8{ '\xa0', '\xe0', '\x3b', '\x4d', '\xae', '\x2a', '\xf5', '\xb0', '\xc8', '\xeb', '\xbb', '\x3c', '\x83', '\x53', '\x99', '\x61' },
    [_]u8{ '\x17', '\x2b', '\x04', '\x7e', '\xba', '\x77', '\xd6', '\x26', '\xe1', '\x69', '\x14', '\x63', '\x55', '\x21', '\x0c', '\x7d' },
};

fn subBytes(input: *[4][4]u8) void {
    subWord(input[0][0..]);
    subWord(input[1][0..]);
    subWord(input[2][0..]);
    subWord(input[3][0..]);
}

fn subBytesInverse(input: *[4][4]u8) void {
    subWordInverse(input[0][0..]);
    subWordInverse(input[1][0..]);
    subWordInverse(input[2][0..]);
    subWordInverse(input[3][0..]);
}

fn shiftRows(input: *[4][4]u8) void {
    _ = rotWord(input[1][0..]);
    _ = rotWord(rotWord(input[2][0..]));
    _ = rotWord(rotWord(rotWord(input[3][0..])));
}

fn mixColumn(r: *[4]u8) void {
    var a: [4]u8 = undefined;
    var b: [4]u8 = undefined;

    var c: u8 = 0;
    while (c < 4) : (c += 1) {
        a[c] = r[c];
        b[c] = gmul(r[c], 2);
    }
    r[0] = b[0] ^ a[3] ^ a[2] ^ b[1] ^ a[1];
    r[1] = b[1] ^ a[0] ^ a[3] ^ b[2] ^ a[2];
    r[2] = b[2] ^ a[1] ^ a[0] ^ b[3] ^ a[3];
    r[3] = b[3] ^ a[2] ^ a[1] ^ b[0] ^ a[0];
}

fn mixColumnReverse(r: *[4]u8) void {
    var a: [4]u8 = undefined;

    var c: u8 = 0;
    while (c < 4) : (c += 1) {
        a[c] = r[c];
    }
    r[0] = gmul(a[0], 14) ^ gmul(a[3], 9) ^ gmul(a[2], 13) ^ gmul(a[1], 11);
    r[1] = gmul(a[1], 14) ^ gmul(a[0], 9) ^ gmul(a[3], 13) ^ gmul(a[2], 11);
    r[2] = gmul(a[2], 14) ^ gmul(a[1], 9) ^ gmul(a[0], 13) ^ gmul(a[3], 11);
    r[3] = gmul(a[3], 14) ^ gmul(a[2], 9) ^ gmul(a[1], 13) ^ gmul(a[0], 11);
}

fn mixColumns(input: *[4][4]u8) !void {
    var temp = try invertFourByFour(input.*);

    mixColumn(&temp[0]);
    mixColumn(&temp[1]);
    mixColumn(&temp[2]);
    mixColumn(&temp[3]);

    temp = try invertFourByFour(temp.*);

    for (temp) |el, idx| {
        for (el) |e, i| {
            input[idx][i] = e;
        }
    }
}

fn mixColumnsReverse(input: *[4][4]u8) !void {
    var temp = try invertFourByFour(input.*);

    mixColumnReverse(&temp[0]);
    mixColumnReverse(&temp[1]);
    mixColumnReverse(&temp[2]);
    mixColumnReverse(&temp[3]);

    temp = try invertFourByFour(temp.*);

    for (temp) |el, idx| {
        for (el) |e, i| {
            input[idx][i] = e;
        }
    }
}

fn addRoundKey(input: *[4][4]u8, roundKeyMatrix: *const [4][4]u8) void {
    for (input) |inputElement, iex| {
        for (inputElement) |e, i| {
            input[iex][i] = e ^ roundKeyMatrix[iex][i];
        }
    }
}

fn sixteenToFourByFour(input: []const u8) !*[4][4]u8 {
    assert(input.len == 16);
    const output = try create([4][4]u8);
    for (input) |e, i| output[i % 4][i / 4] = e;
    return output;
}

fn fourByFourToSixteen(input: *[4][4]u8) ![]u8 {
    const output = try create([16]u8);
    for (output) |_, i| output[i] = input[i % 4][i / 4];
    return output;
}

fn invertFourByFour(input: [4][4]u8) !*[4][4]u8 {
    const output = try create([4][4]u8);

    for (input) |inputElement, iex| {
        for (inputElement) |e, i| {
            output[i][iex] = e;
        }
    }

    return output;
}

fn rotWord(word: []u8) []u8 {
    const temp = word[0];
    word[0] = word[1];
    word[1] = word[2];
    word[2] = word[3];
    word[3] = temp;

    return word;
}

fn subWord(word: []u8) void {
    for (word) |w, i| {
        word[i] = sBox[(w & 240) >> 4][w & 15];
    }
}

fn subWordInverse(word: []u8) void {
    for (word) |w, i| {
        word[i] = sBoxInverse[(w & 240) >> 4][w & 15];
    }
}

fn keyExpansion(key: []const u8) ![]u8 {
    const w = try alloc(u8, 176);
    for (key) |e, i| w[i] = e;

    var i: u16 = 16;
    while (i < 176) : (i += 4) {
        var temp = try create([4]u8);
        for (w[i - 4 .. i]) |e, idx| temp[idx] = e;
        if (i % 16 == 0) {
            _ = rotWord(temp);
            subWord(temp);
            temp[0] ^= roundConstant[i / 16 - 1];
        }

        w[i] = temp[0] ^ w[i - 16];
        w[i + 1] = temp[1] ^ w[i - 15];
        w[i + 2] = temp[2] ^ w[i - 14];
        w[i + 3] = temp[3] ^ w[i - 13];
    }

    return w;
}

fn gmul(x: u8, y: u8) u8 {
    var p: u8 = 0;
    var a = x;
    var b = y;

    var i: u8 = 0;
    while (i < 8) : (i += 1) {
        if (b & 1 == 1) p ^= a;
        const aHighBitSet = (a & 128) == 128;
        a = a << 1;
        if (aHighBitSet) a ^= 0x1b;
        b = b >> 1;
    }
    return p;
}

fn encryptBlock(key: []const u8, input: []const u8) ![]const u8 {
    const expandedKey = try keyExpansion(key);
    const state = try sixteenToFourByFour(input[0..]);

    // initial round 0, addRoundKey
    var roundKey = try sixteenToFourByFour(expandedKey[0..16]);
    addRoundKey(state, roundKey);

    // // round 1 - 9
    var i: u32 = 1;
    while (i < 10) : (i += 1) {
        subBytes(state);
        shiftRows(state);
        _ = try mixColumns(state);
        roundKey = try sixteenToFourByFour(expandedKey[16 * i .. 16 * i + 16]);
        addRoundKey(state, roundKey);
    }

    // round 10
    subBytes(state);
    shiftRows(state);
    roundKey = try sixteenToFourByFour(expandedKey[expandedKey.len - 16 .. expandedKey.len]);
    addRoundKey(state, roundKey);

    return try fourByFourToSixteen(state);
}

fn decryptBlock(key: []const u8, input: []const u8) ![]const u8 {
    const expandedKey = try keyExpansion(key);
    const state = try sixteenToFourByFour(input[0..]);

    // round 10 in reverse
    var roundKey = try sixteenToFourByFour(expandedKey[expandedKey.len - 16 .. expandedKey.len]);
    addRoundKey(state, roundKey);
    shiftRows(state);
    shiftRows(state);
    shiftRows(state);
    subBytesInverse(state);

    var i: u8 = 10;
    while (i > 1) : (i -= 1) {
        roundKey = try sixteenToFourByFour(expandedKey[16 * (i - 1) .. 16 * (i - 1) + 16]);
        addRoundKey(state, roundKey);
        _ = try mixColumnsReverse(state);
        shiftRows(state);
        shiftRows(state);
        shiftRows(state);
        subBytesInverse(state);
    }

    roundKey = try sixteenToFourByFour(expandedKey[0..16]);
    addRoundKey(state, roundKey);

    return try fourByFourToSixteen(state);
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const alloc = arena.allocator().alloc;
const create = arena.allocator().create;

// TODO: move into `decrypt` function, handling arbitrary length input with
// proper padding (whatever that is)
pub fn main() !void {
    defer arena.deinit();
    const key: []const u8 = "YELLOW SUBMARINE";
    var buf: [100 * 1025]u8 = undefined;

    const input = try read(buf[0..], "/Volumes/InternalNVME/jeff/code/cryptozig/datafiles/7stripped.txt");

    var decoded_buf: [5000]u8 = undefined;

    const decoder = base64.standard.Decoder;
    const size = try decoder.calcSizeForSlice(input);
    _ = try decoder.decode(decoded_buf[0..size], input);

    var decryptedbuf: [5000]u8 = undefined;
    var i: u32 = 0;
    while (i < 3000) : (i += 16) {
        var d = try decryptBlock(key, decoded_buf[i .. i + 16]);
        for (d) |e, id| decryptedbuf[i + id] = e;
    }

    warn("{any}\n", .{decryptedbuf});
}

test "key expansion" {
    const key: []const u8 = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f";
    const expectedExpandedKey = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\xd6\xaa\x74\xfd\xd2\xaf\x72\xfa\xda\xa6\x78\xf1\xd6\xab\x76\xfe\xb6\x92\xcf\x0b\x64\x3d\xbd\xf1\xbe\x9b\xc5\x00\x68\x30\xb3\xfe\xb6\xff\x74\x4e\xd2\xc2\xc9\xbf\x6c\x59\x0c\xbf\x04\x69\xbf\x41\x47\xf7\xf7\xbc\x95\x35\x3e\x03\xf9\x6c\x32\xbc\xfd\x05\x8d\xfd\x3c\xaa\xa3\xe8\xa9\x9f\x9d\xeb\x50\xf3\xaf\x57\xad\xf6\x22\xaa\x5e\x39\x0f\x7d\xf7\xa6\x92\x96\xa7\x55\x3d\xc1\x0a\xa3\x1f\x6b\x14\xf9\x70\x1a\xe3\x5f\xe2\x8c\x44\x0a\xdf\x4d\x4e\xa9\xc0\x26\x47\x43\x87\x35\xa4\x1c\x65\xb9\xe0\x16\xba\xf4\xae\xbf\x7a\xd2\x54\x99\x32\xd1\xf0\x85\x57\x68\x10\x93\xed\x9c\xbe\x2c\x97\x4e\x13\x11\x1d\x7f\xe3\x94\x4a\x17\xf3\x07\xa7\x8b\x4d\x2b\x30\xc5";
    const expandedKey = try keyExpansion(key);
    assert(std.mem.eql(u8, expandedKey, expectedExpandedKey));
}

test "encrypt block" {
    const key: []const u8 = "YELLOW SUBMARINE";
    const input: []const u8 = "abcdefghijklmnop";
    const encrypted = try encryptBlock(key, input);
    assert(std.mem.eql(u8, encrypted, "\xbd\xb1\x84\xd4\x4e\x1f\xc1\xd3\x06\x09\x45\xb5\x3c\x99\x4f\x48"));
}

test "decrypt block" {
    const key: []const u8 = "YELLOW SUBMARINE";
    const input: []const u8 = "abcdefghijklmnop";
    const encrypted = try encryptBlock(key, input);
    const decrypted = try decryptBlock(key, encrypted);
    assert(std.mem.eql(u8, decrypted, "abcdefghijklmnop"));
}
