section .data
  asterisks  db  0xA, "*-------------------------------*", 0xA
  aster_len  equ  $ - asterisks

  init_msg  db  "Welcome to a BCD-based calculator"
  init_len  equ  $ - init_msg

  select_msg  db  "Select the operation:", 0xA
  select_len  equ  $ - select_msg

  add_op_msg  db  "1. Add", 0xA
  add_op_len  equ  $ - add_op_msg

  sub_op_msg  db  "2. Subtract", 0xA
  sub_op_len  equ  $ - sub_op_msg

  mul_op_msg  db  "3. Multiply", 0xA
  mul_op_len  equ  $ - mul_op_msg

  div_op_msg  db  "4. Divide", 0xA
  div_op_len  equ  $ - div_op_msg

  exit_msg  db  "0. Exit"
  exit_len  equ  $ - exit_msg

  choice  db  "Your choice: "
  ch_len  equ  $ - choice

  inp_num1  db  "Enter num1: "
  inp_num2  db  "Enter num2: "
  inp_len   equ  $ - inp_num2

  res_add  db  "num1 + num2 = "
  res_sub  db  "num1 - num2 = "
  res_mul  db  "num1 * num2 = "
  res_div  db  "num1 / num2 = "
  res_len  equ  $ - res_div

  unsp_op_msg  db  "Operator not supported.", 0xA
  unsp_op_len  equ  $ - unsp_op_msg

  cont_msg  db  0xA, 0xA, "Would you like to continue?", 0xA, "ENTER 1 for yes, 0 for NO:"
  cont_len  equ  $ - cont_msg

  div_by_zero_msg  db  "Division by zero is not possible.", 0xA
  div_by_zero_len  equ  $ - div_by_zero_msg


section .bss
  oper: resb  2  ; Operator
  num1: resb 11  ; (10+1, 1 for '\n')
  num2: resb 11  ; (10+1, 1 for '\n')
  ress: resb 11  ; All 11 bytes for the result


section .text

; A procedure to convert an ASCII stream of 
; numbers into unpacked BCD.
; - It updates the original buffer.
; - It returns the number of digits (al) and 
;   the sign-bit status (0:unset, 1:set).
; Arg1 (rax): Buffer
ascii_to_uBCD:
  xor rbx, rbx    ; the incoming character is loaded here
  mov rcx, -1     ; index (used to traverse the buffer)
  xor rsi, rsi    ; negative status (default:0, positive)

.parse:
  ; Incrementing at the top ensures I don't have to repeat.
  inc rcx
  mov bl, BYTE [rax+rcx]

  cmp bl, 0xA  ; '\n'
  jz  .return

  cmp bl, 45     ; A hyphen-minus (-)
  jnz .update

  mov rsi, 1  ; Note the presence (1) of sign bit.
  jmp .parse

.update:
  sub bl, 48
  mov BYTE [rax+rcx], bl    ; Replace the ASCII character.
  jmp .parse

.return:
  ; Prepare rax for return.
  xor rax, rax    ; Clear all the bits
  inc cl          ; Why add 1?
  mov al, cl      ; Set the number of digits in al.
  mov ah, 0       ; Set the sign bit as 0, for now.

  ; If the sign bit was set, update the return values.
  cmp rsi, 1
  jz .rett

  dec al       ; Subtract 1 for [?]
  mov ah, 1    ; Set the sign bit.

.rett:
  ret


global _start
_start:
  mov rax, 1
  mov rdi, 1
  mov rsi, asterisks
  mov rdx, aster_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, init_msg
  mov rdx, init_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, asterisks
  mov rdx, aster_len
  syscall

print_menu:
  mov rax, 1
  mov rdi, 1
  mov rsi, asterisks
  mov rdx, aster_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, select_msg
  mov rdx, select_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, add_op_msg
  mov rdx, add_op_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, sub_op_msg
  mov rdx, sub_op_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, mul_op_msg
  mov rdx, mul_op_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, div_op_msg
  mov rdx, div_op_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, exit_msg
  mov rdx, exit_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, asterisks
  mov rdx, aster_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, choice
  mov rdx, ch_len
  syscall

  ; Input the operator.
  mov rax, 0
  mov rdi, 0
  lea rsi, oper
  mov rdx, 2
  syscall

  lea rax, oper
  cmp BYTE [rax], 48    ; ASCII for 0
  jz exit

  ; Input the numbers.
  mov rax, 1
  mov rdi, 1
  mov rsi, inp_num1
  mov rdx, inp_len
  syscall

  mov rax, 0
  mov rdi, 0
  lea rsi, num1
  mov rdx, 12
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, inp_num2
  mov rdx, inp_len
  syscall

  mov rax, 0
  mov rdi, 0
  lea rsi, num2
  mov rdx, 12
  syscall

  ; Convert the buffers
  lea rax, num1
  call ascii_to_uBCD

  lea rax, num2
  call ascii_to_uBCD

  ; Perform the operation.
  cmp BYTE [rax], 49  ; 1 (+)
  jz  _add

  cmp BYTE [rax], 50  ; 2 (-)
  jz  _sub

  cmp BYTE [rax], 51  ; 3 (*)
  jz  _mul

  cmp BYTE [rax], 52  ; 4 (/)
  jz  _div

  jmp unsp_op

_add:
  lea r8,  num1
  lea r9,  num2
  xor rcx, rcx

unsp_op:
  mov rax, 1
  mov rdi, 1
  mov rsi, unsp_op_msg
  mov rdx, unsp_op_len
  syscall
  jmp ask_again

exit:
  mov rax, 60
  xor rdi, rdi
  syscall
