    .code 32
    .INCLUDE "./include/string.s"

    .macro write string, length
    mov r7, #4
    mov r0, #1
    ldr r1, =\string
    mov r2, #\length
    swi #0
    .endm

    .section .data
string_find_test: .asciz "string find test\n"
    .EQU string_find_test_len, . - string_find_test
starts_with_test: .asciz "starts with test\n"
    .EQU starts_with_test_len, . - starts_with_test
ends_with_test:   .asciz "ends with test\n"
    .EQU ends_with_test_len, . - ends_with_test

test:      .asciz "abcdefghijklmnopqrstuvwxyz"
start_str: .asciz "abc"
end_str:   .asciz "xyz"
nfound: .asciz "not found\n"
number: .byte 0
        .byte 10

    .section .bss
buffer: .space 32

// expected result:
/*
string find test
/
starts with test
1
1
/
ends with test
1
1
/
*/

    .global _start
    .section .text

_start:
    write string_find_test, string_find_test_len

    ldr r0, =test
    mov r1, #'?'
    mov r2, #30
    bl string_find_until

    ldr r1, =number
    add r0, r0, #0x30
    strb r0, [r1]
    write number, 2

    write starts_with_test, starts_with_test_len

    ldr r0, =start_str
    ldr r1, =start_str
    bl starts_with

    ldr r1, =number
    add r0, r0, #0x30
    strb r0, [r1]
    write number, 2

    ldr r0, =test
    ldr r1, =start_str
    bl starts_with

    ldr r1, =number
    add r0, r0, #0x30
    strb r0, [r1]
    write number, 2

    ldr r0, =start_str
    ldr r1, =test
    bl starts_with

    ldr r1, =number
    add r0, r0, #0x30
    strb r0, [r1]
    write number, 2

    write ends_with_test, ends_with_test_len

    ldr r0, =end_str
    ldr r1, =end_str
    bl ends_with

    ldr r1, =number
    add r0, r0, #0x30
    strb r0, [r1]
    write number, 2

    ldr r0, =test
    ldr r1, =end_str
    bl ends_with

    ldr r1, =number
    add r0, r0, #0x30
    strb r0, [r1]
    write number, 2

    ldr r0, =end_str
    ldr r1, =test
    bl ends_with

    ldr r1, =number
    add r0, r0, #0x30
    strb r0, [r1]
    write number, 2

    ldr r0, =ends_with_test
    mov r1, #0
    mov r2, #5
    bl substr
    cmn r0, #1
    beq not_found

    bl print_string
    
exit:
    mov r7, #1
    eor r0, r0, r0
    swi #0

not_found:
    ldr r0, =nfound
    bl print_string
    b exit
