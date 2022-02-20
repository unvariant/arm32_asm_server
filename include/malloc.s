    .code 32
    .IFNDEF _MALLOC_S
    .EQU    _MALLOC_S, 0

/* struct chunk {                                                  */
/*      int     size:     4    bytes ;size of the chunk in bytes   */
/*      bin *   current:  4    bytes ;bin the chunk belongs to     */
/*      bool    freed     4    bytes ;chunk has been freed or not  */
/*      void data[size]              ;usable memory                */

/* struct bin {                                                    */
/*      int     size:     4    bytes ;size of the bin in bytes     */
/*      int     alloc:    4    bytes ;amount of allocated bytes    */
/*      int     freed:    4    bytes ;amount of unused memory      */
/*      bin *   prev:     4    bytes ;previous bin                 */
/*      bin *   next:     4    bytes ;next bin                     */
/*      chunk   chunks[size]         ;usable memory                */

.equ PROT_NONE,   0
.equ PROT_READ,   1
.equ PROT_WRITE,  2
.equ PROT_EXEC,   4

.equ MAP_ANON,    32
.equ MAP_PRIVATE, 2

.equ malloc_PROT,  PROT_READ | PROT_WRITE
.equ malloc_FLAGS, MAP_ANON  | MAP_PRIVATE


    .align 16
new_bin:
//r0 is size of bin (must be page aligned)
    push { r0 }                   // save size of bin
    mov r7, #192                  // mmap2
    mov r1, r0                    // amount to allocate
    mov r0, #0                    // kernel chooses where to map pages
    mov r2, #malloc_PROT          // read and write permission
    mov r3, #malloc_FLAGS         // not backed by file, private pages
    mov r4, #-1                   // no file descriptor
    mov r5, #0                    // no offset
    swi #0

    pop { r1 }                    // load size of bin
    cmn r0, #1                    // check for -1 (mmap fail)
    bne new_bin.bin               // if not -1 continue
                                  
    mov r0, #-1                   // set r0 to -1 to indicate failure
    bx lr                         // return

new_bin.bin:    
    
    sub r1, r1, #20               // subtract to account of local variables
    str r1, [r0]                  // set bin.size to size
    mov r1, #0
    str r1, [r0, #4]              // set bin.alloc to zero
    str r1, [r0, #8]              // set bin.freed to zero
    str r1, [r0, #12]             // set bin.prev to NULL
    str r1, [r0, #16]             // set bin.next to NULL

new_bin.end:
    bx lr                         // return r0 contains pointer to new bin


    .align 16
new_chunk:
//size of chunk in r0 (including chunk variables)
//pointer in r1
//current bin in r2
    sub r0, r0, #12               // subtract 12 from size to account for chunk variables
    str r0, [r1], #4              // set chunk.size
    str r2, [r1], #4              // set chunk.bin
    mov r0, #0
    str r0, [r1], #4              // set chunk.freed to false
    mov r0, r1
    bx lr                         // return pointer to memory after chunk variables


    .align 16
page_align:
//integer in r0
    lsr r2, r0, #12               // r2 = r0 >> 12    
    lsl r1, r2, #12               // r1 = r2 << 12
    sub r1, r0, r1                // r1 = r0 - r1
    cmp r1, #0
    beq page_align.aligned
                                  // round up to multiple of 4096   
    add r0, r2, #1                // r0 = r2 + 1
    lsl r0, r0, #12               // r0 = r0 << 12

page_align.aligned:
    bx lr                         // result in r0


    .align 16
malloc:
//r0 is amount of bytes to allocate
    push { lr }                   // save link register
    cmp r0, #0
    ble malloc.end                // return if r0 is less than or equal to zero
    
    add r0, r0, #12               // extra space for struct variables
    ldr r8, =malloc.heap_addr
    ldr r8, [r8]
    ldr r9, [r8]
    cmp r9, #0                    // check if pointer is null
    bne malloc.find_bin           // if not continue
    
    push { r0 }                   // save amount of bytes to alloc
    bl page_align                 // make amount of bytes a multiple of 4096
    bl new_bin                    // create new bin
    cmn r0, #-1                   // check for failure to create new bin
    bne malloc.success

    mov r7, #4
    mov r0, #1
    ldr r1, =malloc.new_bin_err
    mov r2, #malloc.new_bin_err_len
    swi #0

    pop { r0, lr }                // restore link register
    mov r0, #-1                   // set r0 to -1 to indicate failure
    bx lr                         // return

malloc.success:
    ldr r8, =malloc.heap_addr     // load addr of heap
    ldr r8, [r8]
    str r0, [r8]                  // store addr of first bin
    mov r9, r0                    // move pointer to bin into r9
    pop { r0 }                    // restore amount of bytes to alloc
    b malloc.find_bin.end
    
malloc.find_bin:
// r8 points to heap
// r0 contains amount of bytes to alloc
    ldr r9, [r8]                  // load addr of first bin

malloc.find_bin.loop:
    ldr r1, [r9]                  // load size of bin (not including bin variables)
    ldr r2, [r9, #4]              // load amount of bin's allocated memory
    sub r2, r1, r2                // calculate amount of unused memory
    cmp r0, r2
    ble malloc.find_bin.end       // if r0 is less than or equal to r2 break

    ldr r1, [r9, #16]             // pointer to next bin
    cmp r1, #0                    // check if next is NULL
    bne malloc.find_bin.next

    push { r0 }                   // save r0
    bl page_align                 // make r0 a multiple of 4096
    bl new_bin                    // create new bin
    cmp r0, #0                    // check for failure to create new bin
    beq malloc.fail
    str r0, [r9, #16]             // set current bin.next to the new bin
    str r9, [r0, #12]             // set new bin.prev to current bin
    mov r9, r0                    // set r9 new bin
    pop { r0 }                    // restore r0
    b malloc.find_bin.end         // break

malloc.find_bin.next:
    mov r9, r1                    // set r9 to next bin
    b malloc.find_bin.loop        // continue

malloc.find_bin.end:
    ldr r1, [r9, #4]              // amount of allocated bytes
    mov r2, r1                    // move r1 into r2
    add r2, r2, r0                // add chunk size to allocated bytes
    str r2, [r9, #4]              // store new updated allocated bytes
    add r1, r9, r1                // r1 = bin + allocated bytes
    add r1, r1, #20               // calculate next position for new chunk
    mov r2, r9
    bl new_chunk

malloc.end:
    pop { lr }                    // restore link register
    bx lr                         // return

malloc.fail:
    mov r7, #4
    mov r0, #1
    ldr r1, =malloc.fail_msg
    mov r2, #malloc.fail_msg_len
    swi #0

    pop { r0, lr }
    mov r0, #-1
    bx lr

    .section .data
malloc.new_bin_err: .asciz "(malloc): failed to create memory bin\n"
    .EQU malloc.new_bin_err_len, . - malloc.new_bin_err
malloc.fail_msg: .asciz "(malloc): error\n"
    .EQU malloc.fail_msg_len, . - malloc.fail_msg

    .IFNDEF heap
    .ltorg
heap: .4byte 0
    .ENDIF

malloc.heap_addr: .4byte heap


    .ENDIF
/* _MALLOC_S_ */
