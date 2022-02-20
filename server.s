    .code 32
    .INCLUDE "utils.s"
    .INCLUDE "data_definitions.s"

    .section .data
    .align 2
req_buffer_addr:   .4byte req_buffer
res_buffer_addr:   .4byte res_buffer
file_buffer_addr: .4byte file_buffer

no_connect_msg: .asciz "no connection found, sleeping for one second\n"
    .EQU no_connect_msg_len, . - no_connect_msg
connect_msg:    .asciz "found connection\n"
    .EQU connect_msg_len, . - connect_msg
server_err_msg: .asciz "an error occured, exiting\n"
    .EQU server_err_msg_len, . - server_err_msg

    .align 2
address:   .2byte AF_INET
           .2byte 0x401F
           .4byte 0
           .8byte

socket_fd: .4byte 0
client_fd: .4byte 0

timespec:  .8byte 1
           .8byte 0

default_path:   .asciz "static/index.html"

bad_req:        .ascii "HTTP/1.1 400 Malformed Request\n"
                .ascii "Content-Type: text/html;charset=UTF-8\n"
                .ascii "Content-Length: 17\n\n"
                .asciz "Malformed Request"

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

    mov r0, #PORT
    ldr r1, =address
    mov r2, #16
    mov r3, #1
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
    strb r2, [r1, r0]          // make buffer NULL terminated

connection_found:
    mov r7, #SYS_write
    mov r0, #1
    ldr r1, =connect_msg
    mov r2, #connect_msg_len
    swi #0

    cmp r0, #0
    blt server.err

    ldr r0, =default_path
    ldr r1, =res_buffer_addr
    ldr r1, [r1]
    mov r2, #(res_buffer_len & 0xffff)
    movt r2, #(res_buffer_len >> 16 & 0xffff)
    ldr r3, =file_buffer_addr
    ldr r3, [r3]
    mov r4, #file_buffer_len
    bl create_response

    cmn r0, #1
    beq server.err

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

    b server.loop

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

    b server.loop

server.err:
    mov r7, #SYS_write
    mov r0, #1
    ldr r1, =server_err_msg
    mov r2, #server_err_msg_len
    swi #0

    b exit


/* _SERVER_S_ */
