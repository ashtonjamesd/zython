const object = @import("../compiler/object.zig");

pub const CallFrame = struct {
    function: object.FunctionObject,
    ip: usize,
    stackStart: usize,

    pub fn new(function: object.FunctionObject, ip: usize, stackStart: usize) CallFrame {
        return CallFrame{
            .function = function,
            .ip = ip,
            .stackStart = stackStart,
        };
    }
};

const CALLSTACK_MAX = 1024;

pub const CallStack = struct {
    sfp: usize = 0,
    frames: [CALLSTACK_MAX]CallFrame,
};
