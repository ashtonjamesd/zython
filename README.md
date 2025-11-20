# zython

Zython is a lightweight and fast Python interpreter that aims to support the vast majority of Python syntax and core language features, built entirely in Zig.

![License](https://img.shields.io/badge/license-MIT-blue)

## Features

### Supported Data Types
- Numbers
- Booleans
- Strings

### Operators
- Arithmetic: `+`, `-`, `**`, etc
- Logical: `and`, `or`, `not`
- Bitwise: `&`, `|`, `>>`, etc
- Comparison: `<`, `>`, etc
- Grouping: `()`
- Walrus operator: `:=`

### Built-in Functions
- `print()`
- `len()`
- `abs()`
- `int()`
- `ord()`

### Control Flow
- `if` / `else` (not elif yet)
- `pass`
- `while` loops with `break` and `continue`
- Global variables
- Functions with `def` and `return`
- Ternary expressions

See `/examples`.

## Installation

Currently, you can build Zython from source:

```bash
git clone https://github.com/yourusername/zython.git
cd zython
zig build
```

### Usage

```
./zython examples/hello_world.py
```

# Resources

- https://docs.python.org/3/
- https://github.com/python/cpython
- https://unpyc.sourceforge.net/Opcodes.html
- https://craftinginterpreters.com/