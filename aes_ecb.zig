const std = @import("std");
const warn = std.debug.warn;
const assert = std.debug.assert;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const alloc = arena.allocator.alloc;

fn subBytes() void {}
fn shiftRows() void  {}
fn mixColumns() void  {}
fn addRoundKey() void  {}

fn aes128ecb(key: []const u8, input: []const u8) ![]const u8 {
    const output = try alloc(u8, input.len);
    for (input) |e, i| output[i] = e;
    return output;
}

// test "run AES in ECB mode" {
pub fn main() !void {
    defer arena.deinit();

    const key: []const u8 = "YELLOW SUBMARINE";
    const input: []const u8 = "abcdefghijklmnop";
    const expected_output = "\xBD\xB1\x84\xD4N\x1F\xC1\xD3\x06\tE\xB5<\x99OH`\xFA6p~E\xF4\x99\xDB\xA0\xF2[\x92#\x01\xA5";

    const output = try aes128ecb(key, input);

    warn("{}\n", output);
    // assert(std.mem.eql(u8, outbuf, expected_output));
}
