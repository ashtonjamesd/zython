const std = @import("std");

pub const Symbol = struct {
    name: []const u8,
};

pub const SymbolTable = struct {
    symbols: std.ArrayList(Symbol),
};
