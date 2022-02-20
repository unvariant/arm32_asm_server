    .IFNDEF _DATA_DEFINITIONS_
    .EQU    _DATA_DEFINITIONS_, 0

    .EQU AF_INET,       2
    .EQU SOL_SOCKET,    1
    .EQU SOCK_STREAM,   1
    .EQU SO_REUSEADDR,  2
    .EQU INADDR_ANY,    0
    .EQU O_NONBLOCK,    2048
    .EQU TCGETS,        0x5401
    .EQU TCSETS,        0x5402
    .EQU F_GETFL,       3
    .EQU F_SETFL,       4
    .EQU SYS_accept,    285
    .EQU SYS_socket,    281
    .EQU SYS_bind,      282
    .EQU SYS_listen,    284
    .EQU SYS_sendto,    290
    .EQU SYS_read,      3
    .EQU SYS_write,     4
    .EQU SYS_fcntl,     55
    .EQU SYS_nanosleep, 162
    .EQU SYS_close,     6
    .EQU SYS_exit,      1
    .EQU SYS_open,      5

    .ENDIF
