    .code 32

    .INCLUDE "../free.s"
    .INCLUDE "../string.s"
    .INCLUDE "../malloc.s"

    .global _start
    .section .text

_start:
    mov r0, #10
    bl malloc
    cmn r0, #1
    beq err

    bl free
    cmn r0, #1
    beq err

exit:
    mov r7, #1
    eor r0, r0, r0
    swi #0

err:
    ldr r0, =err_msg
    bl print_string
    b exit

err_msg: .asciz "Error\n"
