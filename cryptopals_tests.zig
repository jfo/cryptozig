const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const mem = std.mem;
const base64 = std.base64;
const cp = @import("./cryptopals.zig");

test "Convert hex to base64" {
    const src = "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d";
    const expected_output_raw = "I'm killing your brain like a poisonous mushroom";
    const expected_output_base64 = "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t";

    var dest:[src.len]u8 = undefined;
    const output_raw = cp.hexDigits(dest[0..], src[0..]);

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
    const output_raw = cp.hexDigits(hexed[0..], src[0..]);

    var hexed2:[hexed.len]u8 = undefined;
    const output_raw2 = cp.hexDigits(hexed2[0..], src2[0..]);

    var hexed3:[hexed.len]u8 = undefined;
    const exp = cp.hexDigits(hexed3[0..], expected_output_str[0..]);

    var dest:[hexed.len]u8 = undefined;
    const out = cp.fixed_xor(dest[0..], hexed[0..], hexed2[0..]);

    assert(mem.eql(u8, expected_output_raw, out));
}

test "Single-byte XOR cipher" {
    const src = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736";
    const expected_output = "Cooking MC's like a pound of bacon";

    var hexed:[src.len / 2]u8 = undefined;
    const src_raw = cp.hexDigits(hexed[0..], src[0..]);

    var i:u8 = 0;
    var winner:[src.len / 2]u8 = undefined;
    var dest:[src.len / 2]u8 = undefined;

    while (i < @maxValue(u8)) {
        var out_xor = cp.one_char_xor(dest[0..], src_raw, i);
        i+=1;
        if (cp.scorer(dest) > cp.scorer(winner)) {
            mem.copy(u8, winner[0..], dest[0..]);
        }
    }

    assert(mem.eql(u8, expected_output, winner));
}

test "run Detect single-character XOR" {
    const expected_output = "Now that the party is jumping";

    var inc_allocator = %%std.heap.IncrementingAllocator.init(10 * 1024 * 1024);
    defer inc_allocator.deinit();
    const allocator = &inc_allocator.allocator;
    var file = %%std.io.File.openRead("datafiles/4.txt", allocator);
    defer file.close();

    var buf: [30000]u8 = undefined;

    const s:usize = %%file.getEndPos();
    _ = file.read(buf[0..s]);

    var dest: [327][]u8 = undefined;
    const lines = cp.readlines(dest[0..], buf[0..s]);

    var buffer: [500]u8 = undefined;
    var winners: [500][]u8 = undefined;

    var i:u8 = 0;
    var wi:u32 = 0;
    while (i < @maxValue(u8)) {
        for (lines) |line| {
            var x = cp.hexDigits(buffer[0..], line);
            var l = cp.one_char_xor(buffer[0..], x, i);
            if (cp.scorer(l) > 110) {
                warn("\n");
                warn("{} ", cp.scorer(l));
                warn("{} ", cp.score_ascii(l));
                warn("{} ", cp.score_spaces(l));
                cp.printLn(line);
                warn(" ");
                cp.printLn(l[0..30]);
                wi += 1;
            }
        }
        i += 1;
    }
}
