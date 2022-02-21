    .code 32
    .INCLUDE "./include/string.s"
    .INCLUDE "./include/algorithms/string_search.s"

    .global _start

    .section .data
data:
key:  .asciz "key"
text: .asciz "some_key_text"
buf:  .2byte 0
err_msg: .asciz "an error occured\n"

    .section .text
data_ptr: .4byte data

    .align 4
_start:
    ldr r0, =text
    bl print_string

    ldr r3, =data_ptr
    ldr r3, [r3]
    mov r0, r3
    mov r1, r3
    add r1, r1, #(text - data)
    mov r2, #11
    bl string_search
    cmn r0, #1
    beq err

    add r0, r0, #0x30
    ldr r3, =data_ptr
    ldr r3, [r3]
    mov r1, r3
    add r1, r1, #(buf - data)
    strb r0, [r1]
    mov r0, r1
    bl print_string

exit:
    mov r7, #1
    eor r0, r0, r0
    swi #0

err:
    ldr r3, =data_ptr
    ldr r3, [r3]
    mov r0, r3
    add r0, r0, #(err_msg - data)
    bl print_string
    b exit

