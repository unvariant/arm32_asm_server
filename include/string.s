    .code 32
    .IFNDEF _STRING_S_
    .EQU    _STRING_S_, 0

    .INCLUDE "./include/malloc.s"

/* ptr to string in r0 */

    .align 16
strlen:
    mov r1, r0
    eor r0, r0, r0

    ldrb r2, [r1], #1
    cmp r2, #0
    beq strlen.end

1:
    ldrb r2, [r1], #1
    add r0, r0, #1
    cmp r2, #0
    bne 1b

strlen.end:
    bx lr


/* dest string in r0 */
/* src  string in r1 */
/* returns ptr to dest string on success in r0 */
/* returns number of bytes copied on success in r1 */

    .align 16
strcpy:
    mov r3, r0
1:
    ldrb r2, [r1], #1
    strb r2, [r0], #1
    cmp r2, #0
    bne 1b

    sub r1, r0, r3
    mov r0, r3
    bx lr


    .align 16
string_from:
    push { r0, lr }
    bl strlen
    add r0, r0, #1           // add one for NULL terminator

    bl malloc
    cmn r0, #1
    beq string_from.err

    ldr r1, [sp]
    bl strcpy

    add sp, sp, #4
    pop { lr }
    bx lr

string_from.err:
    add sp, sp, #4
    mov r0, #-1
    pop { lr }
    bx lr


/* ptr to string in r0 */
/* ptr to string in r1 */
/* returns 1 on success */
/* returns -1 on failure */

    .align 16
strcmp:
    mov r2, r0            // mov r0 into r2

    ldrb r3, [r1], #1     // load first byte of r1
    ldrb r4, [r2], #1     // load first byte of r2

    add r5, r3, r4        // r5 = r3 + r4
    cmp r5, #0            // if r5 is zero both r3 and r4 are zero
    beq strcmp.eq         // if both are zero return true (empty string == empty string)

    cmp r3, #0            // if only one is zero return false
    beq strcmp.ne

    cmp r4, #0            // if only one is zero return false
    beq strcmp.ne
1:
    ldrb r3, [r1], #1     // load next byte of r1
    ldrb r4, [r2], #1     // load next byte of r2

    cmp r3, r4            // compare the bytes
    bne strcmp.ne         // if not equal return false

    add r5, r3, r4        // r5 = r3 + r4
    cmp r5, #0            // loop until both bytes are NULL terminators
    bne 1b

strcmp.eq:
    mov r0, #1            // 1 for equal
    bx lr                 // return

strcmp.ne:
    mov r0, #-1           // -1 for not equal
    bx lr                 // return


/* ptr to string in r0 */
/* ptr to string in r1 */
/* checks if r0 starts with r1 */
/* returns 1 on success */
/* returns -1 on failure */

    .align 16
starts_with:
    ldrb r2, [r0], #1
    ldrb r3, [r1], #1

    cmp r3, #0
    beq starts_with.eq

    cmp r2, #0
    beq starts_with.ne

    cmp r2, r3
    beq starts_with

starts_with.ne:
    mov r0, #-1
    bx lr

starts_with.eq:
    mov r0, #1
    bx lr


/* ptr to string in r0 */
/* ptr to string in r1 */
/* checks if r0 ends with r1 */
/* returns 1 on success */
/* returns -1 on failure */

    .align 16
ends_with:
    push { r0, r1, lr }
    sub sp, sp, #4

    bl strlen
    str r0, [sp]

    ldr r0, [sp, #8]
    bl strlen

    ldr r2, [sp]
    mov r3, r0
    cmp r2, r3
    blt ends_with.err

    ldr r0, [sp, #4]
    ldr r1, [sp, #8]
    sub r2, r2, r3
    add r0, r0, r2
    bl strcmp

    add sp, sp, #12
    pop { lr }
    bx lr

ends_with.err:
    mov r0, #-1
    add sp, sp, #12
    pop { lr }
    bx lr


/* ptr to string in r0 */
/* char to find in r1 */
/* maximum characters to process in r2 */
/* returns index of first occurance of char in r1 */
/* returns -1 on not found */

    .align 16
string_find_until:
    cmp r2, #0
    beq 2f

    mov r3, r0
    eor r0, r0, r0
1:
    ldrb r4, [r3, r0]
    cmp r4, r1
    beq 3f

    add r0, r0, #1
    sub r2, r2, #1
    ands r4, r4, r2
    bne 1b
2:
    mov r0, #-1
3:
    bx lr


/* ptr to signed/unsigned integer in r0 */
/* ptr to buffer in r1 to write number to */
/* writes give number into buffer and NULL terminates the buffer */
/* returns ptr to buffer in r0 */
/* returns number of bytes written on success (including NULL terminator) in r1 */
/* returns -1 on failure */

    .align 16
int_to_string:
    eor r2, r2, r2
    sub sp, sp, #8
    str r2, [sp]
    str r1, [sp, #4]
    mov r2, #0xCCCD
    movt r2, #0xCCCC

1:
    mov r3, r0
    umull r5, r4, r0, r2

    lsr r4, r4, #3
    mov r0, r4

    mov r5, r4
    lsl r4, r4, #2
    add r4, r4, r5
    lsl r4, r4, #1

    sub r3, r3, r4
    add r3, r3, #0x30
    push { r3 }
    tst r0, r0
    bne 1b

2:
    pop { r2 }
    strb r2, [r1], #1
    tst r2, r2
    bne 2b

int_to_string.end:
    pop { r0 }
    sub r1, r1, r0
    bx lr


/* ptr to string to print in r0 */

    .align 16
print_string:
    push { r0, lr }
    bl strlen

    pop { r1, lr }
    cmp r0, #0
    beq print_string.end

    mov r7, #4
    mov r2, r0
    mov r0, #1
    swi #0

print_string.end:
    bx lr

    .ENDIF
/* _STRING_S_ */
