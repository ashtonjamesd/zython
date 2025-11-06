const std = @import("std");

const compiler = @import("../compiler/compiler.zig");
const object = @import("../compiler/object.zig");
const operatorType = @import("../frontend/ast.zig").OperatorType;
const opcode = @import("../compiler/instruction.zig").Instruction;
const builtin = @import("builtins.zig");
const callstack = @import("callstack.zig");

const STACK_SIZE = 1024;

pub const ZythonVm = struct {
    program: compiler.Program,
    pc: u32 = 0,
    stack: [STACK_SIZE]object.Object = undefined,
    sp: usize = 0,
    alloc: std.mem.Allocator,
    callstack: callstack.CallStack,
    stdoutBuffer: [1024]u8 = undefined,
    stdoutWriter: std.fs.File.Writer,

    const OpHandler = fn (*ZythonVm) void;
    const jumpTable = [_]OpHandler{
        // .. eventually
    };

    pub fn new(program: compiler.Program, alloc: std.mem.Allocator) ZythonVm {
        var vm = ZythonVm{
            .program = program,
            .alloc = alloc,
            .callstack = callstack.CallStack{
                .frames = undefined,
            },
            .stdoutWriter = undefined,
        };

        initStdoutWriter(&vm);

        return vm;
    }

    fn initStdoutWriter(vm: *ZythonVm) void {
        vm.stdoutWriter = std.fs.File.stdout().writer(&vm.stdoutBuffer);
    }

    pub fn deinit(self: *ZythonVm) void {
        self.program.globalVariables.deinit();
    }

    pub fn execute(self: *ZythonVm) void {
        const start = std.time.nanoTimestamp();

        while (self.pc < self.program.bytecode.items.len) {
            self.executeInstr();
            self.tick();
        }

        const stdout = &self.stdoutWriter.interface;
        stdout.flush() catch return;

        const end = std.time.nanoTimestamp();

        const elapsed_ns = end - start;
        const elapsed_ms = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0;

        std.debug.print("Execution took {d:.3} ms\n", .{elapsed_ms});
    }

    inline fn executeInstr(self: *ZythonVm) void {
        const instr = self.program.bytecode.items[self.pc];

        switch (instr) {
            0x00 => self.executePush(),
            0x01 => self.executeArithmeticBinary(operatorType.Plus),
            0x02 => self.executeArithmeticBinary(operatorType.Minus),
            0x03 => self.executeArithmeticBinary(operatorType.Multiply),
            0x04 => self.executeArithmeticBinary(operatorType.Divide),
            0x05 => self.executeArithmeticBinary(operatorType.Modulo),
            0x06 => self.executeCall(),
            0x07 => self.executeStoreGlobal(),
            0x08 => self.executeLoadGlobal(),
            0x09 => self.executeUnary(operatorType.Minus),
            0x0a => self.executeArithmeticBinary(operatorType.Exponentiation),
            0x0b => self.executeArithmeticBinary(operatorType.FloorDivision),
            0x0c => self.executeArithmeticBinary(operatorType.BitwiseAnd),
            0x0d => self.executeArithmeticBinary(operatorType.BitwiseOr),
            0x0e => self.executeUnary(operatorType.BitwiseNot),
            0x0f => self.executeArithmeticBinary(operatorType.BitwiseXor),
            0x10 => self.executeArithmeticBinary(operatorType.BitwiseLeftShift),
            0x11 => self.executeArithmeticBinary(operatorType.BitwiseRightShift),
            0x12 => self.executeUnary(operatorType.Plus),
            0x13 => self.executeRelationalBinary(operatorType.LessThan),
            0x14 => self.executeRelationalBinary(operatorType.GreaterThan),
            0x15 => self.executeRelationalBinary(operatorType.LessThanOrEquals),
            0x16 => self.executeRelationalBinary(operatorType.GreaterThanOrEquals),
            0x17 => self.executeComparativeBinary(operatorType.Equals),
            0x18 => self.executeComparativeBinary(operatorType.NotEquals),
            0x19 => self.executeLogicalBinary(operatorType.And),
            0x1a => self.executeLogicalBinary(operatorType.Or),
            0x1b => self.executeLogicalUnary(operatorType.Not),
            0x1c => self.executeJumpIfFalse(),
            0x1d => self.executeNop(),
            0x1e => self.executeJump(),
            0x1f => self.executePushConstantWide(),
            else => @panic("Unknown opcode in zvm"),
        }
    }

    inline fn executePushConstantWide(self: *ZythonVm) void {
        self.tick();

        const lowByte = self.currentInstruction();
        self.tick();
        const highByte = self.currentInstruction();

        const index = (@as(u16, @intCast(highByte)) << 8) | @as(u16, @intCast(lowByte));

        const constant = self.constantAt(index);

        self.push(constant);
    }

    inline fn executeJump(self: *ZythonVm) void {
        self.tick();
        const lowByte = self.currentInstruction();
        self.tick();
        const highByte = self.currentInstruction();

        const jumpOffset = @as(i16, lowByte) | @as(i16, highByte) << 8;

        const newPc = @as(i32, @intCast(self.pc)) + @as(i32, jumpOffset);
        self.pc = @intCast(newPc);
    }

    inline fn executeNop(_: *ZythonVm) void {}

    inline fn executeJumpIfFalse(self: *ZythonVm) void {
        const conditionObj = self.pop();

        if (conditionObj.value != .Boolean) {
            @panic("JumpIfFalse expects a boolean value");
        }

        const condition = conditionObj.value.Boolean;

        if (!condition) {
            self.executeJump();
        } else {
            self.tick();
            self.tick();
        }
    }

    fn executeLoadGlobal(self: *ZythonVm) void {
        const name = self.pop();

        const value = self.program.globalVariables.get(name.value.Identifier) orelse {
            @panic("Undefined global variable");
        };

        self.push(value);
    }

    fn executeStoreGlobal(self: *ZythonVm) void {
        const name = self.pop();
        const value = self.pop();

        self.program.globalVariables.put(name.value.Identifier, value) catch {
            @panic("Failed to create new global variable");
        };
    }

    inline fn executeCall(self: *ZythonVm) void {
        const callee = self.pop();

        if (std.mem.eql(u8, callee.value.Identifier, "print")) {
            const argument = self.pop();
            builtin.printObject(self, argument);
        } else {}
    }

    inline fn executePush(self: *ZythonVm) void {
        self.tick();

        const constant = self.pluckConstant();
        self.push(constant);
    }

    fn executeUnary(self: *ZythonVm, operator: operatorType) void {
        const aObj = self.pop();

        const a = aObj.value.Integer;

        const result: i32 = switch (operator) {
            operatorType.Minus => -a,
            operatorType.BitwiseNot => ~a,
            operatorType.Plus => @intCast(@abs(a)),
            else => @panic("invalid unary operator"),
        };

        const obj = object.Object.newIntegerObject(result);
        self.push(obj);
    }

    fn executeLogicalUnary(self: *ZythonVm, operator: operatorType) void {
        const aObj = self.pop();

        const a = aObj.value.Boolean;

        const result = switch (operator) {
            operatorType.Not => !a,
            else => @panic("invalid unary operator"),
        };

        const obj = object.Object.newBoolObject(result);
        self.push(obj);
    }

    fn executeLogicalBinary(self: *ZythonVm, operator: operatorType) void {
        const bObj = self.pop();
        const aObj = self.pop();

        const a = aObj.value.Boolean;
        const b = bObj.value.Boolean;

        const result = switch (operator) {
            operatorType.And => a and b,
            operatorType.Or => a or b,
            else => @panic("invalid binary operator"),
        };

        const obj = object.Object.newBoolObject(result);
        self.push(obj);
    }

    fn executeComparativeBinary(self: *ZythonVm, operator: operatorType) void {
        const bObj = self.pop();
        const aObj = self.pop();

        var result = false;
        if (aObj.value == .Integer) {
            result = switch (operator) {
                operatorType.Equals => aObj.value.Integer == bObj.value.Integer,
                operatorType.NotEquals => aObj.value.Integer != bObj.value.Integer,
                else => @panic("invalid comparative binary operator"),
            };
        } else if (aObj.value == .String) {
            result = switch (operator) {
                operatorType.Equals => std.mem.eql(u8, aObj.value.String, bObj.value.String),
                operatorType.NotEquals => !std.mem.eql(u8, aObj.value.String, bObj.value.String),
                else => @panic("invalid comparative binary operator"),
            };
        } else if (aObj.value == .Boolean) {
            result = switch (operator) {
                operatorType.Equals => aObj.value.Boolean == bObj.value.Boolean,
                operatorType.NotEquals => aObj.value.Boolean != bObj.value.Boolean,
                else => @panic("invalid comparative binary operator"),
            };
        } else {
            // result = switch (operator) {
            //     operatorType.Equals => aObj == bObj,
            //     operatorType.NotEquals => aObj != bObj,
            //     else => @panic("invalid comparative binary operator"),
            // };
        }

        const obj = object.Object.newBoolObject(result);
        self.push(obj);
    }

    inline fn executeRelationalBinary(self: *ZythonVm, operator: operatorType) void {
        const bObj = self.pop();
        const aObj = self.pop();

        const a = aObj.value.Integer;
        const b = bObj.value.Integer;

        const result = switch (operator) {
            operatorType.LessThan => a < b,
            operatorType.GreaterThan => a > b,
            operatorType.LessThanOrEquals => a <= b,
            operatorType.GreaterThanOrEquals => a >= b,
            else => @panic("invalid relational binary operator"),
        };

        self.stack[self.sp] = object.Object.newBoolObject(result);
        self.sp += 1;
    }

    inline fn executeArithmeticBinary(self: *ZythonVm, operator: operatorType) void {
        const bObj = self.pop();
        const aObj = self.pop();

        const a = aObj.value.Integer;
        const b = bObj.value.Integer;

        const result = switch (operator) {
            operatorType.Plus => a +% b,
            operatorType.Minus => a -% b,
            operatorType.Multiply => a *% b,
            // needs amending to support floating point numbers
            operatorType.Divide => @divFloor(a, b),
            operatorType.Modulo => @mod(a, b),
            operatorType.Exponentiation => std.math.pow(i32, a, b),
            operatorType.FloorDivision => @divFloor(a, b),
            operatorType.BitwiseAnd => a & b,
            operatorType.BitwiseOr => a | b,
            operatorType.BitwiseXor => a ^ b,
            operatorType.BitwiseLeftShift => @panic("idk"),
            operatorType.BitwiseRightShift => @panic("idk"),
            // operatorType.BitwiseLeftShift => a << b,
            // operatorType.BitwiseRightShift => a >> b,
            else => @panic("invalid arithmetic binary operator"),
        };

        self.stack[self.sp] = object.Object.newIntegerObject(result);
        self.sp += 1;
    }

    inline fn pluckConstant(self: *ZythonVm) object.Object {
        const index = self.currentInstruction();
        const constant = self.constantAt(index);

        return constant;
    }

    inline fn pop(self: *ZythonVm) object.Object {
        self.sp -= 1;
        const n = self.stack[self.sp];

        return n;
    }

    inline fn push(self: *ZythonVm, value: object.Object) void {
        self.stack[self.sp] = value;
        self.sp += 1;
    }

    inline fn constantAt(self: *ZythonVm, index: u16) object.Object {
        return self.program.constantPool.items[index];
    }

    inline fn currentInstruction(self: *ZythonVm) u8 {
        return self.program.bytecode.items[self.pc];
    }

    inline fn tick(self: *ZythonVm) void {
        self.pc += 1;
    }
};
