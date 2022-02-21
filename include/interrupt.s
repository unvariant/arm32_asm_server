    .code 32
    .IFNDEF _EXIT_S_
    .EQU    _EXIT_S_, 0

    .INCLUDE "malloc.s"

    .EQU SYS_sigaction, 67
    .EQU SIGINT,        2

/*
struct sigaction {
    void     (*sa_handler)(int);                        ; 4 bytes
    void     (*sa_sigaction)(int, siginfo_t *, void *); ; 4 bytes
    sigset_t   sa_mask;                                 ; 128 bytes
    int        sa_flags;                                ; 4 bytes
    void     (*sa_restorer)(void);                      ; 4 bytes
};
total:  144 bytes
*/


/* ptr to signal hander function in r0 */
/* returns 1 on success */
/* returns -1 on failure */

    .align 16
set_handler:
    push { r0, lr }

    mov r0, #144
    bl malloc

    cmn r0, #1
    beq set_handler.err

    ldr r1, [sp]
    str r1, [r0]

    mov r7, #SYS_sigaction
    mov r1, r0
    mov r0, #SIGINT
    mov r2, #0
    swi #0

    cmp r0, #0
    blt set_handler.err

    mov r0, #1
    add sp, sp, #4
    pop { lr }
    bx lr

set_handler.err:
    mov r0, #-1
    add sp, sp, #4
    pop { lr }
    bx lr


    .ENDIF
