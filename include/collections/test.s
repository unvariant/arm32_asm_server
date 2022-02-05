    .code 32
    .INCLUDE "./string_llist.s"

    .section .data
error_message: .ascii "an error occured\n"
    .equ error_message_len, . - error_message
string_llist_test_message: .ascii "linked list working!\n"
    .equ string_llist_test_message_len, . - string_llist_test_message

    .global _start
    .section .text

_start:
    bl string_llist_new
    cmn r0, #1
    beq error

    ldr r1, =string_llist_test_message
    bl string_llist_push
    cmn r0, #1
    beq error

    ldr r1, =error_message
    bl string_llist_push
    cmn r0, #1
    beq error

    mov r1, #0
    bl string_llist_get
    cmn r0, #1
    beq error

    mov r1, r0
    mov r7, #4
    mov r0, #1
    mov r2, #string_llist_test_message_len
    swi #0

exit:
    mov r7, #1
    eor r0, r0, r0
    swi #0

error:
    mov r7, #4
    mov r0, #1
    ldr r1, =error_message
    mov r2, #error_message_len
    swi #0
    
    b exit
