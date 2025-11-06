const std = @import("std");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");
const programMetadata = @import("../frontend/metadata.zig").Metadata;

const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;

pub const ParseError = error{
    ExpectError,
};

pub const Parser = struct {
    program: ast.Ast,
    alloc: std.mem.Allocator,
    position: usize = 0,
    tokens: std.ArrayList(Token),
    hadError: bool = false,
    errorMessage: []const u8,
    metadata: programMetadata,

    pub fn new(alloc: std.mem.Allocator, tokens: std.ArrayList(Token), metadata: programMetadata) Parser {
        return Parser{
            .program = ast.Ast{
                .statements = std.ArrayList(*ast.AstNode).initCapacity(alloc, 4096) catch {
                    @panic("Failed to allocate memory for AST Statements");
                },
            },
            .alloc = alloc,
            .tokens = tokens,
            .errorMessage = "",
            .metadata = metadata,
        };
    }

    fn deinitNode(self: *Parser, node: *ast.AstNode) void {
        switch (node.as) {
            .AstCallExpression => {
                for (node.as.AstCallExpression.parameters.items) |item| {
                    self.deinitNode(item);
                }
                node.as.AstCallExpression.parameters.deinit(self.alloc);
                self.deinitNode(node.as.AstCallExpression.callee);
            },
            .AstBinaryExpression => {
                self.deinitNode(node.as.AstBinaryExpression.left);
                self.deinitNode(node.as.AstBinaryExpression.right);
            },
            .AstUnaryExpression => {
                self.deinitNode(node.as.AstUnaryExpression.left);
            },
            .AstVariableDeclaration => {
                self.deinitNode(node.as.AstVariableDeclaration.value);
            },
            .AstCompoundAssignment => {
                self.deinitNode(node.as.AstCompoundAssignment.value);
            },
            .AstIfStatement => {
                self.deinitNode(node.as.AstIfStatement.condition);
                for (node.as.AstIfStatement.body.items) |item| {
                    self.deinitNode(item);
                }
                node.as.AstIfStatement.body.deinit(self.alloc);

                for (node.as.AstIfStatement.elseBody.items) |item| {
                    self.deinitNode(item);
                }
                node.as.AstIfStatement.elseBody.deinit(self.alloc);
            },
            .AstWhileStatement => {
                self.deinitNode(node.as.AstWhileStatement.condition);
                for (node.as.AstWhileStatement.body.items) |item| {
                    self.deinitNode(item);
                }
                node.as.AstWhileStatement.body.deinit(self.alloc);
            },
            .AstFunctionDefinition => {
                node.as.AstFunctionDefinition.arguments.deinit(self.alloc);
                for (node.as.AstFunctionDefinition.body.items) |stmt| {
                    self.deinitNode(stmt);
                }
                node.as.AstFunctionDefinition.body.deinit(self.alloc);
            },
            .AstAssert => {
                self.deinitNode(node.as.AstAssert.value);
            },
            .AstRaise => {
                self.deinitNode(node.as.AstRaise.value);
            },
            else => {},
        }

        self.alloc.destroy(node);
    }

    pub fn deinit(self: *Parser) void {
        for (self.program.statements.items) |node| {
            self.deinitNode(node);
        }

        self.program.statements.deinit(self.alloc);
    }

    fn printDepth(depth: u32) void {
        for (0..depth) |_| {
            std.debug.print(" ", .{});
        }
    }

    pub fn printNode(self: Parser, node: *ast.AstNode, depth: u32) void {
        printDepth(depth);

        switch (node.as) {
            .AstError => {
                std.debug.print("Error Node\n", .{});
            },
            .AstPass => {
                std.debug.print("Pass Node\n", .{});
            },
            .AstFunctionDefinition => {
                std.debug.print("Function Definition({s}):\n", .{node.as.AstFunctionDefinition.name});

                printDepth(depth + 1);
                std.debug.print("Body: \n", .{});
                for (node.as.AstFunctionDefinition.body.items) |stmt| {
                    self.printNode(stmt, depth + 2);
                }
            },
            .AstIfStatement => {},
            .AstWhileStatement => {},
            .AstForStatement => {},
            .AstBreak => {
                std.debug.print("Break\n", .{});
            },
            .AstContinue => {
                std.debug.print("Continue\n", .{});
            },
            .AstAssert => {
                std.debug.print("Assert\n", .{});

                printDepth(depth + 1);
                std.debug.print("Value: ", .{});
                self.printNode(node.as.AstAssert.value, depth + 2);
            },
            .AstRaise => {
                std.debug.print("Raise\n", .{});

                printDepth(depth + 1);
                std.debug.print("Value: ", .{});
                self.printNode(node.as.AstRaise.value, depth + 2);
            },
            .AstCompoundAssignment => {
                std.debug.print("Compound Assignment\n", .{});

                printDepth(depth + 1);
                std.debug.print("Operator: ", .{});
                std.debug.print("{}", .{node.as.AstCompoundAssignment.operator});

                std.debug.print("\n", .{});
                printDepth(depth + 1);
                std.debug.print("Name: {s}\n", .{node.as.AstCompoundAssignment.name});

                printDepth(depth + 1);
                std.debug.print("Right:\n", .{});
                self.printNode(node.as.AstCompoundAssignment.value, depth + 2);
            },
            .AstBinaryExpression => {
                std.debug.print("Binary Expression\n", .{});

                printDepth(depth + 1);
                std.debug.print("Operator: ", .{});
                std.debug.print("{}", .{node.as.AstBinaryExpression.operator});

                std.debug.print("\n", .{});
                printDepth(depth + 1);
                std.debug.print("Left:\n", .{});
                self.printNode(node.as.AstBinaryExpression.left, depth + 2);

                std.debug.print("\n", .{});
                printDepth(depth + 1);
                std.debug.print("Right:\n", .{});
                self.printNode(node.as.AstBinaryExpression.right, depth + 2);
            },
            .AstUnaryExpression => {
                std.debug.print("Unary Expression\n", .{});

                printDepth(depth + 1);
                std.debug.print("Operator: ", .{});
                std.debug.print("{}", .{node.as.AstUnaryExpression.operator});

                std.debug.print("\n", .{});
                printDepth(depth + 1);
                std.debug.print("Left:\n", .{});
                self.printNode(node.as.AstUnaryExpression.left, depth + 2);
            },
            .AstCallExpression => {
                std.debug.print("Call Expression\n", .{});

                printDepth(depth + 1);
                std.debug.print("Callee:", .{});
                self.printNode(node.as.AstCallExpression.callee, depth);

                printDepth(depth + 1);
                std.debug.print("Parameters: \n", .{});
                for (node.as.AstCallExpression.parameters.items) |parameter| {
                    printDepth(depth + 2);
                    std.debug.print("Parameter:", .{});
                    self.printNode(parameter, depth);
                }
            },
            .AstIntegerLiteral => {
                std.debug.print("Integer({})\n", .{node.as.AstIntegerLiteral.value});
            },
            .AstIdentifier => {
                std.debug.print("Identifier({s})\n", .{node.as.AstIdentifier.name});
            },
            .AstBooleanLiteral => {
                std.debug.print("Boolean({})\n", .{node.as.AstBooleanLiteral.value});
            },
            .AstStringLiteral => {
                std.debug.print("String({s})\n", .{node.as.AstStringLiteral.value});
            },
            .AstVariableDeclaration => {
                std.debug.print("Variable Declaration({s}):\n", .{node.as.AstVariableDeclaration.name});

                printDepth(depth + 1);
                std.debug.print("Value:\n", .{});
                self.printNode(node.as.AstVariableDeclaration.value, depth + 1);
            },
        }
    }

    pub fn print(self: Parser) void {
        std.debug.print("\nParser AST:\n", .{});
        for (self.program.statements.items) |node| {
            self.printNode(node, 1);
        }

        std.debug.print("\n", .{});
    }

    pub fn parseAst(self: *Parser) void {
        while (!self.isEnd()) {
            const node = self.parseNode();

            self.program.statements.append(self.alloc, node) catch {
                @panic("Failed to add node into AST");
            };
        }
    }

    fn parseNode(self: *Parser) *ast.AstNode {
        while (self.match(TokenType.Newline)) {
            self.advance();
        }

        return switch (self.currentToken().tokenType) {
            TokenType.Identifier => self.parseIdentifier(),
            TokenType.Def => self.parseFunctionDefinition(),
            TokenType.Assert => self.parseAssert(),
            TokenType.Raise => self.parseRaise(),
            TokenType.If => self.parseIf(),
            TokenType.Pass => self.parsePass(),
            TokenType.While => self.parseWhile(),
            TokenType.Break => self.parseBreak(),
            TokenType.Continue => self.parseContinue(),
            TokenType.For => self.parseFor(),
            else => self.parseExpression(),
        };
    }

    fn parseFor(self: *Parser) *ast.AstNode {
        if (!self.expect(TokenType.For)) {
            return self.syntaxError("expected 'for'");
        }

        const loopVariableName = self.currentToken();
        if (!self.match(TokenType.Identifier)) {
            return self.syntaxError("expected identifier");
        }

        if (!self.expect(TokenType.In)) {
            return self.syntaxError("expected 'in'");
        }

        const expression = self.parseExpression();
        const body = self.parseIndentBlock();

        return ast.AstForStatementNode.new(self.alloc, expression, body, loopVariableName.lexeme);
    }

    fn parseContinue(self: *Parser) *ast.AstNode {
        if (!self.expect(TokenType.Continue)) {
            return self.syntaxError("expected 'continue'");
        }

        while (self.match(TokenType.Newline)) {
            self.advance();
        }

        return ast.AstContinueNode.new(self.alloc);
    }

    fn parseBreak(self: *Parser) *ast.AstNode {
        if (!self.expect(TokenType.Break)) {
            return self.syntaxError("expected 'break'");
        }

        while (self.match(TokenType.Newline)) {
            self.advance();
        }

        return ast.AstBreakNode.new(self.alloc);
    }

    fn parseWhile(self: *Parser) *ast.AstNode {
        if (!self.expect(TokenType.While)) {
            return self.syntaxError("expected 'while'");
        }

        const condition = self.parseExpression();
        const body = self.parseIndentBlock();

        return ast.AstWhileStatementNode.new(self.alloc, condition, body);
    }

    fn parsePass(self: *Parser) *ast.AstNode {
        if (!self.expect(TokenType.Pass)) {
            return self.syntaxError("expected 'pass'");
        }

        while (self.match(TokenType.Newline)) {
            self.advance();
        }

        return ast.AstPassNode.new(self.alloc);
    }

    fn parseIndentBlock(self: *Parser) std.ArrayList(*ast.AstNode) {
        var body = std.ArrayList(*ast.AstNode).initCapacity(self.alloc, 4) catch {
            @panic("Failed to allocate function arguments");
        };

        if (!self.expect(TokenType.Colon)) {
            return body;
        }

        if (!self.expect(TokenType.Newline)) {
            return body;
        }

        if (!self.expect(TokenType.Indent)) {
            return body;
        }

        while (!self.match(TokenType.Dedent)) {
            const node = self.parseNode();

            body.append(self.alloc, node) catch {
                @panic("Failed to add node into if body");
            };
        }

        if (!self.expect(TokenType.Dedent)) {
            return body;
        }

        return body;
    }

    fn parseIf(self: *Parser) *ast.AstNode {
        if (!self.expect(TokenType.If)) {
            return self.syntaxError("expected 'if'");
        }

        const condition = self.parseExpression();
        if (self.isErr(condition)) return condition;

        const body = self.parseIndentBlock();

        var elseBody = std.ArrayList(*ast.AstNode).initCapacity(self.alloc, 4) catch {
            @panic("Failed to allocate function arguments");
        };

        if (self.match(TokenType.Else)) {
            self.advance();

            elseBody.deinit(self.alloc);
            elseBody = self.parseIndentBlock();
        }

        return ast.AstIfStatementNode.new(self.alloc, condition, body, elseBody);
    }

    fn parseRaise(self: *Parser) *ast.AstNode {
        if (!self.expect(TokenType.Raise)) {
            return self.syntaxError("expected 'raise'");
        }

        const value = self.parseExpression();
        if (self.isErr(value)) return value;

        return ast.AstAssertNode.new(self.alloc, value);
    }

    fn parseAssert(self: *Parser) *ast.AstNode {
        if (!self.expect(TokenType.Assert)) {
            return self.syntaxError("expected 'assert'");
        }

        const value = self.parseExpression();
        if (self.isErr(value)) return value;

        return ast.AstAssertNode.new(self.alloc, value);
    }

    fn parseFunctionDefinition(self: *Parser) *ast.AstNode {
        if (!self.expect(TokenType.Def)) {
            return self.syntaxError("expected 'def'");
        }

        const nameToken = self.currentToken();
        if (!self.expect(TokenType.Identifier)) {
            return self.syntaxError("expected identifer");
        }

        if (!self.expect(TokenType.LeftParen)) {
            return self.syntaxError("expected '('");
        }

        var arguments = std.ArrayList(ast.FunctionArgument).initCapacity(self.alloc, 4) catch {
            @panic("Failed to allocate function arguments");
        };

        if (self.match(TokenType.Identifier)) {
            const argument = ast.FunctionArgument.new(self.currentToken().lexeme);
            self.advance();

            arguments.append(self.alloc, argument) catch {
                @panic("Failed to add function argument into list");
            };

            while (!self.isEnd() and self.match(TokenType.Comma)) {
                self.advance();

                const argToken = self.currentToken();
                self.advance();

                arguments.append(self.alloc, ast.FunctionArgument.new(argToken.lexeme)) catch {
                    @panic("Failed to add function argument into list");
                };
            }
        }

        if (!self.expect(TokenType.RightParen)) {
            return self.syntaxError("expected ')'");
        }

        const body = self.parseIndentBlock();

        return ast.AstFunctionDefinitionNode.new(self.alloc, nameToken.lexeme, arguments, body);
    }

    fn parseIdentifier(self: *Parser) *ast.AstNode {
        self.advance();

        if (self.match(TokenType.SingleEquals)) {
            self.recede();
            return self.parseVariableDeclaration();
        } else if (self.match(TokenType.LeftParen)) {
            self.recede();
            return self.parseCallExpression();
        }

        self.recede();
        return self.parseExpression();
    }

    fn parseCallExpression(self: *Parser) *ast.AstNode {
        const node = self.parseExpression();
        if (self.isErr(node)) {
            return self.syntaxError("invalid syntax");
        }

        var parameters = std.ArrayList(*ast.AstNode).initCapacity(self.alloc, 4) catch {
            @panic("Failed to allocate parameters for call expression.");
        };

        if (!self.expect(TokenType.LeftParen)) {
            return self.syntaxError("expected '('");
        }

        while (!self.isEnd() and !self.match(TokenType.RightParen)) {
            const expr = self.parseExpression();
            parameters.append(self.alloc, expr) catch {
                @panic("Failed to add expression to call expression parameters");
            };
        }

        if (!self.expect(TokenType.RightParen)) {
            return self.syntaxError("expected ')'");
        }

        while (self.match(TokenType.Newline)) {
            self.advance();
        }

        return ast.AstCallExpressionNode.new(self.alloc, node, parameters);
    }

    fn parseVariableDeclaration(self: *Parser) *ast.AstNode {
        const nameToken = self.currentToken();
        if (!self.expect(TokenType.Identifier)) {
            return self.syntaxError("expected identifier");
        }

        if (!self.expect(TokenType.SingleEquals)) {
            return self.syntaxError("expected '='");
        }

        const expr = self.parseExpression();
        if (self.isErr(expr)) {
            return self.syntaxError("expected variable initializer");
        }

        while (self.match(TokenType.Newline)) {
            self.advance();
        }

        return ast.AstVariableDeclarationNode.new(self.alloc, nameToken.lexeme, expr);
    }

    fn parseExpression(self: *Parser) *ast.AstNode {
        return self.parseAssignment();
    }

    fn parseAssignment(self: *Parser) *ast.AstNode {
        const left = self.parseLogicalOr();
        if (self.isErr(left)) return left;

        const assignment_ops = [_]TokenType{
            TokenType.SingleEquals,
            TokenType.PlusEquals,
            TokenType.MinusEquals,
            TokenType.MultiplyEquals,
            TokenType.DivideEquals,
            TokenType.ModuloEquals,
            TokenType.FloorDivideEquals,
            TokenType.ExponentEquals,
            TokenType.BitwiseAndEquals,
            TokenType.BitwiseOrEquals,
            TokenType.BitwiseXorEquals,
            TokenType.BitwiseRightShiftEquals,
            TokenType.BitwiseLeftShiftEquals,
            TokenType.WalrusOperator,
        };

        for (assignment_ops) |op| {
            if (self.match(op)) {
                if (left.as != .AstIdentifier) {
                    return self.syntaxError("Expected identifier");
                }

                const operatorToken = self.currentToken().tokenType;
                const operator = self.operatorFromTokenType(operatorToken);
                self.advance();

                const right = self.parseAssignment();
                if (self.isErr(right)) return right;

                while (self.match(TokenType.Newline)) {
                    self.advance();
                }

                self.deinitNode(left);

                return ast.AstCompoundAssignmentNode.new(
                    self.alloc,
                    left.as.AstIdentifier.name,
                    operator,
                    right,
                );
            }
        }

        return left;
    }

    fn parseLogicalOr(self: *Parser) *ast.AstNode {
        var left = self.parseLogicalAnd();
        if (self.isErr(left)) return left;

        while (self.match(TokenType.Or)) {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseLogicalAnd();
            if (self.isErr(right)) return right;

            left = ast.AstBinaryExpressionNode.new(self.alloc, left, operator, right);
        }

        return left;
    }
    fn parseLogicalAnd(self: *Parser) *ast.AstNode {
        var left = self.parseLogicalNot();
        if (self.isErr(left)) return left;

        while (self.match(TokenType.And)) {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseLogicalNot();
            if (self.isErr(right)) return right;

            left = ast.AstBinaryExpressionNode.new(self.alloc, left, operator, right);
        }

        return left;
    }

    fn parseLogicalNot(self: *Parser) *ast.AstNode {
        if (self.match(TokenType.Not)) {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseLogicalNot();
            if (self.isErr(right)) return right;

            return ast.AstUnaryExpressionNode.new(self.alloc, right, operator);
        }

        return self.parseComparison();
    }

    fn parseComparison(self: *Parser) *ast.AstNode {
        var left = self.parseBitwiseOr();
        if (self.isErr(left)) return left;

        while (self.match(TokenType.DoubleEquals) or self.match(TokenType.NotEquals) or self.match(TokenType.GreaterThan) or
            self.match(TokenType.GreaterThanOrEquals) or self.match(TokenType.LessThan) or self.match(TokenType.LessThanOrEquals))
        {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseBitwiseOr();
            if (self.isErr(right)) return right;

            left = ast.AstBinaryExpressionNode.new(self.alloc, left, operator, right);
        }

        return left;
    }

    fn parseBitwiseOr(self: *Parser) *ast.AstNode {
        var left = self.parseBitwiseXor();
        if (self.isErr(left)) return left;

        while (self.match(TokenType.BitwiseOr)) {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseBitwiseXor();
            if (self.isErr(right)) return right;

            left = ast.AstBinaryExpressionNode.new(self.alloc, left, operator, right);
        }

        return left;
    }

    fn parseBitwiseXor(self: *Parser) *ast.AstNode {
        var left = self.parseBitwiseAnd();
        if (self.isErr(left)) return left;

        while (self.match(TokenType.BitwiseXor)) {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseBitwiseAnd();
            if (self.isErr(right)) return right;

            left = ast.AstBinaryExpressionNode.new(self.alloc, left, operator, right);
        }

        return left;
    }

    fn parseBitwiseAnd(self: *Parser) *ast.AstNode {
        var left = self.parseBitwiseShifts();
        if (self.isErr(left)) return left;

        while (self.match(TokenType.BitwiseAnd)) {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseBitwiseShifts();
            if (self.isErr(right)) return right;

            left = ast.AstBinaryExpressionNode.new(self.alloc, left, operator, right);
        }

        return left;
    }

    fn parseBitwiseShifts(self: *Parser) *ast.AstNode {
        var left = self.parseTerm();
        if (self.isErr(left)) return left;

        while (self.match(TokenType.BitwiseLeftShift) or self.match(TokenType.BitwiseRightShift)) {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseTerm();
            if (self.isErr(right)) return right;

            left = ast.AstBinaryExpressionNode.new(self.alloc, left, operator, right);
        }

        return left;
    }

    fn parseTerm(self: *Parser) *ast.AstNode {
        var left = self.parseFactor();
        if (self.isErr(left)) return left;

        while (self.match(TokenType.Plus) or self.match(TokenType.Minus)) {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseFactor();
            if (self.isErr(right)) return right;

            left = ast.AstBinaryExpressionNode.new(self.alloc, left, operator, right);
        }

        return left;
    }

    fn parseFactor(self: *Parser) *ast.AstNode {
        var left = self.parseExponentiation();
        if (self.isErr(left)) return left;

        while (self.match(TokenType.Multiply) or self.match(TokenType.Divide) or
            self.match(TokenType.Modulo) or self.match(TokenType.FloorDivision))
        {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseExponentiation();
            if (self.isErr(right)) return right;

            left = ast.AstBinaryExpressionNode.new(self.alloc, left, operator, right);
        }

        return left;
    }

    fn parseExponentiation(self: *Parser) *ast.AstNode {
        var left = self.parseUnary();
        if (self.isErr(left)) return left;

        while (self.match(TokenType.Exponentiation)) {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseUnary();
            if (self.isErr(right)) return right;

            left = ast.AstBinaryExpressionNode.new(self.alloc, left, operator, right);
        }

        return left;
    }

    fn parseUnary(self: *Parser) *ast.AstNode {
        if (self.match(TokenType.Minus) or self.match(TokenType.Plus) or self.match(TokenType.BitwiseNot)) {
            const operator = self.operatorFromTokenType(self.currentToken().tokenType);
            self.advance();

            const right = self.parseUnary();
            if (self.isErr(right)) return right;

            return ast.AstUnaryExpressionNode.new(self.alloc, right, operator);
        }

        return self.parsePrimary();
    }

    fn parsePrimary(self: *Parser) *ast.AstNode {
        const token = self.currentToken();

        switch (token.tokenType) {
            TokenType.LeftParen => {
                self.advance();

                const expr = self.parseExpression();
                if (self.isErr(expr)) {
                    return self.syntaxError("Invalid expression inside parentheses");
                }

                if (!self.expect(TokenType.RightParen)) {
                    return self.syntaxError("Expected closing parenthesis");
                }

                return expr;
            },
            TokenType.Integer => {
                const value = std.fmt.parseInt(i32, token.lexeme, 10) catch {
                    @panic("Expected integer format on integer token");
                };

                self.advance();
                return ast.AstIntegerLiteralNode.new(self.alloc, value);
            },
            TokenType.Identifier => {
                self.advance();
                return ast.AstIdentifierNode.new(self.alloc, token.lexeme);
            },
            TokenType.True, TokenType.False => {
                self.advance();

                const value = if (std.mem.eql(u8, token.lexeme, "True")) true else false;
                return ast.AstBooleanLiteralNode.new(self.alloc, value);
            },
            TokenType.String => {
                self.advance();

                return ast.AstStringLiteralNode.new(self.alloc, token.lexeme);
            },
            else => {
                self.advance();
                return self.syntaxError("Expected primary expression");
            },
        }
    }

    fn errorNode(self: Parser) *ast.AstNode {
        const node = self.alloc.create(ast.AstNode) catch {
            @panic("Failed to allocate memory for AstErrorNode");
        };

        node.* = ast.AstNode{
            .as = .{
                .AstError = ast.AstErrorNode{},
            },
        };

        return node;
    }

    fn operatorFromTokenType(_: Parser, tokenType: TokenType) ast.OperatorType {
        return switch (tokenType) {
            TokenType.Plus => ast.OperatorType.Plus,
            TokenType.PlusEquals => ast.OperatorType.Plus,
            TokenType.Minus => ast.OperatorType.Minus,
            TokenType.MinusEquals => ast.OperatorType.Minus,
            TokenType.Multiply => ast.OperatorType.Multiply,
            TokenType.MultiplyEquals => ast.OperatorType.Multiply,
            TokenType.Divide => ast.OperatorType.Divide,
            TokenType.DivideEquals => ast.OperatorType.Divide,
            TokenType.Modulo => ast.OperatorType.Modulo,
            TokenType.ModuloEquals => ast.OperatorType.Modulo,
            TokenType.Exponentiation => ast.OperatorType.Exponentiation,
            TokenType.ExponentEquals => ast.OperatorType.Exponentiation,
            TokenType.FloorDivision => ast.OperatorType.FloorDivision,
            TokenType.FloorDivideEquals => ast.OperatorType.FloorDivision,
            TokenType.BitwiseAnd => ast.OperatorType.BitwiseAnd,
            TokenType.BitwiseAndEquals => ast.OperatorType.BitwiseAnd,
            TokenType.BitwiseOr => ast.OperatorType.BitwiseOr,
            TokenType.BitwiseOrEquals => ast.OperatorType.BitwiseOr,
            TokenType.BitwiseNot => ast.OperatorType.BitwiseNot,
            TokenType.BitwiseXor => ast.OperatorType.BitwiseXor,
            TokenType.BitwiseXorEquals => ast.OperatorType.BitwiseXor,
            TokenType.BitwiseLeftShift => ast.OperatorType.BitwiseLeftShift,
            TokenType.BitwiseLeftShiftEquals => ast.OperatorType.BitwiseLeftShift,
            TokenType.BitwiseRightShift => ast.OperatorType.BitwiseRightShift,
            TokenType.BitwiseRightShiftEquals => ast.OperatorType.BitwiseRightShift,
            TokenType.LessThan => ast.OperatorType.LessThan,
            TokenType.LessThanOrEquals => ast.OperatorType.LessThanOrEquals,
            TokenType.GreaterThan => ast.OperatorType.GreaterThan,
            TokenType.GreaterThanOrEquals => ast.OperatorType.GreaterThanOrEquals,
            TokenType.NotEquals => ast.OperatorType.NotEquals,
            TokenType.DoubleEquals => ast.OperatorType.Equals,
            TokenType.And => ast.OperatorType.And,
            TokenType.Or => ast.OperatorType.Or,
            TokenType.Not => ast.OperatorType.Not,
            TokenType.WalrusOperator => ast.OperatorType.Walrus,
            else => @panic("Unknown token type when mapping to AST operator"),
        };
    }

    fn syntaxError(self: *Parser, msg: []const u8) *ast.AstNode {
        while (self.isEnd()) {
            self.recede();
        }

        const token = self.currentToken();

        std.debug.print("File: {s}, at {}:{}\n", .{ self.metadata.path, token.line, token.column });
        std.debug.print("Syntax error: {s}\n", .{msg});
        self.hadError = true;

        return self.errorNode();
    }

    fn isErr(_: Parser, node: *ast.AstNode) bool {
        return node.as == ast.AstNodeType.AstError;
    }

    fn match(self: Parser, tokenType: TokenType) bool {
        return self.currentToken().tokenType == tokenType;
    }

    fn expect(self: *Parser, expectedType: TokenType) bool {
        if (self.currentToken().tokenType != expectedType) {
            return false;
        }

        self.advance();
        return true;
    }

    fn currentToken(self: Parser) Token {
        return if (!self.isEnd()) self.tokens.items[self.position] else Token{
            .lexeme = "",
            .tokenType = TokenType.Error,
            .line = 0,
            .column = 0,
        };
    }

    fn recede(self: *Parser) void {
        self.position -= 1;
    }

    fn advance(self: *Parser) void {
        self.position += 1;
    }

    fn isEnd(self: Parser) bool {
        return self.position >= self.tokens.items.len;
    }
};
