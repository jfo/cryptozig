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

    var dest: [src.len]u8 = undefined;
    const output_raw = cp.hexDigits(dest[0..], src[0..]);

    const encoder = base64.standard_encoder;
    var buffer: [5000]u8 = undefined;
    var encoded = buffer[0..base64.Base64Encoder.calcSize(output_raw.len)];
    _ = encoder.encode(encoded, output_raw[0..output_raw.len]);

    assert(mem.eql(u8, expected_output_raw, output_raw));
    assert(mem.eql(u8, expected_output_base64, encoded));
}

test "Fixed XOR" {
    const src = "1c0111001f010100061a024b53535009181c";
    const src2 = "686974207468652062756c6c277320657965";

    const expected_output_str = "746865206b696420646f6e277420706c6179";
    const expected_output_raw = "the kid don't play";

    var hexed: [src.len / 2]u8 = undefined;
    const output_raw = cp.hexDigits(hexed[0..], src[0..]);

    var hexed2: [hexed.len]u8 = undefined;
    const output_raw2 = cp.hexDigits(hexed2[0..], src2[0..]);

    var hexed3: [hexed.len]u8 = undefined;
    const exp = cp.hexDigits(hexed3[0..], expected_output_str[0..]);

    var dest: [hexed.len]u8 = undefined;
    const out = cp.fixed_xor(dest[0..], hexed[0..], hexed2[0..]);

    assert(mem.eql(u8, expected_output_raw, out));
}

test "Single-byte XOR cipher" {
    const src = "1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736";
    const expected_output = "Cooking MC's like a pound of bacon";

    var hexed: [src.len / 2]u8 = undefined;
    const src_raw = cp.hexDigits(hexed[0..], src[0..]);

    var i: u8 = 0;
    var winner: [src.len / 2]u8 = undefined;
    var dest: [src.len / 2]u8 = undefined;

    while (i < @maxValue(u8)) {
        var out_xor = cp.one_char_xor(dest[0..], src_raw, i);
        i += 1;
        if (cp.scorer(dest) > cp.scorer(winner)) {
            mem.copy(u8, winner[0..], dest[0..]);
        }
    }

    assert(mem.eql(u8, expected_output, winner));
}

// soooo much could be improved here.
test "Detect single-character XOR" {
    const expected_output = "Now that the party is jumping";

    var inc_allocator = try std.heap.IncrementingAllocator.init(10 * 1024 * 1024);
    defer inc_allocator.deinit();
    const allocator = &inc_allocator.allocator;
    var file = try std.io.File.openRead("datafiles/4.txt", allocator);
    defer file.close();

    var buf: [30000]u8 = undefined;

    const s: usize = try file.getEndPos();
    _ = file.read(buf[0..s]);

    var dest: [327][]u8 = undefined;
    const lines = cp.readlines(dest[0..], buf[0..s]);

    var buffer: [500]u8 = undefined;

    var i: u8 = 0;

    var winner: [500]u8 = undefined;
    var last_winner_score: u32 = 0;
    while (i < @maxValue(u8)) {
        for (lines) |line| {
            var x = cp.hexDigits(buffer[0..], line);
            var l = cp.one_char_xor(buffer[0..], x, i);
            const score = cp.scorer(l);
            if (score > last_winner_score) {
                last_winner_score = score;
                for (l[0..l.len]) |b, idx| winner[idx] = b;
            }
        }
        i += 1;
    }

    assert(mem.eql(u8, expected_output[0..], winner[0..expected_output.len]));
}

test "Implement repeating-key XOR" {
    const key = "ICE";
    const src = "Burning 'em, if you ain't quick and nimble\nI go crazy when I hear a cymbal";
    const expected_str = "0b3637272a2b2e63622c2e69692a23693a2a3c6324202d623d63343c2a26226324272765272a282b2f20430a652e2c652a3124333a653e2b2027630c692b20283165286326302e27282f";
    var buffer1: [500]u8 = undefined;
    const expected = cp.hexDigits(buffer1[0..expected_str.len], expected_str);

    var output: [256]u8 = undefined;
    cp.repeating_key_xor(output[0..], src, key);
    assert(mem.eql(u8, expected[0..], output[0..expected.len]));
}

test "Break repeating-key XOR" {
    assert(37 == try cp.hamming_distance("this is a test", "wokka wokka!!!"));

    const hamming_test_str = "12345678";
    assert((try cp.hamming_distance("1234", "5678")) ==
        (try cp.keysize_hamming(hamming_test_str, 4)));

    assert((try cp.hamming_distance("123", "456")) ==
        (try cp.keysize_hamming(hamming_test_str, 3)));

    var buf: [100 * 64]u8 = undefined;
    const input = try cp.read_file_into_buf(buf[0..], "datafiles/6stripped.txt");

    // something is rotten here
    var decoded_buf: [5000]u8 = undefined;
    const decoder = base64.standard_decoder;
    const size = try decoder.calcSize(input);
    _ = decoder.decode(decoded_buf[0..size], input);

    var dest: [5000]u8 = undefined;
    const decrypted = cp.break_repeating_key_xor(dest[0..], decoded_buf[0..size]);
    warn("{}", dest);
}

test "run AES in ECB mode" {
    var buf: [1000 * 64]u8 = undefined;
    const input = try cp.read_file_into_buf(buf[0..], "datafiles/7stripped.txt");

    var decoded_buf: [7000]u8 = undefined;
    var decoded_input = base64.decode(decoded_buf[0..], input);
    warn("{}", decoded_input);

    const key = "YELLOW SUBMARINE";
    var out = cp.thing(decoded_input, key);

    warn("\n{}\n", out);
}
