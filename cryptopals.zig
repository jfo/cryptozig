const warn = @import("std").debug.warn;
const mem = @import("std").mem;

// none of this is in any way done or intended beyond my own debuggery use.

pub fn hexDigit(c: u8) -> u8 {
    switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => u8(@maxValue(u8))
    }
}

pub fn hexDigits(dest: []u8, src: []const u8) -> []u8 {
    var i:u32 = 0;
    while (i < src.len) {
        dest[i / 2] = hexDigit(src[i]) << 4 | hexDigit(src[i + 1]);
        i+=2;
    }
    return dest[0..src.len / 2 ];
}

pub fn one_char_xor(dest: []u8, src: []const u8, c:u8) -> []u8 {
    for (src) |char, i| dest[i] = char ^ c;
    dest[0..]
}

// this naive score function simply counts spaces
pub fn scorer(src: []const u8) -> u32 {
    var count:u32 = 0;
    for (src) |char| {
        if (char == 32) {
            count += 1
        }
    }
    count
}

// this is a little better, scoring for ascii chars
pub fn scorechars(src: []const u8) -> u32 {
    var count:u32 = 0;
    for (src) |char| {
        if (char > ' ' and char < 122) {
            count += 1
        }
    }
    count
}

pub fn printLn(line: []u8) -> void {
    for (line) |c| warn("{c}", c);
}

pub fn readlines(dest: [][]u8, content: []u8) -> [][]u8 {
    var idx1:usize = 0;
    var idx2:usize = 0;
    for (content) |c, i| if (c == '\n') {
        dest[idx1] = content[idx2..i];
        idx1 += 1;
        idx2 = i + 1;
    };
    dest
}

pub fn fixed_xor(dest: []u8, src: []const u8, src2: []const u8) -> []u8 {
    for (src) |c, i| dest[i] = c ^ src2[i];
    dest[0..]
}