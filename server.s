    .code 32

    .INCLUDE "interrupt.s"
    .INCLUDE "utils.s"
    .INCLUDE "definitions.s"
    .INCLUDE "string.s"
    .INCLUDE "malloc.s"
    .INCLUDE "free.s"
    .INCLUDE "response.s"

    .section .data
req_buffer_addr:   .4byte req_buffer
res_buffer_addr:   .4byte res_buffer
file_buffer_addr:  .4byte file_buffer

no_connect_msg: .asciz "no connection found, sleeping for one second\n"
    .EQU no_connect_msg_len, . - no_connect_msg
connect_msg:    .asciz "found connection\n"
    .EQU connect_msg_len, . - connect_msg
server_err_msg: .asciz "an error occured, exiting\n"
    .EQU server_err_msg_len, . - server_err_msg
server_exit: .asciz "recieved interrupt, exiting\n"
    .EQU server_exit_len, . - server_exit

newline: .byte 10

address:   .2byte AF_INET
           .2byte 0x401F
           .4byte 0
           .8byte

socket_fd: .4byte 0
client_fd: .4byte 0

timespec:  .8byte 1
           .8byte 0

continue: .byte 1


    .EQU PORT, 8000
    .EQU socket_fd_offset, 4
    .EQU client_fd_offset, 0

    .global _start
    .section .text

    .EQU req_buffer_len,  4096
    .EQU res_buffer_len,  0x101000
    .EQU file_buffer_len, 0x100000

    .comm req_buffer, req_buffer_len + 4 
    .comm res_buffer, res_buffer_len + 4 
    .comm file_buffer, file_buffer_len + 4

_start:
    sub sp, sp, #8

    ldr r0, =signal_handler
    bl set_handler

    cmn r0, #1
    beq server.err

    mov r0, #PORT
    ldr r1, =address
    mov r2, #16
    mov r3, #5
    bl socket_setup

    cmn r0, #1
    beq server.err

    ldr r1, =socket_fd
    str r0, [r1]
    str r0, [sp, #socket_fd_offset]

    mov r7, #SYS_fcntl
    ldr r0, [sp, #socket_fd_offset]
    mov r1, #F_GETFL
    swi #0

    cmp r0, #0
    blt server.err

    orr r2, r0, #O_NONBLOCK

    mov r7, #SYS_fcntl
    ldr r0, [sp, #socket_fd_offset]
    mov r1, #F_SETFL
    swi #0

    cmp r0, #0
    blt server.err

server.loop:

accept:
    mov r7, #SYS_accept
    ldr r0, [sp, #socket_fd_offset]
    mov r1, #0
    mov r2, #0
    swi #0

    cmp r0, #0
    blt sleep_one_second

    ldr r1, =client_fd
    str r0, [r1]
    str r0, [sp, #client_fd_offset]


read:
    mov r7, #SYS_read
    ldr r0, [sp, #client_fd_offset]
    ldr r1, =req_buffer_addr
    ldr r1, [r1]
    mov r2, #req_buffer_len
    swi #0

    cmp r0, #0
    blt server.err

    mov r2, #0
    ldr r1, =req_buffer_addr
    ldr r1, [r1]
    strb r2, [r1, r0]                          // make buffer NULL terminated

    mov r0, r1
    bl print_string

    write newline, 1

connection_found:
    ldr r0, =req_buffer_addr
    ldr r0, [r0]
    ldr r1, =GET_request
    bl starts_with

    mov r0, #0x1000
    movt r0, #0x0010
    push { r0 }
    bl malloc
    cmn r0, #1
    beq server.err
    push { r0 }

    mov r0, #0x100000
    bl malloc
    cmn r0, #1
    beq server.err

    mov r3, r0
    mov r4, #0x100000
    ldr r0, =req_buffer_addr
    ldr r0, [r0]
    pop { r1, r2 }
    bl process_request

send:
    mov r7, #SYS_write
    mov r2, r1
    sub r2, r2, #1
    mov r1, r0
    ldr r0, [sp, #client_fd_offset]
    swi #0

    cmp r0, #0
    blt server.err


close:
    mov r7, #SYS_close
    ldr r0, [sp, #client_fd_offset]
    swi #0

    cmp r0, #0
    blt server.err

server.check_continue:
    ldr r1, =continue
    ldrexb r0, [r1]
    strexb r2, r0, [r1]
    cmp r2, #0
    beq server.check_continue

    cmp r0, #1
    beq server.loop

server.end:
    mov r7, #SYS_close
    ldr r0, [sp, #socket_fd_offset]
    swi #0

exit:
    mov r7, #SYS_exit
    mov r0, #0
    swi #0


sleep_one_second:
    mov r7, #SYS_write
    mov r0, #1
    ldr r1, =no_connect_msg
    mov r2, #no_connect_msg_len
    swi #0

    cmp r0, #0
    blt server.err

    mov r7, #SYS_nanosleep
    ldr r0, =timespec
    mov r1, #0
    swi #0

    cmp r0, #0
    blt server.err

    b server.check_continue


server.err:
    mov r7, #SYS_write
    mov r0, #1
    ldr r1, =server_err_msg
    mov r2, #server_err_msg_len
    swi #0

    b server.end


signal_handler:
    ldr r1, =continue
    ldrexb r0, [r1]
    mov r0, #1
    strexb r2, r0, [r1]
    cmp r2, #0
    beq signal_handler

    write server_exit, server_exit_len
    b server.end


/* _SERVER_S_ */
