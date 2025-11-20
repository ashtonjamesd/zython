pub const ObjectType = enum {
    Integer,
    String,
    Boolean,
    Identifier,
    Function,
};

pub const FunctionObject = struct {
    name: []const u8,
    arity: u8,
    bytecode_start: usize,
    bytecode_end: usize,
};

pub const Object = struct {
    value: union(ObjectType) {
        Integer: i32,
        String: []const u8,
        Boolean: bool,
        Identifier: []const u8,
        Function: FunctionObject,
    },

    pub inline fn newIntegerObject(value: i32) Object {
        return Object{
            .value = .{
                .Integer = value,
            },
        };
    }

    pub inline fn newStringObject(value: []const u8) Object {
        return Object{
            .value = .{
                .String = value,
            },
        };
    }

    pub inline fn newBoolObject(value: bool) Object {
        return Object{
            .value = .{
                .Boolean = value,
            },
        };
    }

    pub inline fn newIdentifierObject(value: []const u8) Object {
        return Object{
            .value = .{
                .Identifier = value,
            },
        };
    }

    pub inline fn newFunctionObject(name: []const u8, arity: u8, bytecode_start: usize, bytecode_end: usize) Object {
        return Object{
            .value = .{
                .Function = FunctionObject{
                    .name = name,
                    .arity = arity,
                    .bytecode_start = bytecode_start,
                    .bytecode_end = bytecode_end,
                },
            },
        };
    }
};
