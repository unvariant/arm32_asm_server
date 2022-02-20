    .code 32
    .IFNDEF _UTILS_S_
    .EQU    _UTILS_S_, 0

    .INCLUDE "data_definitions.s"
    .INCLUDE "string.s"


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


/* ptr to path to file in r0 */
/* ptr to buffer in r1 to write response */
/* ptr to length of response buffer in r2 */
/* ptr to buffer in r3 to store file */
/* ptr to length of file buffer in r4 */

    .align 16
create_response:
    push { r0, r1, r2, r3, r4, lr }
    sub sp, sp, #4

    ldr r0, [sp, #8]
    ldr r1, =create_response.res_temp
    bl strcpy

    add r0, r0, r1
    sub r0, r0, #1

    ldr r1, =create_response.content_len
    bl strcpy

    add r0, r0, r1
    sub r0, r0, #1
    str r0, [sp]

    mov r7, #SYS_open
    ldr r0, [sp, #4]
    swi #0

    cmp r0, #0
    blt create_response.err

    mov r7, #SYS_open
    ldr r0, [sp, #4]
    mov r1, #0
    swi #0

    cmp r0, #0
    blt create_response.err

    mov r7, #SYS_read
    ldr r1, [sp, #12]
    ldr r2, [sp, #16]
    swi #0

    cmp r0, #0
    blt create_response.err

    ldr r1, [sp, #12]
    mov r2, #0
    str r2, [r1, r0]

    ldr r1, [sp]
    bl int_to_string

    add r0, r0, r1
    mov r1, #0x0a0a
    strh r1, [r0, #-1]
    add r0, r0, #1

    ldr r1, [sp, #12]
    bl strcpy
    add r1, r0, r1

create_response.end:
    ldr r0, [sp, #8]
    sub r1, r1, r0
    add sp, sp, #24
    pop { lr }
    bx lr

create_response.err:
    mov r0, #-1
    add sp, sp, #24
    pop { lr }
    bx lr

    .section .data
create_response.res_temp:    .ascii "HTTP/1.1 200 OK\n"
                             .asciz "Content-Type: text/html;charset=UTF-8\n"
create_response.content_len: .asciz "Content-Length: "


    .ENDIF
/* _UTILS_S_ */
