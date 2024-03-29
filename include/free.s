    .code 32
    .IFNDEF _FREE_S_
    .EQU    _FREE_S_, 0

    .INCLUDE "string.s"


    .align 16

free:
//r0 contains pointer to memory to free
    ldr r1, [r0, #-4]             // load chunk.freed
    cmp r1, #0
    beq free.free

    push { lr }
    ldr r0, =double_free
    bl print_string
    pop { lr }

    mov r0, #-1
    bx lr

free.free:
    mov r1, #1
    str r1, [r0, #-4]              // mark the chunk as freed
    ldr r1, [r0, #-12]             // load size of chunk in bytes
    add r1, r1, #12                // add 12 bytes to size to account for chunk variables
    ldr r0, [r0, #-8]              // load chunk's parent bin
    
    ldr r2, [r0, #8]               // load amount of freed bytes
    add r2, r2, r1                 // add chunk size
    str r2, [r0, #8]               // store back
    
    ldr r1, [r0, #4]               // load amount of allocated bytes
    cmp r2, r1                     // if equal bin can be unmapped
    bne free.end

    ldr r1, [r0, #12]              // load previous bin
    ldr r2, [r0, #16]              // load next bin

    cmp r1, #0
    beq free.set_heap          // if prev is NULL then bin must be first in the chain

/* r1 != NULL */
    
    cmp r2, #0                     // if next is NULL then must be last in the chain
    beq free.set_next

/* r1 != NULL and r2 != NULL */

    str r1, [r2, #12]              // next bin.prev = prev bin
    str r2, [r1, #16]              // prev bin.next = next bin
    b free.munmap

free.set_heap:

    cmp r2, #0
    beq free.zero_heap             // if next is also NULL must be only bin in the chain

/* r1 == NULL and r2 != NULL */

    ldr r3, =free.heap_addr        // set first bin in heap to next bin
    ldr r3, [r3]
    str r2, [r3]
    b free.munmap

free.set_next:
/* r1 != NULL and r2 == NULL */

    str r2, [r1, #16]
    b free.munmap

free.zero_heap:
/* r1 == NULL and r2 == NULL */
    
    ldr r3, =free.heap_addr        // set first bin in heap to NULL
    ldr r3, [r3]
    str r1, [r3]

free.munmap:
    ldr r1, [r0]                   // load size of bin (not includeing bin variables)
    add r1, r1, #20                // add to account for bin variables
    
    mov r7, #91                    // munmap
    swi #0                         // r0 contains addr of bin, r1 contains size of bin and bin variables

    cmn r0, #1                     // check for munmap failure
    bne free.end 

    push { lr }
    ldr r0, =munmap_fail
    bl print_string
    pop { lr }
     
    mov r0, #-1                    // set r0 to -1 to indicate failure
    bx lr

free.end:
    mov r0, #0                     // set r0 to 0 to indicate success
    bx lr                          // return

    .section .data
    .ltorg

double_free: .asciz "(free): double free\n"
munmap_fail: .asciz "(free): munmap fail\n"

    .IFNDEF heap
heap: .4byte 0
    .ENDIF

free.heap_addr: .4byte heap

    .ENDIF
