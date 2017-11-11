const warn = @import("std").debug.warn;
const assert = @import("std").debug.assert;

test "immutable slices?" {
    var array = "hi mom";
    const slice = array[0..2];

    warn("\n{}\n", array); // hi mom
    warn("{}\n", slice); // hi

    // ok, it's `var`
    array[0] = 's';
    warn("{}\n", array); // si mom
    warn("{}\n", slice); // si

    // this works... but `slice` is `const`, which I would think is like an
    // immutable read only borrow?
    slice[1] = 's';
    warn("{}\n", array); // ss mom
    warn("{}\n", slice); // ss

    // The inverse acts as I would expect:
    const im_array = "hi dad";
    var im_slice = im_array[0..2];
    // im_array[0] = 's'; error: cannot assign to constant
    // im_slice[0] = 's'; error: cannot assign to constant
}

test "slice pointer" {
    const array: [10]u8 = undefined;
    const ptr = &array[0];

    // You can use slicing syntax to convert a pointer into a slice:
    const slice = ptr[0..5];
    slice[2] = 3;
    assert(slice[2] == 3);
    // The slice is mutable because we sliced a mutable pointer.
    assert(@typeOf(slice) == []u8);

    // You can also slice a slice:
    const slice2 = slice[2..3];
    assert(slice2.len == 1);
    assert(slice2[0] == 3);
}
