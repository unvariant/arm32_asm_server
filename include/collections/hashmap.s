    .IFNDEF _HASHMAP_S_
    .EQU    _HASHMAP_S_, 0

    .INCLUDE "./include/malloc.s"
    .INCLUDE "./include/free.s"
    .INCLUDE "./include/collections/hashmap_bucket.s"

/*
struct hashmap {
    int length;               // number of entries
    string_llist * entries;   // ptr to array of linked list entries
}
*/


/* ptr to string to hash in r0 */
/* returns -1 on failure */

    .align 16
hash_string:
    eor r1, r1, r1       // set r1 to zero
    mov r2, #1           // set r2 to 1
    mov r3, #61          // multiplier (prime)
hash_string.loop:
    ldrb r4, [r0], #1    // load byte
    mul r4, r2, r4       // multiply r4 by r2
    add r1, r1, r4       // add r4 to r1
    mul r2, r3, r2       // multiply r2 by r3
    cmp r4, #0          
    bne hash_string.loop // stop at NULL terminator
    
    mov r0, r1
    bx lr


/* number of hashmap entries in r0 */
/* returns -1 on failure */

    .align 16
hashmap_new:
    push { r0, lr }           // save # of entries and link register
    sub sp, sp, #4

    cmp r0, #0
    beq hashmap_new.err

    mov r0, #8                // alloc 8 bytes of space
    bl malloc

    cmn r0, #1                // check for malloc err
    beq hashmap_new.err

    ldr r1, [sp, #4]          // load # of entries
    str r1, [r0]              // set # of entries in hashmap

    str r0, [sp]              // save ptr to hashmap
    lsl r0, r1, #2            // r1 = r0 * 4
    bl malloc                 // alloc array for entries

    cmn r0, #1                // check for malloc err
    beq hashmap_new.err

    ldr r1, [sp]
    str r0, [r1, #4]
    ldr r3, [sp, #4]
    str r3, [r1]

    eor r1, r1, r1            // zero r1
    eor r2, r2, r2            // zero r2
1:
    str r1, [r0, r2, LSL #2]  // zero 4bytes at r0 + r2 * 4
    add r2, r2, #1            // increment r2 by one
    cmp r2, r3                // loop until r2 equals # of entries
    blt 1b

    ldr r0, [sp]
    add sp, sp, #8            // restore stack
    pop { lr }                // restore link register
    bx lr                     // return 

hashmap_new.err:
    add sp, sp, #8
    mov r0, #-1
    pop { lr }
    bx lr


/* ptr to hashmap in r0 */
/* ptr to key in r1 */
/* returns addr of array element that contains bucket ptr, bucket ptr *might* contain the key */
/* returns -1 on failure */
/* not meant to be called by user, only by other hashmap functions */

    .align 16
__hashmap_bucket_addr:
    push { r0, r1, lr }

    mov r0, r1
    bl hash_string

    ldr r1, [sp]
    ldr r2, [r1]

    udiv r3, r0, r2               // --- | calculates r0
    mul r3, r2, r3                //     | modulo r2
    sub r0, r0, r3                // --- | and stores result in r0

    ldr r1, [r1, #4]
    add r0, r1, r0, LSL #2        // calculate addr of array element

    add sp, sp, #8
    pop { lr }
    bx lr


/* ptr to hashmap in r0 */
/* ptr to key in r1 */
/* ptr to value in r2 */
/* NOTE: hashmap entries are pointers to linked lists */

    .align 16
hashmap_insert:
    push { r0, r1, r2, lr }           // save parameters on stack

    bl __hashmap_bucket_addr

    ldr r1, [r0]                 // load ptr to bucket
    cmp r1, #0                   // check if ptr is NULL
    bne hashmap_insert.insert

    push { r0 }                  // save ptr to entry
    bl bucket_new                // create new bucket
    
    cmn r0, #1                   // check for err
    beq hashmap_insert.err

    ldr r1, [sp]                 // load ptr to array
    str r0, [r1]                 // store bucket in array
    mov r0, r1

/* ptr to entry in r0 */
hashmap_insert.insert:
    ldr r0, [r0]                 // load ptr to entry
    ldr r1, [sp, #8]             // load key in r1
    ldr r2, [sp, #12]
    bl bucket_insert             // insert into bucket

    cmn r0, #1                   // check for err
    beq hashmap_insert.err

    add sp, sp, #4               // clean up stack
    pop { r0, r1, r2, lr }       // restore link register
    bx lr                        // return

hashmap_insert.err:
    add sp, sp, #16
    mov r0, #-1
    pop { lr }
    bx lr


/* ptr to hashmap in r0 */
/* ptr to key in r1 */
/* returns -1 on failure */
/* return ptr to value on success */

    .align 16
hashmap_get:
    push { r0, r1, lr }

    bl __hashmap_bucket_addr

    ldr r0, [r0]
    cmp r0, #0
    beq hashmap_get.err

    ldr r1, [sp, #4]
    bl bucket_find

    cmn r0, #1
    beq hashmap_get.err

    ldr r0, [r0, #8]

    add sp, sp, #8
    pop { lr }
    bx lr

hashmap_get.err:
    add sp, sp, #8
    mov r0, #-1
    pop { lr }
    bx lr
    


/* ptr to hashmap in r0 */
/* ptr to key in r1 */
/* returns -1 on failure */
/* returns positive integer on success */

    .align 16
hashmap_remove:
    push { r0, r1, lr }

    bl __hashmap_bucket_addr

    ldr r0, [r0]
    cmp r0, #0
    beq hashmap_remove.err

    ldr r1, [sp, #4]
    bl bucket_remove

    cmn r0, #1
    beq hashmap_remove.err

    pop { r0, r1, lr }
    bx lr

hashmap_remove.err:
    add sp, sp, #8
    mov r0, #-1
    pop { lr }
    bx lr


/* ptr to hashmap in r0 */
/* returns -1 on failure to dealloc */
/* returns positive integer on success */

    .align 16
hashmap_dealloc:
    push { r0, r1, lr }
    sub sp, sp, #8

    ldr r1, [r0]
    str r1, [sp, #12]
    ldr r0, [r0, #4]
    eor r1, r1, r1
    str r0, [sp]
    str r1, [sp, #4]
hashmap_dealloc.free_buckets:
    ldr r0, [r0, r1, LSL #2]
    cmp r0, #0
    beq 1f

    bl bucket_dealloc
    cmn r0, #1
    beq hashmap_dealloc.err

1:
    ldr r0, [sp]
    ldr r1, [sp, #4]
    ldr r2, [sp, #12]
    add r1, r1, #1
    str r1, [sp, #4]
    cmp r1, r2
    blt hashmap_dealloc.free_buckets

hashmap_dealloc.free_struct:
    ldr r0, [sp]

    bl free
    cmn r0, #1
    beq hashmap_dealloc.err

    ldr r0, [sp, #8]

    bl free
    cmn r0, #1
    beq hashmap_dealloc.err

    add sp, sp, #16
    mov r0, #1
    pop { lr }
    bx lr

hashmap_dealloc.err:
    add sp, sp, #16
    mov r0, #-1
    pop { lr }
    bx lr

    
    .ENDIF
