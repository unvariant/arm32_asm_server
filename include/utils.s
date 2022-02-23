    .code 32
    .IFNDEF _UTILS_S_
    .EQU    _UTILS_S_, 0

    .INCLUDE "definitions.s"
    .INCLUDE "string.s"


    .macro write string, length
    mov r7, #SYS_write
    mov r0, #1
    ldr r1, =\string
    mov r2, #\length
    swi #0
    .endm

/* port number in r0 */
/* ptr to address information in r1 */
/* address information size in bytes in r2 */
/* number of connections to allow in r3 */
/* returns socket_fd in r0 on success */
/* returns -1 on failure */

    .align 16
socket_setup:
    sub sp, sp, #20
    str r0, [sp, #4]
    str r1, [sp, #8]
    str r2, [sp, #12]
    str r3, [sp, #16]

    mov r7, #SYS_socket
    mov r0, #AF_INET
    mov r1, #SOCK_STREAM
    mov r2, #0
    swi #0

    cmp r0, #0
    blt socket_setup.err

    str r0, [sp]

    mov r7, #SYS_bind
    ldr r0, [sp]
    ldr r1, [sp, #8]
    ldr r2, [sp, #12]
    swi #0

    cmp r0, #0
    blt socket_setup.err

    mov r7, #SYS_listen
    ldr r0, [sp]
    ldr r1, [sp, #16]
    swi #0

    ldr r0, [sp]
    add sp, sp, #20
    bx lr

socket_setup.err:
    mov r0, #-1
    bx lr


    .ENDIF
/* _UTILS_S_ */
