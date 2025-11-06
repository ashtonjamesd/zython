const std = @import("std");

const Ast = @import("../frontend/ast.zig");
const OperatorType = @import("../frontend/ast.zig").OperatorType;
const programMetadata = @import("../frontend/metadata.zig").Metadata;
const symbols = @import("symbol.zig");

pub const Analyzer = struct {
    hadError: bool = false,
    metadata: programMetadata,
    symbolTable: symbols.SymbolTable,
    alloc: std.mem.Allocator,

    pub fn new(alloc: std.mem.Allocator, metadata: programMetadata) Analyzer {
        return Analyzer{
            .alloc = alloc,
            .metadata = metadata,
            .symbolTable = symbols.SymbolTable{
                .symbols = std.ArrayList(symbols.Symbol).initCapacity(alloc, 128) catch {
                    @panic("failed to allocate analyzer symbol table");
                },
            },
        };
    }

    pub fn deinit(self: *Analyzer) void {
        self.symbolTable.symbols.deinit(self.alloc);
    }

    pub fn getSymbol(self: Analyzer, name: []const u8) !symbols.Symbol {
        for (self.symbolTable.symbols.items) |symbol| {
            if (std.mem.eql(u8, name, symbol.name)) {
                return symbol;
            }
        }

        return error{};
    }

    fn analyzeError(self: *Analyzer, message: []const u8) void {
        self.hadError = true;

        std.debug.print("File: {s}\n", .{self.metadata.path});
        std.debug.print("Analyze error: {s}\n", .{message});
    }

    fn analyzeWarning(self: Analyzer, message: []const u8) void {
        std.debug.print("File: {s}\n", .{self.metadata.path});
        std.debug.print("Analyze warning: {s}\n", .{message});
    }

    fn analyzeBinaryExpr(self: *Analyzer, expr: Ast.AstBinaryExpressionNode) void {
        if (expr.operator == OperatorType.Divide) {
            if (expr.right.as == .AstIntegerLiteral and expr.right.as.AstIntegerLiteral.value == 0) {
                self.analyzeError("cannot divide by zero");
            }
        }
    }

    fn foldConstants(self: *Analyzer, expr: Ast.AstNode) void {
        _ = self;
        if (expr.as == .AstIntegerLiteral) {}
    }

    fn analyzeIfStatement(self: *Analyzer, expr: Ast.AstIfStatementNode) void {
        _ = self;
        _ = expr;
    }

    fn analyzeCallExpr(self: *Analyzer, expr: Ast.AstCallExpressionNode) void {
        for (expr.parameters.items) |node| {
            self.analyzeNode(node);
        }
    }

    fn analyzeNode(self: *Analyzer, node: *Ast.AstNode) void {
        switch (node.as) {
            .AstBinaryExpression => self.analyzeBinaryExpr(node.as.AstBinaryExpression),
            .AstCallExpression => self.analyzeCallExpr(node.as.AstCallExpression),
            else => {},
        }
    }

    pub fn analyzeAst(self: *Analyzer, ast: Ast.Ast) void {
        for (ast.statements.items) |node| {
            self.analyzeNode(node);
        }
    }
};
