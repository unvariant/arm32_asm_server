    .code 32
    .INCLUDE "./hashmap.s"
    .INCLUDE "../malloc.s"

    .section .data
hashmap: .4byte 0
key:     .asciz "KEY\n"
value:   .asciz "VALUE\n"
err_msg: .asciz "ERROR\n"

    .global _start
    .section .text

_start:
    mov r0, #10
    bl hashmap_new
    cmn r0, #1
    beq err

    ldr r1, =hashmap
    str r0, [r1]

    ldr r1, =key
    ldr r2, =value
    bl hashmap_insert
    cmn r0, #1
    beq err

    ldr r0, =hashmap
    ldr r0, [r0]
    ldr r1, =key
    bl hashmap_get
    cmn r0, #1
    beq err

    bl print_string

exit:
    mov r7, #1
    eor r0, r0, r0
    swi #0

err:
    ldr r0, =err_msg
    bl print_string
    b exit
