# SysV ABI Calling Convention

## Function Call Argument

| Arg # | Register |
| :---- | :------- |
| Arg 1 | rdi |
| Arg 2 | rsi |
| Arg 3 | rdx |
| Arg 4 | rcx |
| Arg 5 | r8  |
| Arg 6 | r9  |

More than 6? Put the remaining args on stack.

## Callee Saved Registers

The callee function (the fn being called) must reserve the original value in these registers before using them and restore their state before exit.

They include: rbx rbp r12 r13 r14 r15

### Caller Saved Registers

The caller function must preserve the original value in these registers as a call to another function can use these registers.

As the callee is not liable to manage their state, they are excellent scratchpads.

They include: rax rcx rdx rsi rdi r8 r9 r10 r11

# Register Hygiene

Use caller-saved registers for:
  - temporaries
  - intermediate math
  - values that die before calls

Use callee-saved registers for:
  - long-lived values across calls
  - struct base pointers
  - loop invariants that survive calls

**rsp is not a scratch register.**

**rbp is scratch only when I give up the base pointer or I am not inside a procedure.**
