const std = @import("std");
const lexer = @import("../frontend/lexer.zig");
const parser = @import("../frontend/parser.zig");
const compiler = @import("../compiler/compiler.zig");
const analyzer = @import("../compiler/analyze.zig");
const vm = @import("../vm/zvm.zig");
const metadata = @import("../frontend/metadata.zig").Metadata;

pub const RuntimeResult = enum {
    Success,
    RuntimeFailure,
    CompileTimeFailure,
};

pub const ZythonRuntimeConfig = struct {
    debug: bool,
};

pub const ZythonRuntime = struct {
    path: []const u8,
    alloc: std.mem.Allocator,
    config: ZythonRuntimeConfig,

    pub fn new(path: []const u8, alloc: std.mem.Allocator, config: ZythonRuntimeConfig) ZythonRuntime {
        return ZythonRuntime{
            .path = path,
            .alloc = alloc,
            .config = config,
        };
    }

    pub fn run(self: ZythonRuntime) RuntimeResult {
        const debug = self.config.debug;

        const cwd = std.fs.cwd();
        const source = cwd.readFileAlloc(self.alloc, self.path, 4096) catch {
            return RuntimeResult.RuntimeFailure;
        };
        defer self.alloc.free(source);

        const meta = metadata.new(self.path);

        var lex = lexer.Lexer.new(source, self.alloc);
        defer lex.deinit();

        const lexResult = lex.tokenize();

        if (debug) lex.print();
        if (lexResult != lexer.LexerResult.Success) {
            return RuntimeResult.CompileTimeFailure;
        }

        var parse = parser.Parser.new(self.alloc, lex.tokens, meta);
        defer parse.deinit();

        parse.parseAst();

        if (debug) parse.print();
        if (parse.hadError) {
            return RuntimeResult.CompileTimeFailure;
        }

        var anaylze = analyzer.Analyzer.new(self.alloc, meta);
        defer anaylze.deinit();

        anaylze.analyzeAst(parse.program);

        if (anaylze.hadError) {
            return RuntimeResult.CompileTimeFailure;
        }

        var compile = compiler.Compiler.new(self.alloc, parse.program);
        defer compile.deinit();

        compile.compileBytecode();

        if (debug) {
            compile.dumpBytecode() catch {
                @panic("failed to dump compiler");
            };
            compile.print();
        }

        var zython = vm.ZythonVm.new(compile.program, self.alloc);
        defer zython.deinit();

        zython.execute();

        return RuntimeResult.Success;
    }
};
