    .code 32
    .IFNDEF _STRING_S_
    .EQU    _STRING_S_, 0

    .include "/home/pi/project/malloc.s"

/* number of bytes in r0 */
/* return pointer in r0 */
/* return -1 on alloc fail */
string_new:
    push { lr }
    cmp r0, 1
    jl string_new.error
    bl malloc
    
    cmn r0, 1
    jz string_new.error
    
    pop { lr }
    bx lr

string_new.error:
    pop { lr }
    mov r0, #-1
    bx lr

    .ENDIF
/ * _STRING_S_ */
