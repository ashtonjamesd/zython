# Zython ISA

This document describes the Instruction Set Architecture (ISA) for the Zython interpreter. The ISA defines the set of instructions that the Zython Virtual Machine (ZVM) can execute. Each instruction is represented by a single opcode and may have associated operands.

## Instruction Set

### Arithmetic Instructions
- **PushConstant (0x0):** Push a constant value onto the stack.
- **Add (0x1):** Pop two values from the stack, add them, and push the result.
- **Sub (0x2):** Pop two values from the stack, subtract the second from the first, and push the result.
- **Mul (0x3):** Pop two values from the stack, multiply them, and push the result.
- **Div (0x4):** Pop two values from the stack, divide the first by the second, and push the result.
- **Mod (0x5):** Pop two values from the stack, compute the modulus, and push the result.

### Function Instructions
- **Call (0x6):** Call a function.

### Memory Instructions
- **StoreGlobal (0x7):** Store the top value from the stack into a global variable.
- **LoadGlobal (0x8):** Load a global variable onto the stack.

### Unary Operations
- **Neg (0x9):** Negate the top value on the stack.
- **UnaryPlus (0x12):** Push the top value of the stack without modification.

### Exponentiation and Division
- **Exp (0xa):** Pop two values from the stack, raise the first to the power of the second, and push the result.
- **FloorDiv (0xb):** Pop two values from the stack, perform floor division, and push the result.

### Bitwise Operations
- **BitAnd (0xc):** Perform a bitwise AND on the top two values of the stack.
- **BitOr (0xd):** Perform a bitwise OR on the top two values of the stack.
- **BitNot (0xe):** Perform a bitwise NOT on the top value of the stack.
- **BitXor (0xf):** Perform a bitwise XOR on the top two values of the stack.
- **BitLeftShift (0x10):** Perform a left bitwise shift on the top two values of the stack.
- **BitRightShift (0x11):** Perform a right bitwise shift on the top two values of the stack.

### Comparison Instructions
- **Lt (0x13):** Pop two values from the stack, compare if the first is less than the second, and push the result.
- **Gt (0x14):** Pop two values from the stack, compare if the first is greater than the second, and push the result.
- **Lte (0x15):** Pop two values from the stack, compare if the first is less than or equal to the second, and push the result.
- **Gte (0x16):** Pop two values from the stack, compare if the first is greater than or equal to the second, and push the result.
- **Eq (0x17):** Pop two values from the stack, compare if they are equal, and push the result.
- **Neq (0x18):** Pop two values from the stack, compare if they are not equal, and push the result.

### Logical Instructions
- **And (0x19):** Perform a logical AND on the top two values of the stack.
- **Or (0x1a):** Perform a logical OR on the top two values of the stack.
- **Not (0x1b):** Perform a logical NOT on the top value of the stack.

### Control Flow Instructions
- **JumpIfFalse (0x1c):** Jump to a specified instruction if the top value of the stack is false.
- **Nop (0x1d):** No operation.
- **Jump (0x1e):** Unconditionally jump to a specified instruction.

### Extended Instructions
- **PushConstantWide (0x1f):** Push a wide constant value onto the stack. Uses the next two bytes for the constant index.