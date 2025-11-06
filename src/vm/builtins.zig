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
