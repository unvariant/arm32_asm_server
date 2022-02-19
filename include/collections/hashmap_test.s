    .code 32
    .INCLUDE "./include/collections/hashmap.s"
    .INCLUDE "./include/malloc.s"
    .INCLUDE "./include/string.s"

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

    ldr r0, =key
    bl string_from
    push { r0 }
    ldr r0, =value
    bl string_from
    pop { r1 }
    mov r2, r0
    ldr r0, =hashmap
    ldr r0, [r0]
    bl hashmap_insert
    cmn r0, #1
    beq err

    ldr r0, =key
    ldr r0, =hashmap
    ldr r0, [r0]
    bl hashmap_get
    cmn r0, #1
    beq err

    bl print_string

    ldr r0, =hashmap
    ldr r0, [r0]
    bl hashmap_dealloc
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
