    .code 32
    .IFNDEF _STRING_SEARCH_S_
    .EQU    _STRING_SEARCH_S_, 0

    .INCLUDE "./include/string.s"


/* functiion to search for substring with string using rabin karp algorithm */
/* https://en.wikipedia.org/wiki/Rabin-Karp_algorithm */
/* TODO: explore KPM and Aho-Corasick string search algorithms */

/* string pattern to find in r0 */
/* string to search through in r1 */
/* prime number used to hash strings in r2 */
/* ^ should be close to number of different possible characters in search string */
/* returns the index that the pattern was found at */
/* returns -1 if no pattern match is found */

    .align 16
string_search:
    push { r0, r1, r2, lr }
    sub sp, sp, #4

    bl strlen
    str r0, [sp]

    ldr r1, [sp, #8]
    eor r2, r2, r2
1:
    ldrb r3, [r1, r2]
    cmp r3, #0
    beq string_search.err

    add r2, r2, #1
    cmp r2, r0
    blt 1b

    ldr r1, [sp, #4]
    ldr r2, [sp, #8]
    add r1, r1, r0
    add r2, r2, r0
    sub r1, r1, #1
    sub r2, r2, #1
    ldr r3, [sp, #12]
    mov r4, #1
    mov r5, #0x7fffffff
    eor r6, r6, r6
    eor r7, r7, r7

2:
    ldrb r8, [r1]
    mul r8, r4, r8
    and r8, r8, r5
    add r6, r6, r8

    ldrb r8, [r2]
    mul r8, r4, r8
    and r8, r8, r5
    add r7, r7, r8

    sub r0, r0, #1
    cmp r0, #0
    beq 2f

    sub r1, r1, #1
    sub r2, r2, #1

    mul r4, r3, r4
    and r4, r4, r5
    b 2b

2:
    ldr r1, [sp, #8]
    cmp r6, r7
    beq string_search.match

    ldr r0, [sp]
3:
    ldrb r2, [r1, r0]
    cmp r2, #0
    beq string_search.err

    ldrb r8, [r1], #1
    mul r8, r4, r8
    and r8, r8, r5
    sub r7, r7, r8
    mul r7, r3, r7
    and r7, r7, r5
    add r7, r7, r2

    cmp r6, r7
    beq string_search.match

    b 3b

string_search.err:
    add sp, sp, #16
    mov r0, #-1
    pop { lr }
    bx lr

string_search.match:
    ldr r0, [sp, #8]
    sub r0, r1, r0
    add sp, sp, #16
    pop { lr }
    bx lr
    
    .ENDIF
/* _STRING_SEARCH_S_ */
