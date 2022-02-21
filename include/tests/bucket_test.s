    .code 32
    .INCLUDE "./hashmap_bucket.s"
    .INCLUDE "../string.s"

    .section .data
error: .asciz "an error occured\n"
nfound: .asciz "entry not found\n"
key_str:   .asciz "KEY\n"
value_str: .asciz "VALUE\n"
overwrite_str: .asciz "OVERWRITTEN\n"
bucket: .4byte 0
num:    .2byte 0
key:    .4byte 0
value:  .4byte 0
overwrite: .4byte 0

    .globl _start
    .section .text

_start:
    ldr r0, =key_str
    bl string_from
    ldr r1, =key
    str r0, [r1]

    ldr r0, =value_str
    bl string_from
    ldr r1, =value
    str r0, [r1]

    ldr r0, =overwrite_str
    bl string_from
    ldr r1, =overwrite
    str r0, [r1]

    bl bucket_new
    cmn r0, #1
    beq print_error

    ldr r1, =bucket
    str r0, [r1]

    ldr r1, =key
    ldr r1, [r1]
    ldr r2, =value
    ldr r2, [r2]
    bl bucket_insert
    cmn r0, #1
    beq print_error

    ldr r0, =value_str
    bl string_from
    ldr r1, =value
    str r0, [r1]

    ldr r0, =bucket
    ldr r0, [r0]
    ldr r1, =value
    ldr r1, [r1]
    ldr r2, =overwrite
    ldr r2, [r2]
    bl bucket_insert
    cmn r0, #1
    beq print_error

    ldr r1, =key
    ldr r1, [r1]
    bl bucket_find
    cmn r0, #1
    beq not_found

    ldr r0, [r0, #8]
    bl print_string

    dealloc:
    ldr r0, =bucket
    ldr r0, [r0]
    bl bucket_dealloc
    cmn r0, #1
    beq print_error

exit:
    mov r7, #1
    eor r0, r0, r0
    swi #0

print_error:
    ldr r0, =error
    bl print_string
    b exit

not_found:
    ldr r0, =nfound
    bl print_string
    b exit
