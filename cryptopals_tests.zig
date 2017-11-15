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

// soooo much could be improved here.
test "Detect single-character XOR" {
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

    var i:u8 = 0;

    var winner: [500]u8 = undefined;
    var last_winner_score:u32 = 0;
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

    assert(mem.eql(u8, expected_output[0..], winner[0..expected_output.len]))
}

test "Implement repeating-key XOR" {
    const key = "ICE";
    const src = "Burning 'em, if you ain't quick and nimble\nI go crazy when I hear a cymbal";
    const expected_str = "0b3637272a2b2e63622c2e69692a23693a2a3c6324202d623d63343c2a26226324272765272a282b2f20430a652e2c652a3124333a653e2b2027630c692b20283165286326302e27282f";
    var buffer1 :[500]u8 = undefined;
    const expected = cp.hexDigits(buffer1[0..expected_str.len], expected_str);

    var output: [256]u8 = undefined;
    cp.repeating_key_xor(output[0..], src, key);
    assert(mem.eql(u8, expected[0..], output[0..expected.len]));
}

test "run Break repeating-key XOR" {
    assert(37 == %%cp.hamming_distance("this is a test", "wokka wokka!!!"));

    const hamming_test_str = "12345678";
    assert(%%cp.hamming_distance("1234", "5678") ==
            %%cp.keysize_hamming(hamming_test_str, 4));
    assert(%%cp.hamming_distance("123", "456") ==
            %%cp.keysize_hamming(hamming_test_str, 3));

    // open the source file
    var inc_allocator = %%std.heap.IncrementingAllocator.init(10 * 1024 * 1024);
    defer inc_allocator.deinit();
    const allocator = &inc_allocator.allocator;
    var file = %%std.io.File.openRead("datafiles/6stripped.txt", allocator);
    defer file.close();

    // read the source file into a buffer
    const s:usize = %%file.getEndPos();
    var buf: [1000 * 64]u8 = undefined;
    const input_size = %%file.read(buf[0..s]);
    const input = buf[0..input_size];

    var decoded_buf: [7000]u8 = undefined;
    var decoded_input = base64.decode(decoded_buf[0..], input);

    // Let KEYSIZE be the guessed length of the key; try values from 2 to (say) 40.
    // For each KEYSIZE, take the first KEYSIZE worth of bytes, and the second
    // KEYSIZE worth of bytes, and find the edit distance between them. Normalize
    // this result by dividing by KEYSIZE.
    const likely_key_size: u8 = %%cp.simple_likely_keysize(decoded_input);

    // Now that you probably know the KEYSIZE: break the ciphertext into blocks of
    // KEYSIZE length.
    var dest2: [585][]u8 = undefined;
    const chunks = cp.break_into_chunks(dest2[0..], decoded_input[0..], likely_key_size);

    // Now transpose the blocks: make a block that is the first byte of every block,
    // and a block that is the second byte of every block, and so on.

    var dest: [5000]u8 = undefined;
    var in = dest[0..];
    var transposed = cp.transpose_blocks(in, chunks[0..], likely_key_size);

    var transposed_chunks_buf: [10][]u8 = undefined;
    var transposed_chunks = cp.break_into_chunks(transposed_chunks_buf[0..], transposed, chunks.len);

    // for (transposed_chunks) |to| {
        // cp.printLn(to);
    // }


    var key: [5]u8 = undefined;
    for (transposed_chunks) |chunk, idx| {
        var buffer: [5000]u8 = undefined;
        var i:u8 = 0;
        var win:u32 = 0;
        var char:u8 = undefined;
        while (i < @maxValue(u8)) {
            var l = cp.one_char_xor(buffer[0..], chunk, i);
            var score = cp.scorer(l);
            if (score > win) {
                win = score;
                char = i;
            }
            i += 1;
        }
        key[idx] = char;
    }
    var destt: [5000]u8 = undefined;
    cp.repeating_key_xor(destt[0..], decoded_input, key);
    warn("{}", destt);
}
