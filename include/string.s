    .code 32
    .IFNDEF _STRING_S_
    .EQU    _STRING_S_, 0

    .INCLUDE "./malloc.s"

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


    .align 16
strcpy:
    mov r3, r0
1:
    ldrb r2, [r1], #1
    strb r2, [r0], #1
    cmp r2, #0
    bne 1b

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
/* returns -1 on failure */
/* returns 1 on success */

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
