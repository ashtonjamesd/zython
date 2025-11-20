const std = @import("std");

const Zython = @import("zvm.zig");
const object = @import("../compiler/object.zig");

pub inline fn printObject(self: *Zython.ZythonVm, n: object.Object) void {
    const stdout = &self.stdoutWriter.interface;

    switch (n.value) {
        .Boolean => {
            stdout.print("{}\n", .{n.value.Boolean}) catch return;
        },
        .Integer => {
            stdout.print("{}\n", .{n.value.Integer}) catch return;
        },
        .Identifier => {
            stdout.print("{s}\n", .{n.value.Identifier}) catch return;
        },
        .String => {
            stdout.print("{s}\n", .{n.value.String}) catch return;
        },
        .Function => {
            stdout.print("Function '{s}'\n", .{n.value.Function.name}) catch return;
        },
    }
}

pub inline fn abs(_: *Zython.ZythonVm, n: object.Object) u32 {
    return @abs(n.value.Integer);
}

pub inline fn len(_: *Zython.ZythonVm, n: object.Object) usize {
    return switch (n.value) {
        .String => n.value.String.len,
        else => 0,
    };
}

pub inline fn int(_: *Zython.ZythonVm, n: object.Object) i32 {
    return switch (n.value) {
        .Boolean => if (n.value.Boolean) 1 else 0,
        .String => std.fmt.parseInt(i32, n.value.String, 10) catch 0,
        .Integer => n.value.Integer,
        else => 0,
    };
}

pub inline fn ord(_: *Zython.ZythonVm, n: object.Object) i32 {
    return switch (n.value) {
        .String => |s| {
            if (s.len != 1) return 0;
            return @intCast(s[0]);
        },
        else => 0,
    };
}
