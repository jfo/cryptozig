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
    // TODO: handle odd case
    while (i < src.len - 1) {
        dest[i / 2] = hexDigit(src[i]) << 4 | hexDigit(src[i + 1]);
        i+=2;
    }
    return dest[0..src.len / 2 ];
}

pub fn one_char_xor(dest: []u8, src: []const u8, c:u8) -> []u8 {
    for (src) |char, i| dest[i] = char ^ c;
    dest[0..]
}

// scores for both ascii and spaces.
pub fn scorer(src: []const u8) -> u32 {
    var count:u32 = 0;
    for (src) |char| {
        count += (switch (char) {
            ' ' => u32(2),
            '!'...122 => 1,
            else => 0,
        })
    }
    count
}

pub fn printLn(line: []u8) -> void {
    for (line) |c| {
        warn("{x02} ", c);
    }
    warn("\n");
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

pub fn repeating_key_xor(dest: []u8, src: []const u8, key: []const u8) -> void {
    for (src) |e, i| dest[i] = key[i % key.len] ^ e
}

// this prints backwards rn a doy
fn printb(nq:u8)->void {
    var n = nq;
    while (n != 0) {
        if (n & 1 != 0) warn("1") else warn("0");
        n >>= 1;
    }
}
pub fn hamming(x:u8, y:u8) -> u4 {
    var val = x ^ y;
    var dist:u4 = 0;
    while (val != 0) {
        dist += 1;
        val &= val - 1;
    }
    dist
}

error UnevenInput;
error InsufficientInput;

pub fn hamming_distance(x: []const u8, y: []const u8) -> %u32 {
    if (x.len != y.len) return error.UnevenInput;
    var out:u32 = 0;
    for (x) |cx, i| out += hamming(cx, y[i]);
    out
}

pub fn keysize_hamming(src: []const u8, keysize: u32) -> %u32 {
    if (src.len < keysize * 2) return error.InsufficientInput;
    const chunk_one = src[0..keysize];
    const chunk_two = src[keysize..keysize*2];
    %%hamming_distance(chunk_one, chunk_two)
}

// up to 40
pub fn find_repeating_xor_keysize(src: []const u8) -> %u8 {
    const max_keysize_attempt = 40;
    // if (src.len < max_keysize_attempt * 2) return error.InsufficientInput;

    // @maxValue(f32); TODO analyze_min_max_value float
    var smallest_edit_size: f32 = 30.0;
    var likely_key_size: u8 = undefined;

    var i: u8 = 1;
    while (i < max_keysize_attempt) {
        var out: f32 = 0.0;
        var idx: u32 = 0;
        while (idx < src.len - (idx * i)) {
            out += f32(%%keysize_hamming(src[i * idx..], i)) / f32(i);
            idx += 1;
        }
        const distance: f32 = out / f32(idx);

        if (distance < smallest_edit_size) {
            smallest_edit_size = distance;
            likely_key_size = i;
        }
        i += 1;
    }
    likely_key_size
}

fn detect_single_character_xor(input: []const u8) -> u8 {
    var i:u8 = 0;

    var winner: u8 = undefined;
    var last_winner_score:u32 = 0;
    while (i < @maxValue(u8)) {
        var buffer: [500]u8 = undefined;

        var l = one_char_xor(buffer[0..], input, i);

        const score = scorer(l);
        // warn("{}: {}\n", score, l[0..100]);

        if (score > last_winner_score) {
            last_winner_score = score;
            winner = i;
        }
        i += 1;
    }
    winner
}

pub fn find_repeating_xor_key(output: []u8, input: []u8) -> []u8 {
    const keysize = %%find_repeating_xor_keysize(input);

    var dest: [64 * 64][]u8 = undefined;
    const chunks = break_into_chunks(dest[0..], input, keysize);

    var dest2: [64 * 64]u8 = undefined;
    const transposed_arr = transpose_blocks(dest2[0..], chunks, keysize);

    var dest3: [64 * 64][]u8 = undefined;
    const transposed_chunks = break_into_chunks(dest3[0..], transposed_arr, chunks.len);

   for (transposed_chunks) |chunk, i| {
        output[i] = detect_single_character_xor(chunk);
    }
    output[0..transposed_chunks.len]
}


pub fn break_into_chunks(dest: [][]u8, src: []u8, chunksize: usize) -> [][]u8 {
    dest[0] = src[0..chunksize];
    var idx:usize = 1;
    while (idx < src.len / chunksize) {
        dest[idx] = src[chunksize * idx..chunksize * idx + chunksize];
        idx += 1;
    }
    dest[0..src.len / chunksize]
}

pub fn transpose_blocks(dest: []u8, src: [][]const u8, keysize: u8) -> []u8 {
    var out: [][]u8 = undefined;

    var i: u32 = 0;
    var id: u32 = 0;

    while (i < keysize) {
        for (src) |row, idx| {
            dest[idx + id] = row[i];
        }
        i += 1;
        id += u32(src.len);
    }

    dest[0..src.len*keysize]
}
