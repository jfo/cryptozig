const warn = @import("std").debug.warn;
const assert = @import("std").debug.assert;
const encode = @import("std").base64.encode;
const mem = @import("std").mem;

fn hexDigit(c: u8) -> u8 {
    switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => u8(@maxValue(u8))
    }
}

fn hexDigits(dest: []u8, src: []const u8) -> []u8 {
    var i:u32 = 0;
    while (i < src.len) {
        dest[i / 2] = hexDigit(src[i]) << 4 | hexDigit(src[i + 1]);
        i+=2;
    }
    return dest[0..src.len / 2 ];
}

test "cryptopals 1" {
    const src = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d";
    const expected_output_raw = "I'm killing your brain like a poisonous mushroom";
    const expected_output_base64 = "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t";

    var dest:[src.len]u8 = undefined;
    const output_raw = hexDigits(dest[0..], src[0..]);

    var dest2:[src.len]u8 = undefined;
    const output_base64 = encode(dest2[0..], output_raw[0..output_raw.len]);

    assert(mem.eql(u8, expected_output_raw, output_raw));
    assert(mem.eql(u8, expected_output_base64, output_base64));
}

