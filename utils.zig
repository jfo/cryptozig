const warn = @import("std").debug.warn;

pub fn printLn(line: []u8) -> void {
    for (line) |c| warn("{c}", c);
}

pub fn readlines(dest: [][]u8, content: []u8) -> [][]u8 {
    var idx1:usize = 0;
    var idx2:usize = 0;
    for (content) |c, i| {
        if (c == '\n') {
            dest[idx1] = content[idx2..i+1];
            idx1 += 1;
            idx2 = i + 1;
        };
    };
    dest
}
