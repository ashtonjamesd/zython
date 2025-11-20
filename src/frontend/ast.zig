const std = @import("std");

pub const Ast = struct {
    statements: std.ArrayList(*AstNode),
};

pub const AstNodeType = enum {
    AstVariableDeclaration,
    AstIntegerLiteral,
    AstBooleanLiteral,
    AstIdentifier,
    AstBinaryExpression,
    AstUnaryExpression,
    AstCallExpression,
    AstFunctionDefinition,
    AstCompoundAssignment,
    AstAssert,
    AstRaise,
    AstIfStatement,
    AstPass,
    AstStringLiteral,
    AstWhileStatement,
    AstForStatement,
    AstBreak,
    AstContinue,
    AstReturn,
    AstTernary,
    AstError,
};

pub const OperatorType = enum {
    Plus,
    Minus,
    Multiply,
    Divide,
    Modulo,
    Exponentiation,
    FloorDivision,
    BitwiseAnd,
    BitwiseOr,
    BitwiseNot,
    BitwiseXor,
    BitwiseLeftShift,
    BitwiseRightShift,
    LessThan,
    LessThanOrEquals,
    GreaterThan,
    GreaterThanOrEquals,
    Equals,
    NotEquals,
    And,
    Or,
    Not,
    Walrus,
};

pub const AstNode = struct {
    as: union(AstNodeType) {
        AstVariableDeclaration: AstVariableDeclarationNode,
        AstIntegerLiteral: AstIntegerLiteralNode,
        AstBooleanLiteral: AstBooleanLiteralNode,
        AstIdentifier: AstIdentifierNode,
        AstBinaryExpression: AstBinaryExpressionNode,
        AstUnaryExpression: AstUnaryExpressionNode,
        AstCallExpression: AstCallExpressionNode,
        AstFunctionDefinition: AstFunctionDefinitionNode,
        AstCompoundAssignment: AstCompoundAssignmentNode,
        AstAssert: AstAssertNode,
        AstRaise: AstRaiseNode,
        AstIfStatement: AstIfStatementNode,
        AstPass: AstPassNode,
        AstStringLiteral: AstStringLiteralNode,
        AstWhileStatement: AstWhileStatementNode,
        AstForStatement: AstForStatementNode,
        AstBreak: AstBreakNode,
        AstContinue: AstContinueNode,
        AstReturn: AstReturnNode,
        AstTernary: AstTernaryNode,
        AstError: AstErrorNode,
    },
};

pub const FunctionArgument = struct {
    name: []const u8,

    pub fn new(name: []const u8) FunctionArgument {
        return FunctionArgument{
            .name = name,
        };
    }
};

pub const AstBreakNode = struct {
    pub fn new(allocator: std.mem.Allocator) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstBreakNode");
        };

        node.* = AstNode{
            .as = .{
                .AstBreak = AstBreakNode{},
            },
        };

        return node;
    }
};

pub const AstContinueNode = struct {
    pub fn new(allocator: std.mem.Allocator) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstContinueNode");
        };

        node.* = AstNode{
            .as = .{
                .AstContinue = AstContinueNode{},
            },
        };

        return node;
    }
};

pub const AstFunctionDefinitionNode = struct {
    name: []const u8,
    arguments: std.ArrayList(FunctionArgument),
    body: std.ArrayList(*AstNode),

    pub fn new(allocator: std.mem.Allocator, name: []const u8, arguments: std.ArrayList(FunctionArgument), body: std.ArrayList(*AstNode)) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstFunctionDefinitionNode");
        };

        node.* = AstNode{
            .as = .{
                .AstFunctionDefinition = AstFunctionDefinitionNode{
                    .name = name,
                    .arguments = arguments,
                    .body = body,
                },
            },
        };

        return node;
    }
};

pub const AstWhileStatementNode = struct {
    condition: *AstNode,
    body: std.ArrayList(*AstNode),

    pub fn new(allocator: std.mem.Allocator, condition: *AstNode, body: std.ArrayList(*AstNode)) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstIfStatementNode");
        };

        node.* = AstNode{
            .as = .{
                .AstWhileStatement = AstWhileStatementNode{
                    .condition = condition,
                    .body = body,
                },
            },
        };

        return node;
    }
};

pub const AstForStatementNode = struct {
    loopVariableName: []const u8,
    condition: *AstNode,
    body: std.ArrayList(*AstNode),

    pub fn new(allocator: std.mem.Allocator, condition: *AstNode, body: std.ArrayList(*AstNode), loopVariableName: []const u8) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstForStatementNode");
        };

        node.* = AstNode{
            .as = .{
                .AstForStatement = AstForStatementNode{
                    .condition = condition,
                    .body = body,
                    .loopVariableName = loopVariableName,
                },
            },
        };

        return node;
    }
};

pub const AstIfStatementNode = struct {
    condition: *AstNode,
    body: std.ArrayList(*AstNode),
    elseBody: std.ArrayList(*AstNode),

    pub fn new(allocator: std.mem.Allocator, condition: *AstNode, body: std.ArrayList(*AstNode), elseBody: std.ArrayList(*AstNode)) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstIfStatementNode");
        };

        node.* = AstNode{
            .as = .{
                .AstIfStatement = AstIfStatementNode{
                    .condition = condition,
                    .body = body,
                    .elseBody = elseBody,
                },
            },
        };

        return node;
    }
};

pub const AstCallExpressionNode = struct {
    callee: *AstNode,
    parameters: std.ArrayList(*AstNode),

    pub fn new(allocator: std.mem.Allocator, callee: *AstNode, parameters: std.ArrayList(*AstNode)) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstCallExpressionNode");
        };

        node.* = AstNode{
            .as = .{
                .AstCallExpression = AstCallExpressionNode{
                    .callee = callee,
                    .parameters = parameters,
                },
            },
        };

        return node;
    }
};

pub const AstBinaryExpressionNode = struct {
    left: *AstNode,
    operator: OperatorType,
    right: *AstNode,

    pub fn new(allocator: std.mem.Allocator, left: *AstNode, operator: OperatorType, right: *AstNode) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstBinaryExpressionNode");
        };

        node.* = AstNode{
            .as = .{
                .AstBinaryExpression = AstBinaryExpressionNode{
                    .left = left,
                    .operator = operator,
                    .right = right,
                },
            },
        };

        return node;
    }
};

pub const AstUnaryExpressionNode = struct {
    left: *AstNode,
    operator: OperatorType,

    pub fn new(allocator: std.mem.Allocator, left: *AstNode, operator: OperatorType) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstUnaryExpressionNode");
        };

        node.* = AstNode{
            .as = .{
                .AstUnaryExpression = AstUnaryExpressionNode{
                    .left = left,
                    .operator = operator,
                },
            },
        };

        return node;
    }
};

pub const AstReturnNode = struct {
    value: *AstNode,

    pub fn new(allocator: std.mem.Allocator, value: *AstNode) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstReturnNode");
        };

        node.* = AstNode{
            .as = .{
                .AstReturn = AstReturnNode{
                    .value = value,
                },
            },
        };

        return node;
    }
};

pub const AstRaiseNode = struct {
    value: *AstNode,

    pub fn new(allocator: std.mem.Allocator, value: *AstNode) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstRaiseNode");
        };

        node.* = AstNode{
            .as = .{
                .AstRaise = AstRaiseNode{
                    .value = value,
                },
            },
        };

        return node;
    }
};

pub const AstPassNode = struct {
    pub fn new(allocator: std.mem.Allocator) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstPassNode");
        };

        node.* = AstNode{
            .as = .{
                .AstPass = AstPassNode{},
            },
        };

        return node;
    }
};

pub const AstAssertNode = struct {
    value: *AstNode,

    pub fn new(allocator: std.mem.Allocator, value: *AstNode) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstAssertNode");
        };

        node.* = AstNode{
            .as = .{
                .AstAssert = AstAssertNode{
                    .value = value,
                },
            },
        };

        return node;
    }
};

pub const AstCompoundAssignmentNode = struct {
    name: []const u8,
    operator: OperatorType,
    value: *AstNode,

    pub fn new(allocator: std.mem.Allocator, name: []const u8, operator: OperatorType, value: *AstNode) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstCompoundAssignmentNode");
        };

        node.* = AstNode{
            .as = .{
                .AstCompoundAssignment = AstCompoundAssignmentNode{
                    .name = name,
                    .operator = operator,
                    .value = value,
                },
            },
        };

        return node;
    }
};

pub const AstVariableDeclarationNode = struct {
    name: []const u8,
    value: *AstNode,

    pub fn new(allocator: std.mem.Allocator, name: []const u8, value: *AstNode) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstVariableDeclarationNode");
        };

        node.* = AstNode{
            .as = .{
                .AstVariableDeclaration = AstVariableDeclarationNode{
                    .name = name,
                    .value = value,
                },
            },
        };

        return node;
    }
};

pub const AstTernaryNode = struct {
    value_if_true: *AstNode,
    condition: *AstNode,
    value_if_false: *AstNode,

    pub fn new(allocator: std.mem.Allocator, value_if_true: *AstNode, condition: *AstNode, value_if_false: *AstNode) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstTernaryNode");
        };

        node.* = AstNode{
            .as = .{
                .AstTernary = AstTernaryNode{
                    .value_if_true = value_if_true,
                    .condition = condition,
                    .value_if_false = value_if_false,
                },
            },
        };

        return node;
    }
};

pub const AstIntegerLiteralNode = struct {
    value: i32,

    pub fn new(allocator: std.mem.Allocator, value: i32) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstIntegerLiteralNode");
        };

        node.* = AstNode{
            .as = .{
                .AstIntegerLiteral = AstIntegerLiteralNode{ .value = value },
            },
        };

        return node;
    }
};

pub const AstIdentifierNode = struct {
    name: []const u8,

    pub fn new(allocator: std.mem.Allocator, name: []const u8) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstIdentifierNode");
        };

        node.* = AstNode{
            .as = .{
                .AstIdentifier = AstIdentifierNode{
                    .name = name,
                },
            },
        };

        return node;
    }
};

pub const AstBooleanLiteralNode = struct {
    value: bool,

    pub fn new(allocator: std.mem.Allocator, value: bool) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstBooleanLiteralNode");
        };

        node.* = AstNode{
            .as = .{
                .AstBooleanLiteral = AstBooleanLiteralNode{
                    .value = value,
                },
            },
        };

        return node;
    }
};

pub const AstStringLiteralNode = struct {
    value: []const u8,

    pub fn new(allocator: std.mem.Allocator, value: []const u8) *AstNode {
        const node = allocator.create(AstNode) catch {
            @panic("Failed to allocate memory for AstStringLiteralNode");
        };

        node.* = AstNode{
            .as = .{
                .AstStringLiteral = AstStringLiteralNode{
                    .value = value,
                },
            },
        };

        return node;
    }
};

pub const AstErrorNode = struct {};
