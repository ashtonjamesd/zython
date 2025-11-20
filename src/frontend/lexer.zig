const std = @import("std");

const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;

pub const LexerResult = enum {
    Success,
    Failure,
};

pub const Lexer = struct {
    source: []const u8,
    position: usize = 0,
    tokens: std.ArrayList(Token),
    indentStack: std.ArrayList(u32),
    alloc: std.mem.Allocator,
    line: u32,
    column: u32,

    pub fn new(source: []const u8, alloc: std.mem.Allocator) Lexer {
        return Lexer{
            .source = source,
            .tokens = std.ArrayList(Token).initCapacity(alloc, 128) catch {
                @panic("Failed to initialize token list in lexer");
            },
            .indentStack = std.ArrayList(u32).initCapacity(alloc, 128) catch {
                @panic("Failed to initialize indent stack in lexer");
            },
            .alloc = alloc,
            .line = 1,
            .column = 1,
        };
    }

    pub fn deinit(self: *Lexer) void {
        self.tokens.deinit(self.alloc);
        self.indentStack.deinit(self.alloc);
    }

    pub fn print(self: *Lexer) void {
        for (self.tokens.items) |token| {
            std.debug.print("Token: {any}, Lexeme: '{s}' | {}:{}\n", .{
                token.tokenType,
                token.lexeme,
                token.line,
                token.column,
            });
        }
    }

    pub fn tokenize(self: *Lexer) LexerResult {
        self.indentStack.append(self.alloc, 0) catch {
            @panic("Failed to initialize base indent level");
        };

        var at_line_start = true;
        while (!self.isEnd()) {
            if (self.isEnd()) break;

            if (self.currentChar() == '#') {
                while (!self.isEnd() and self.currentChar() != '\n') {
                    self.advance();
                }
            }
            if (self.isEnd()) break;

            if (at_line_start) {
                var indent: u32 = 0;
                while (!self.isEnd() and self.currentChar() == ' ') {
                    indent += 1;
                    self.advance();
                }
                if (!self.isEnd() and self.currentChar() == '\n') {} else {
                    const last_indent = self.indentStack.items[self.indentStack.items.len - 1];
                    if (indent > last_indent) {
                        self.indentStack.append(self.alloc, indent) catch {
                            @panic("Failed to push indent");
                        };
                        self.tokens.append(self.alloc, self.newToken(TokenType.Indent, "")) catch {
                            @panic("Failed to append Indent token");
                        };
                    } else if (indent < last_indent) {
                        while (self.indentStack.items.len > 0 and indent < self.indentStack.items[self.indentStack.items.len - 1]) {
                            _ = self.indentStack.pop();
                            self.tokens.append(self.alloc, self.newToken(TokenType.Dedent, "")) catch {
                                @panic("Failed to append Dedent token");
                            };
                        }
                        if (indent != self.indentStack.items[self.indentStack.items.len - 1]) {
                            self.tokens.append(self.alloc, self.newToken(TokenType.Error, "IndentationError")) catch {
                                @panic("Failed to append Error token");
                            };
                        }
                    }
                }
                at_line_start = false;
            }

            const token = self.tokenizeNext();

            if (token.tokenType == TokenType.Newline) {
                self.line += 1;
                self.column = 1;
                at_line_start = true;
            }

            if (token.tokenType != TokenType.Whitespace) {
                self.tokens.append(self.alloc, token) catch {
                    @panic("Failed to append token to lexer token list");
                };
            }

            self.advance();
        }

        while (self.indentStack.items.len > 1) {
            _ = self.indentStack.pop();
            self.tokens.append(self.alloc, self.newToken(TokenType.Dedent, "")) catch {
                @panic("Failed to append final Dedent token");
            };
        }

        return LexerResult.Success;
    }

    fn tokenizeNext(self: *Lexer) Token {
        switch (self.currentChar()) {
            'a'...'z', 'A'...'Z', '_' => return self.tokenizeIdentifier(),
            '0'...'9' => return self.tokenizeInteger(),
            '\n' => return self.newToken(TokenType.Newline, "\\n"),
            '\"' => return self.tokenizeString(),
            else => return self.tokenizeSymbol(),
        }
    }

    fn tokenizeString(self: *Lexer) Token {
        self.advance();

        const start = self.position;
        while (!self.isEnd() and self.currentChar() != '\"') {
            self.advance();
        }
        self.advance();

        const lexeme = self.source[start .. self.position - 1];
        self.position -= 1;

        return self.newToken(TokenType.String, lexeme);
    }

    fn tokenizeIdentifier(self: *Lexer) Token {
        const start = self.position;
        while (!self.isEnd() and (std.ascii.isAlphabetic(self.currentChar()) or self.currentChar() == '_')) {
            self.advance();
        }

        const lexeme = self.source[start..self.position];
        self.position -= 1;

        var tokenType = TokenType.Identifier;
        if (std.mem.eql(u8, lexeme, "True")) {
            tokenType = TokenType.True;
        } else if (std.mem.eql(u8, lexeme, "False")) {
            tokenType = TokenType.False;
        } else if (std.mem.eql(u8, lexeme, "and")) {
            tokenType = TokenType.And;
        } else if (std.mem.eql(u8, lexeme, "not")) {
            tokenType = TokenType.Not;
        } else if (std.mem.eql(u8, lexeme, "or")) {
            tokenType = TokenType.Or;
        } else if (std.mem.eql(u8, lexeme, "def")) {
            tokenType = TokenType.Def;
        } else if (std.mem.eql(u8, lexeme, "assert")) {
            tokenType = TokenType.Assert;
        } else if (std.mem.eql(u8, lexeme, "raise")) {
            tokenType = TokenType.Raise;
        } else if (std.mem.eql(u8, lexeme, "if")) {
            tokenType = TokenType.If;
        } else if (std.mem.eql(u8, lexeme, "pass")) {
            tokenType = TokenType.Pass;
        } else if (std.mem.eql(u8, lexeme, "else")) {
            tokenType = TokenType.Else;
        } else if (std.mem.eql(u8, lexeme, "while")) {
            tokenType = TokenType.While;
        } else if (std.mem.eql(u8, lexeme, "break")) {
            tokenType = TokenType.Break;
        } else if (std.mem.eql(u8, lexeme, "continue")) {
            tokenType = TokenType.Continue;
        } else if (std.mem.eql(u8, lexeme, "for")) {
            tokenType = TokenType.For;
        } else if (std.mem.eql(u8, lexeme, "in")) {
            tokenType = TokenType.In;
        } else if (std.mem.eql(u8, lexeme, "return")) {
            tokenType = TokenType.Return;
        }

        return self.newToken(tokenType, lexeme);
    }

    fn tokenizeInteger(self: *Lexer) Token {
        const start = self.position;
        while (!self.isEnd() and std.ascii.isDigit(self.currentChar())) {
            self.advance();
        }

        const lexeme = self.source[start..self.position];
        self.position -= 1;

        return self.newToken(TokenType.Integer, lexeme);
    }

    fn tokenizeSymbol(self: *Lexer) Token {
        const char = self.currentChar();

        const token = switch (char) {
            ',' => return self.newToken(TokenType.Comma, ","),
            '+' => {
                self.advance();
                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.PlusEquals, "+=");
                }

                self.recede();
                return self.newToken(TokenType.Plus, "+");
            },
            '-' => {
                self.advance();
                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.MinusEquals, "-=");
                }

                self.recede();
                return self.newToken(TokenType.Minus, "-");
            },
            ':' => {
                self.advance();
                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.WalrusOperator, ":=");
                }

                self.recede();
                return self.newToken(TokenType.Colon, ":");
            },
            '*' => {
                self.advance();
                if (self.currentChar() == '*') {
                    self.advance();
                    if (self.currentChar() == '=') {
                        return self.newToken(TokenType.ExponentEquals, "**=");
                    }

                    self.recede();
                    return self.newToken(TokenType.Exponentiation, "**");
                }

                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.MultiplyEquals, "*=");
                }

                self.recede();
                return self.newToken(TokenType.Multiply, "*");
            },
            '/' => {
                self.advance();
                if (self.currentChar() == '/') {
                    self.advance();
                    if (self.currentChar() == '=') {
                        return self.newToken(TokenType.FloorDivideEquals, "//=");
                    }

                    self.recede();
                    return self.newToken(TokenType.FloorDivision, "//");
                }

                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.DivideEquals, "/=");
                }

                self.recede();
                return self.newToken(TokenType.Divide, "/");
            },
            '%' => {
                self.advance();
                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.ModuloEquals, "%=");
                }

                self.recede();
                return self.newToken(TokenType.Modulo, "%");
            },
            '(' => self.newToken(TokenType.LeftParen, "("),
            ')' => self.newToken(TokenType.RightParen, ")"),
            '&' => {
                self.advance();
                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.BitwiseAndEquals, "&=");
                }

                self.recede();
                return self.newToken(TokenType.BitwiseAnd, "&");
            },
            '|' => {
                self.advance();
                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.BitwiseOrEquals, "|=");
                }

                self.recede();
                return self.newToken(TokenType.BitwiseOr, "|");
            },
            '^' => {
                self.advance();
                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.BitwiseXorEquals, "^=");
                }

                self.recede();
                return self.newToken(TokenType.BitwiseXor, "^");
            },
            '~' => self.newToken(TokenType.BitwiseNot, "~"),
            '>' => {
                self.advance();
                if (self.currentChar() == '>') {
                    self.advance();
                    if (self.currentChar() == '=') {
                        return self.newToken(TokenType.BitwiseRightShiftEquals, ">>=");
                    }

                    self.recede();
                    return self.newToken(TokenType.BitwiseRightShift, ">>");
                }

                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.GreaterThanOrEquals, ">=");
                }

                self.recede();
                return self.newToken(TokenType.GreaterThan, ">");
            },
            '<' => {
                self.advance();
                if (self.currentChar() == '<') {
                    self.advance();
                    if (self.currentChar() == '=') {
                        return self.newToken(TokenType.BitwiseLeftShiftEquals, "<<=");
                    }

                    self.recede();
                    return self.newToken(TokenType.BitwiseLeftShift, "<<");
                }

                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.LessThanOrEquals, "<=");
                }

                self.recede();
                return self.newToken(TokenType.LessThan, "<");
            },
            '=' => {
                self.advance();
                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.DoubleEquals, "==");
                }

                self.recede();
                return self.newToken(TokenType.SingleEquals, "=");
            },
            '!' => {
                self.advance();
                if (self.currentChar() == '=') {
                    return self.newToken(TokenType.NotEquals, "!=");
                }

                self.recede();
                @panic("todo");
            },
            ' ' => self.newToken(TokenType.Whitespace, " "),
            else => @panic("Unknown symbol in lexer"),
        };

        return token;
    }

    fn newToken(self: *Lexer, tokenType: TokenType, lexeme: []const u8) Token {
        return Token.new(tokenType, lexeme, self.line, self.column);
    }

    fn isEnd(self: Lexer) bool {
        return self.position >= self.source.len;
    }

    fn advance(self: *Lexer) void {
        self.position += 1;
        self.column += 1;
    }

    fn recede(self: *Lexer) void {
        self.position -= 1;
        self.column -= 1;
    }

    fn currentChar(self: Lexer) u8 {
        return self.source[self.position];
    }
};
