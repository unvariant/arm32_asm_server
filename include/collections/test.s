    .code 32
    .INCLUDE "./string_llist.s"
    .INCLUDE "./hashmap.s"
    .INCLUDE "../string.s"

    .section .data
error_message: .asciz "an error occured\n"
    .equ error_message_len, . - error_message
string_llist_test_message: .asciz "linked list working!\n"
    .equ string_llist_test_message_len, . - string_llist_test_message
test_message: .asciz "Hello World!\n"
notf_message: .asciz "Entry not found\n"
linked_list: .4byte 0
    .global _start
    .section .text

_start:
    bl string_llist_new
    cmn r0, #1
    beq error

    ldr r1, =linked_list
    str r0, [r1]

    ldr r1, =string_llist_test_message
    bl string_llist_push
    cmn r0, #1
    beq error

    ldr r1, =test_message
    bl string_llist_push
    cmn r0, #1
    beq error

    mov r1, #1
    bl string_llist_remove
    cmn r0, #1
    beq error

    ldr r1, =test_message
    bl string_llist_push
    cmn r0, #1
    beq error

    ldr r1, =test_message
    bl string_llist_find
    cmn r0, #1
    beq not_found

    push { r0 }

    ldr r1, =linked_list
    ldr r0, [r1]
    bl string_llist_dealloc

    pop { r0 }
    bl print_string

    mov r0, #10
    bl hashmap_new

    cmn r0, #1
    beq error

    ldr r1, =test_message
    bl hashmap_insert

    cmp r0, #1
    beq error

exit:
    mov r7, #1
    eor r0, r0, r0
    swi #0

error:
    ldr r0, =error_message
    bl print_string
    
    b exit

not_found:
    ldr r0, =notf_message
    bl print_string

    b exit
