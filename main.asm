section .data
  hello_msg  db  "Hello, Calculator!", 0xA
  hello_len  equ  $ - hello_msg

  asterisks  db  "*-------------------------*", 0xA
  aster_len  equ  $ - asterisks

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

  exit_msg  db  "0. Exit", 0xA
  exit_len  equ  $ - exit_msg

  choice  db  "Your choice: "
  ch_len  equ  $ - choice

  in_num1  db  "Enter num1: "
  in_num2  db  "Enter num2: "
  inp_len  equ  $ - in_num2

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
  oper:    resb   2    ; A 1 byte container for the operator. The extra byte is for '\n'.
  num1:    resb  12    ; A (11+1) bytes container. The extra byte is for '\n'.
  num2:    resb  12    ; A (11+1) bytes container. The extra byte is for '\n'.
  result:  resb  24    ; A 24 bytes container for result. The extra byte is for '\n'.

section .text

; A procedure to convert an ASCII stream of 
;   numbers to an integer stream.
; Arg1 (rax): The ASCII stream
ascii_to_num:
  push rbp
  mov  rbp, rsp

  xor r8,  r8     ; The number, after conversion.
  xor rdx, rdx    ; Register to load the incoming character.
  xor rcx, rcx    ; Counter.
  xor rsi, rsi    ; sign-bit: will be set 1 if the number 
                  ; has a hyphen-minus

.loop1:
  ; Extract each ASCII character. This value is an 
  ; ordinal, only its human interpretation is a 
  ; number.
  mov dl, BYTE [rax+rcx]

  ; Check if we have reached one past the end of 
  ; the actual digits, i.e. the new line character.
  cmp dl, 0xA
  jnz .cont

  ; If yes, prepare for return.
  ; Make the number negative if a hyphen-minus was 
  ; found.
  cmp rsi, 1
  jnz .return
  neg r8

.return:
  mov rax, r8
  pop rbp
  ret

.cont:
  cmp dl, 45    ; A (-) in the number.
  jnz .parse_digit

  mov rsi, 1
  inc rcx
  jmp .loop1

.parse_digit:
  ; The ordinals corresponding to 0-9 ASCII chars 
  ; are 48-57 in decimals. To obtain the actual 
  ; decimal ordinal corresponding to them, we've 
  ; subtract 48 from the ASCII value.
  sub dl, 48

  ; We are moving left to right. The leftmost value 
  ;   carries the largest weight. To construct the 
  ;   result correctly, we have to multiply the 
  ;   existing number in the result with 10, followed 
  ;   by adding the newly converted ASCII character.
  ; For example, take "56\n" as input.
  ; - The result is initialized to 0.
  ; - First  iteration, we get (0*10 + 5), i.e. 5.
  ; - Second iteration, we get (5*10 + 6), i.e. 56.
  imul  r8,  10
  movzx rdx, dl
  add   r8,  rdx

  ; Increase the counter.
  inc rcx
  jmp .loop1


; Convert a number into its ASCII representation 
; and returns the number of digits in the number.
; Arg1 (rax): number
num_to_ascii:
  push rbp
  mov  rbp, rsp

  ; mov rdi, rax
  ; mov rax, 60
  ; syscall

  mov rsi, rax    ; copy the original number
  mov r10, 1      ; Count of digits in number (initialize with 1).
  xor r8, r8      ; sign-bit status (initialized with "not set")

; Count the digits in number.
.loop1:
  cqo             ; sign-extend RDX
  mov  rdi, 10
  idiv rdi        ; num = num/10

  cmp rax, 0
  jnz .not_yet

  mov rax, rsi    ; restore the original number in rax.
  mov r11, r10    ; copy the number of digits.

  ; Increase r10 by 1 if the sign-bit is set. This is 
  ; required as we need to put a hyphen-minus before 
  ; the number.
  test rax, rax
  jns  .loop2

  inc r10
  inc r11
  neg rax      ; make the number unsigned for [REASON]
  mov r8, 1    ; sign-bit active now, later used in placing the hyphen.
  jmp .loop2

.not_yet:
  inc r10
  jmp .loop1

; Divide the result by 10 until the quotient 
; becomes 0, i.e. no more digits left. Put the 
; remainder from opposite side in the buffer.
.loop2:
  cqo
  mov  rdi, 10
  idiv rdi

  lea rsi, result
  add dl, 48
  mov BYTE [rsi+r10-1], dl
  dec r10

  cmp rax, 0
  jnz .loop2

  ; Put the hyphen-minus at start.
  cmp r8, 1
  jnz .return
  mov BYTE [rsi+r10-1], 45

; Return the count of digits in rax.
.return:
  mov rax, r11
  pop rbp
  ret


global _start
_start:
  push r12
  push r13
  push r14

  mov rax, 1
  mov rdi, 1
  mov rsi, hello_msg
  mov rdx, hello_len
  syscall

print_menu:
  mov rax, 1
  mov rdi, 1
  mov rsi, asterisks
  mov rdx, aster_len
  syscall

  mov rax, 1             ; sys_write
  mov rdi, 1             ; fd=stdout
  mov rsi, select_msg    ; buffer
  mov rdx, select_len    ; buffer length
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

  ; Take the operator.
  mov rax, 0       ; sys_read
  mov rdi, 0       ; fd=stdin
  lea rsi, oper    ; buffer
  mov rdx, 2       ; buffer capacity
  syscall

  lea rax, oper
  cmp BYTE [rax], 48    ; ASCII for 0
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
  mov rdx, 12
  syscall

  mov rax, 1
  mov rdi, 1
  mov rsi, in_num2
  mov rdx, inp_len
  syscall

  mov rax, 0
  mov rdi, 0
  lea rsi, num2
  mov rdx, 12
  syscall

  ; Call ascii_to_num and convert the ASCII streams 
  ; into actual integers.
  xor r12, r12    ; num1
  xor r13, r13    ; num2
  xor r14, r14    ; result

  lea  rax, num1
  call ascii_to_num
  mov  r12, rax

  lea  rax, num2
  call ascii_to_num
  mov  r13, rax

  ; Perform the operation.
  mov r14, r12     ; load num1 in result
  lea rax, oper    ; load the operator in rax

  cmp BYTE [rax], 49  ; 1 (+)
  jz  _add

  cmp BYTE [rax], 50  ; 2 (-)
  jz  _sub

  cmp BYTE [rax], 51  ; 3 (*)
  jz  _mul

  cmp BYTE [rax], 52  ; 4 (/)
  jz  _div

  jnz unsp_op

_add:
  add r14, r13
  jmp print_result

_sub:
  sub r14, r13
  jmp print_result

_mul:
  imul r14, r13
  jmp print_result

_div:
  ; Check for division by zero.
  cmp r13, 0
  jz  ._div_by_zero

  mov  rax, r12
  cqo              ; sign extend RDX (RAX:RDX)
  idiv r13         ; (Quotient:RAX && Remainder:RDX)
  mov  r14, rax    ; copy the quotient in the result register
  jmp  print_result

._div_by_zero:
  mov rax, 1
  mov rdi, 1
  mov rsi, div_by_zero_msg
  mov rdx, div_by_zero_len
  syscall
  jmp ask_again

unsp_op:
  mov rax, 1
  mov rdi, 1
  mov rsi, unsp_op_msg
  mov rdx, unsp_op_len
  syscall
  jmp ask_again

print_result:
  lea rax, oper

  cmp BYTE [rax], 49
  jz  add_res

  cmp BYTE [rax], 50
  jz  sub_res

  cmp BYTE [rax], 51
  jz  mul_res

  cmp BYTE [rax], 52
  jz  div_res

add_res:
  mov rax, 1
  mov rdi, 1
  mov rsi, res_add
  mov rdx, res_len
  syscall
  jmp ress

sub_res:
  mov rax, 1
  mov rdi, 1
  mov rsi, res_sub
  mov rdx, res_len
  syscall
  jmp ress

mul_res:
  mov rax, 1
  mov rdi, 1
  mov rsi, res_mul
  mov rdx, res_len
  syscall
  jmp ress

div_res:
  mov rax, 1
  mov rdi, 1
  mov rsi, res_div
  mov rdx, res_len
  syscall
  jmp ress

ress:
  mov rax, r14
  call num_to_ascii

  mov rdx, rax
  mov rax, 1
  mov rdi, 1
  lea rsi, result
  syscall

ask_again:
  mov rax, 1
  mov rdi, 1
  mov rsi, cont_msg
  mov rdx, cont_len
  syscall

  mov rax, 0
  mov rdi, 0
  mov rsi, oper
  mov rdx, 2
  syscall

  lea rax, oper
  cmp BYTE [rax], 49
  jz  print_menu

exit:
  mov rax, 60
  xor rdi, rdi
  syscall
