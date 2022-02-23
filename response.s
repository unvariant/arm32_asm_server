    .code 32
    .IFNDEF _RESPONSE_S_
    .EQU    _RESPONSE_S_, 0

    .INCLUDE "definitions.s"
    .INCLUDE "string.s"
    .INCLUDE "string_search.s"


/* ptr to path to file in r0 */
/* ptr to buffer in r1 to write response */
/* ptr to length of response buffer in r2 */
/* ptr to buffer in r3 to store file */
/* ptr to length of file buffer in r4 */
/* response code in r5 */
/* returns ptr to response buffer in r0 */
/* returns number of bytes written in r1 */

    .align 16
create_response:
    push { r0, r1, r2, r3, r4, r5, lr }
    sub sp, sp, #4

    ldr r0, [sp, #8]
    ldr r1, =create_response.status_start
    bl strcpy

    add r0, r0, r1
    sub r0, r0, #1

    str r0, [sp]
    mov r1, r0
    ldr r0, [sp, #24]
    bl int_to_string

    ldr r0, [sp]
    add r0, r0, r1
    mov r1, #0x0a
    strb r1, [r0, #-1]

    ldr r1, =create_response.static
    bl strcpy

    add r0, r0, r1
    sub r0, r0, #1
    str r0, [sp]

    mov r7, #SYS_open
    ldr r0, [sp, #4]
    mov r1, #0
    swi #0
    cmp r0, #0
    blt create_response.err

    mov r7, #SYS_read
    ldr r1, [sp, #16]
    ldr r2, [sp, #20]
    swi #0
    cmp r0, #0
    blt create_response.err

    ldr r1, [sp, #16]
    mov r2, #0
    str r2, [r1, r0]

    ldr r1, [sp]
    bl int_to_string

    add r0, r0, r1
    mov r1, #0x0a0a
    strh r1, [r0, #-1]
    add r0, r0, #1

    ldr r1, [sp, #16]
    bl strcpy
    add r1, r0, r1
    
create_response.end:
    ldr r0, [sp, #8]
    sub r1, r1, r0
    add sp, sp, #28
    pop { lr }
    bx lr

create_response.err:
    mov r0, #-1
    add sp, sp, #28
    pop { lr }
    bx lr

    .ltorg
create_response.status_start: .asciz "HTTP/1.1 "
create_response.static:       .ascii "Content-Type: text/html;charset=UTF-8\n"
                              .asciz "Content-Length: "
debug: .asciz "debug\n"
/* ptr to request string in r0 */
/* ptr to response buffer in r1 */
/* length of response buffer in r2 */
/* ptr to file buffer in r3 */
/* length of file buffer in r4 */
/* ptr to directory to search for files in r5 */

    .align 16
process_GET:
    push { r0, r1, r2, r3, r4, r5, lr }
    sub sp, sp, #4

    add r0, r0, #4
    mov r1, #0x20
    bl string_find
    cmn r0, #1
    beq server.end

    add r2, r0, #4
    ldr r0, [sp, #4]
    mov r1, #4
    bl substr
    cmn r0, #1
    beq process_GET.err
    str r0, [sp]

    mov r1, r0
    ldr r0, =invalid_path
    mov r2, #127
    bl string_search
    cmn r0, #1
    bne process_GET.err

    ldr r1, [sp]
    ldr r0, [sp, #24]
    bl concat
    cmn r0, #1
    beq process_GET.err

    ldr r1, [sp]
    str r0, [sp]
    mov r0, r1
    bl free
    cmn r0, #1
    beq process_GET.err

    ldr r0, [sp]
    bl print_string
    ldr r0, [sp]
    ldr r1, [sp, #8]
    ldr r2, [sp, #12]
    ldr r3, [sp, #16]
    ldr r4, [sp, #20]
    mov r5, #200
    bl create_response
    cmn r0, #1
    beq process_GET.err

    push { r1 }
    ldr r1, [sp, #4]
    str r0, [sp, #4]
    mov r0, r1
    bl free
    cmn r0, #1
    beq process_GET.err
    pop { r1 }

    ldr r0, [sp]
    add sp, sp, #28
    pop { lr }
    bx lr

process_GET.err:
    mov r0, #-1
    add sp, sp, #28
    pop { lr }
    bx lr

    .ltorg
invalid_path: .asciz ".."

/* TODO: process POST information */
    .align 16
process_POST:


/* request buffer in r0 */
/* response buffer in r1 */
/* length of response buffer in r2 */
/* file buffer in r3 */
/* length of file buffer in r4 */

    .align 16
process_request:
    push { r0, r1, r2, r3, r4, lr }
    sub sp, sp, #4

    ldr r1, =GET_request
    bl starts_with
    cmp r0, #1
    beq process_request.GET

process_request.error_response:
    ldr r0, [sp, #8]
    ldr r1, =default_err_response
    bl strcpy

    b process_request.end

process_request.GET:
    ldr r0, [sp, #4]
    ldr r1, [sp, #8]
    ldr r2, [sp, #12]
    ldr r3, [sp, #16]
    ldr r4, [sp, #20]
    ldr r5, =GET_search_dir
    bl process_GET
    cmn r0, #1
    beq process_request.error_response

process_request.end:
    add sp, sp, #24
    pop { lr }
    bx lr

    .ltorg
GET_request:                  .asciz "GET "
POST_request:                 .asciz "POST "
GET_search_dir:               .asciz "static"
default_err_response:         .ascii "HTTP/1.1 404\n"
                              .ascii "Content-Type: text/html;charset=UTF-8\n"
                              .ascii "Content-Length: 18\n\n"
                              .asciz "segmentation fault"


    .ENDIF
/* _RESPONSE_S_ */
