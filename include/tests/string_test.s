    .code 32
    .INCLUDE "./string.s"

    .section .data
test: .asciz "abcdefghijklmnopqrstuvwxyz "
nfound: .asciz "not found\n"

    .section .bss
buffer: .space 32

    .global _start
    .section .text

_start:
    ldr r0, =test
    mov r1, #'?'
    mov r2, #30
    bl string_find_until
    cmn r0, #1
    beq not_found

    ldr r1, =buffer
    add r0, r0, #0x30
    strb r0, [r1]

    mov r0, r1
    bl print_string

exit:
    mov r7, #1
    eor r0, r0, r0
    swi #0

not_found:
    ldr r0, =nfound
    bl print_string
    b exit
