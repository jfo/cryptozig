const assert = @import("std").debug.assert;
const mem = @import("std").mem;

const cryptopals = @import("./cryptopals.zig");
const base64 = @import("std").base64;

const hexDigits = cryptopals.hexDigits;
const one_char_xor = cryptopals.one_char_xor;
const scorer = cryptopals.scorer;
const fixed_xor = cryptopals.fixed_xor;

test "Convert hex to base64" {
    const src = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d";
    const expected_output_raw = "I'm killing your brain like a poisonous mushroom";
    const expected_output_base64 = "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t";

    var dest:[src.len]u8 = undefined;
    const output_raw = hexDigits(dest[0..], src[0..]);

    var dest2:[src.len]u8 = undefined;
    const output_base64 = base64.encode(dest2[0..], output_raw[0..output_raw.len]);

    assert(mem.eql(u8, expected_output_raw, output_raw));
    assert(mem.eql(u8, expected_output_base64, output_base64));
}

test "Fixed XOR" {
    const src = "1c0111001f010100061a024b53535009181c";
    const src2 = "686974207468652062756c6c277320657965";

    const expected_output_str = "746865206b696420646f6e277420706c6179";
    const expected_output_raw = "the kid don't play";

    var hexed:[src.len / 2]u8 = undefined;
    const output_raw = hexDigits(hexed[0..], src[0..]);

    var hexed2:[hexed.len]u8 = undefined;
    const output_raw2 = hexDigits(hexed2[0..], src2[0..]);

    var hexed3:[hexed.len]u8 = undefined;
    const exp = hexDigits(hexed3[0..], expected_output_str[0..]);

    var dest:[hexed.len]u8 = undefined;
    const out = fixed_xor(dest[0..], hexed[0..], hexed2[0..]);

    assert(mem.eql(u8, expected_output_raw, out));
}

test "Single-byte XOR cipher" {
    const src = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736";
    const expected_output = "Cooking MC's like a pound of bacon";

    var hexed:[src.len / 2]u8 = undefined;
    const src_raw = hexDigits(hexed[0..], src[0..]);

    var i:u8 = 0;
    var winner:[src.len / 2]u8 = undefined;
    var dest:[src.len / 2]u8 = undefined;

    while (i < @maxValue(u8)) {
        var out_xor = one_char_xor(dest[0..], src_raw, i);
        i+=1;
        if (scorer(dest) > scorer(winner)) {
            mem.copy(u8, winner[0..], dest[0..]);
        }
    }

    assert(mem.eql(u8, expected_output, winner));
}

test "Detect single-character XOR" {
}
