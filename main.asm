section .data
  init_msg  db  "Hello, Calculator!", 0xA
  init_len  equ  $ - init_msg

  asterisks  db  "*-------------------------*", 0xA
  aster_len  equ  $ - asterisks

  menu_msg  db  "Select the operation:", 0xA
  menu_len  equ  $ - menu_msg

  add_msg   db  "1. Add", 0xA
  add_len   equ  $ - add_msg

  sub_msg   db  "2. Subtract", 0xA
  sub_len   equ  $ - sub_msg

  mul_msg   db  "3. Multiply", 0xA
  mul_len   equ  $ - mul_msg

  div_msg   db  "4. Divide", 0xA
  div_len   equ  $ - div_msg

  exit_msg  db  "0. Exit", 0xA
  exit_len  equ  $ - exit_msg

  choice  db  "Your choice: "
  ch_len  equ  $ - choice

  in_num1   db  "Enter num1: ", 0xA
  in_num2   db  "Enter num2: ", 0xA
  inp_len   equ  $ - in_num2

  res_add  db  "num1 + num2 = "
  res_sub  db  "num1 - num2 = "
  res_mul  db  "num1 * num2 = "
  res_div  db  "num1 / num2 = "
  res_len   equ  $ - div_msg

  unsp_op_msg  db  "Operator not supported.", 0xA
  unsp_op_len  equ  $ - unsp_op_msg

  cont_msg  db  "Would you like to continue?", 0xA, "Enter 1 for yes, 0 for NO:"
  cont_len  equ  $ - cont_msg


section .bss
  oper:    resb  2    ; A 1 byte container for the operator. The extra byte is for '\n'.
  num1:    resb  5    ; A 4 bytes container. The extra byte is for '\n'.
  num2:    resb  5    ; A 4 bytes container. The extra byte is for '\n'.
  result:  resb  4    ; A 4 bytes container for result. The extra byte is for '\n'.

section .text
global  _start

; A procedure to convert an ASCII stream of 
;   numbers to an integer stream.
; Arg1 (rax): The ASCII stream
ascii_to_num:
  push rbp
  mov  rbp, rsp

  xor rcx, rcx    ; Counter
  xor rsi, rsi    ; Number of digits in the stream.
  xor r8,  r8     ; The number, after conversion.

; calculate the number of digits in the ASCII stream.
.loop1:
  cmp BYTE [rax + rsi], 0xA
  jz  .loop2

  inc rsi
  jmp .loop1

; Convert the ASCII stream into a numeric stream.
.loop2:
  ; Extract the first ASCII character. This value 
  ;   is an ordinal, only its human interpretation 
  ;   is that of a number.
  mov dl, BYTE [rax+rcx]

  ; The ordinals corresponding to 0-9 ASCII chars 
  ;   are 48-57 in decimals. To obtain the actual 
  ;   decimal ordinal corresponding to them, we've 
  ;   subtract 48 from the ASCII value.
  sub dl, 48

  ; We are moving from right to left. The rightmost 
  ;   value carries the most weight. To construct the 
  ;   result correctly, we have to multiply the existing 
  ;   number in the result with 10, followed by adding 
  ;   the newly converted ASCII character.
  ; For example, take "56" as input.
  ; - The result is initialized to 0.
  ; - First  iteration, we get (0*10 + 5), i.e. 5.
  ; - Second iteration, we get (5*10 + 6), i.e. 56.
  imul r8, 10
  add  r8, dl

  ; Increase the counter.
  inc rcx

  ; Check if we have reached the last digit.
  cmp cl, sil
  jnz .loop2

  ; Return
  mov rax, r8
  pop rbp
  ret


_start:
  sub rsp, 16
  mov rax, 1
  mov rdi, 1
  mov rsi, init_msg
  mov rdx, init_len
  syscall

print_menu:
  mov rax, 1
  mov rdi, 1
  mov rsi, asterisks
  mov rdx, aster_len
  syscall

  mov rax, 1           ; sys_write
  mov rdi, 1           ; fd=stdout
  mov rsi, menu_msg    ; buffer
  mov rdx, menu_len    ; buffer length
  syscall

  mov rax, 1          ; sys_write
  mov rdi, 1          ; fd=stdout
  mov rsi, add_msg    ; buffer
  mov rdx, add_len     ; buffer length
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, sub_msg
  mov rdx, sub_len
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, mul_msg
  mov rdx, mul_msg
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, div_msg
  mov rdx, div_msg
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

  ; Take the operator.
  mov rax, 0       ; sys_read
  mov rdi, 0       ; fd=stdin
  lea rsi, oper    ; buffer
  mov rdx, 2       ; buffer capacity
  syscall

  jz exit

  ; Take the numbers.
  mov rax, 1
  mov rdi, 1
  mov rsi, in_num1
  mov rdx, inp_len
  syscall

  mov rax, 0
  mov rdi, 0
  lea rsi, num1
  mov rdx, 5
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, in_num2
  mov rdx, inp_len
  syscall

  mov rax, 0
  mov rdi, 0
  lea rsi, num2
  mov rdx, 5
  syscall

  ; Call ascii_to_num and convert the ASCII streams 
  ; into actual integers.
  xor r8, r8      ; num1
  xor r9, r9      ; num2
  xor r10, r10    ; result

  lea rax, num1
  call ascii_to_num
  mov r8, rax

  lea rax, num2
  call ascii_to_num
  mov r9, rax

  ; Perform the operation.
  mov r10, r8    ; load num1 in result

  lea rax, oper

  cmp BYTE [rax], 43  ; +
  jz  _add

  cmp BYTE [rax], 45  ; -
  jz  _sub

  cmp BYTE [rax], 42  ; *
  jz  _mul

  cmp BYTE [rax], 47  ; /
  jz  _div

  jnz unsp_op

_add:
  add r8, r9
  jmp num_to_ascii

_sub:
  sub r8, r9
  jmp num_to_ascii

_mul:
  imul r8, r9
  jmp num_to_ascii

_div:
  mov rax, r8
  cqo            ; sign extend RDX (RAX:RDX)
  div r9         ; (Quotient:RAX && Remainder:RDX)
  jmp num_to_ascii

unsp_op:
  mov rax, 1
  mov rdi, 1
  mov rsi, unsp_op_msg
  mov rdx, unsp_op_len
  syscall

  jmp ask_again

num_to_ascii:
  mov rax, r10    ; result
  mov r11, 1      ; result length
  xor rcx, rcx    ; result length copy for loop4.

; Calculate the number of digits in the result.
.loop3:
  mov rcx, r11    ; [change this]

  mov  rdi, r11
  imul rdi, 10
  div  rdi

  cmp rax, 0
  jz  .loop4

  inc r11
  jmp .loop3

; Divide the result by 10 until the quotient 
; becomes 0, i.e. no more digits left. Put 
; the remainder from opposite side.
.loop4:
  cqo
  div 10

  lea rsi, result
  mov BYTE [rsi+rcx-1], rdx
  dec rcx

  cmp rax, 0
  jnz .loop4

print_result:
  lea rax, oper

  cmp BYTE [rax], 43
  jz  add_res

  cmp BYTE [rax], 45
  jz  sub_res

  cmp BYTE [rax], 42
  jz  mul_res

  cmp BYTE [rax], 47
  jz  div_res

add_res:
  mov rax, 1
  mov rdi, 1
  lea rsi, res_add
  mov rdx, res_len
  syscall

  jmp ress

sub_res:
  mov rax, 1
  mov rdi, 1
  lea rsi, res_sub
  mov rdx, res_len
  syscall

  jmp ress

mul_res:
  mov rax, 1
  mov rdi, 1
  lea rsi, res_mul
  mov rdx, res_len
  syscall

  jmp ress

div_res:
  mov rax, 1
  mov rdi, 1
  lea rsi, res_div
  mov rdx, res_len
  syscall

  jmp ress

ress:
  mov rax, 1
  mov rdi, 1
  mov rsi, result
  mov rdx, r11

  jmp ask_again

ask_again:
  mov rax, 1
  mov rdi, 1
  mov rsi, cont_msg
  mov rdx, cont_len
  syscall

  mov rax, 0
  mov rax, 0
  mov rsi, oper
  mov rdx, 2
  syscall

  lea rax, oper
  mov rax, [rax]
  cmp rax, 49
  jz  print_menu

exit:
  mov rax, 60
  xor rdi, rdi
  syscall
