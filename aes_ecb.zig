const std = @import("std");
const assert = std.debug.assert;

fn aes128ecb(key: []const u8, input: []const u8, output: []u8) []const u8 {
    for (input) |e, i| output[i] = e;
    return output;
}

test "run AES in ECB mode" {
    const key: []const u8 = "YELLOW SUBMARINE";
    const input: []const u8 = "abcdefghijklmnop";
    const expected_output = "\x79\xf7\xdd\x52\x0b\xec\x8f\xb7\x25\xd9\xef\xe2\xec\xb3\xc4\xb1\xdc\x76\x91\x85\xb4\xea\xcf\xc8\x44\xba\xea\x1f\xad\x49\xe8\xa1";

    var outbuf: [16]u8 = undefined;
    _ = aes128ecb(key, input, outbuf[0..]);

    assert(std.mem.eql(u8, outbuf, expected_output));
}
