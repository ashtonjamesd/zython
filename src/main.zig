const std = @import("std");
const zython = @import("runtime/zython.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }
    const alloc = gpa.allocator();

    var args = try std.process.argsWithAllocator(alloc);
    defer args.deinit();

    _ = args.next();

    const path = args.next();
    if (path == null) {
        std.debug.print("Usage: zython <script_path>\n", .{});
        return;
    }

    var debug = false;

    const flag = args.next() orelse "";
    if (std.mem.eql(u8, flag, "-d")) {
        debug = true;
    }

    const config = zython.ZythonRuntimeConfig{
        .debug = debug,
    };

    var runtime = zython.ZythonRuntime.new(path.?, alloc, config);
    if (runtime.run() != zython.RuntimeResult.Success) {
        return;
    }
}
