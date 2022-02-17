    .code 32
    .IFNDEF _HASHMAP_BUCKET_S_
    .EQU    _HASHMAP_BUCKET_S_, 0

    .INCLUDE "../malloc.s"
    .INCLUDE "../free.s"
    .INCLUDE "../string.s"

/*
struct bucket {
    int length;
    struct bucket_entry * first;
}

struct bucket_entry {
    char * key;
    struct bucket_entry * next;
    char * value;
}
*/


/* returns pointer to bucket in r0 on success */
/* returns -1 on failure */
/* creates a new empty bucket and returns a pointer to it */

    .align 16
bucket_new:
    push { lr }                 // save link register
    mov r0, #8                  // argument for malloc, number of bytes to allocate
    bl malloc

    cmn r0, #1                  // check for malloc fail (returns -1 on err)
    beq bucket_new.err

    eor r1, r1, r1
    str r1, [r0, #0]            // set length to zero
    str r1, [r0, #4]            // set first entry ptr to NULL

    pop { lr }                  // restore link register
    bx lr                       // return

bucket_new.err:
    mov r0, #-1                 // set r0 to -1 to indicate failure
    pop { lr }                  // restore link register
    bx lr                       // return


/* r0 contains ptr to bucket struct */
/* r1 contains ptr to key to add to bucket */
/* r2 contains ptr to value to add to bucket */
/* returns -1 on failure */
/* adds key value pair to bucket, overwrites existing value if key is already in bucket */

    .align 16
bucket_insert:
    push { r0, r1, r2, lr }           // save r0 and link register

    ldr r2, [r0]
    cmp r2, #0
    beq bucket_insert.new_entry

    /* search for entry with key (r1) in bucket (r0) */
    bl bucket_find

    cmn r0, #1
    beq bucket_insert.not_found

/* bucket_find returns ptr to entry if found */
    ldr r2, [sp, #8]             // load value
    ldr r1, [r0, #8]             // load old value
    cmp r1, r2
    beq bucket_insert.overwrite

    push { r0, r2 }
    mov r0, r1
    bl free                      // if old value and new value are different free the old value
    cmn r0, #1
    beq bucket_insert.free_err

    pop { r0, r2 }

bucket_insert.overwrite:
    str r2, [r0, #8]             // replace old value with new value

bucket_insert.free_err:
    add sp, sp, #12
    pop { lr }
    bx lr

bucket_insert.not_found:
    ldr r0, [sp]                        // load bucket ptr
    ldr r2, [r0]                        // load length of bucket
    eor r3, r3, r3                      // zero loop counter
1:
    ldr r0, [r0, #4]                    // load ptr to next bucket entry
    add r3, r3, #1
    cmp r3, r2                          // loop until counter equals length of bucket
    blt 1b

bucket_insert.new_entry:
    
    push { r0 }                         // save ptr to bucket entry

    mov r0, #12
    bl malloc

    cmn r0, #1                           // check for err
    beq bucket_insert.err                 // if error handle properly

    ldr r3, [sp]                         // load ptr to entry
    ldr r1, [sp, #8]                     // load key
    ldr r2, [sp, #12]                    // load value
    str r1, [r0]                         // store key
    str r2, [r0, #8]                     // store value
    eor r1, r1, r1
    str r1, [r0, #4]                     // set ptr to next entry to NULL
    str r0, [r3, #4]                     // store new entry in previous entry

    ldr r0, [sp, #4]                     // load ptr to bucket
    ldr r1, [r0]                         // load length of bucket
    add r1, r1, #1                       // increment length
    str r1, [r0]                         // store length

    add sp, sp, #16                      // restore link register
    pop { lr }
    bx lr                                // return

bucket_insert.err:
    mov r0, #-1
    add sp, sp, #16
    pop { lr }
    bx lr


/* ptr to bucket in r0 */
/* ptr to key to remove in r1 */
/* returns -1 on failure to remove (free err or not found) */
/* returns 1 on success */
/* removes bucket entry that contains key */

    .align 16
bucket_remove:
    push { r0, r1, lr }
    bl bucket_find

    cmn r0, #-1
    beq bucket_remove.err

    ldr r1, [r0, #4]              // load ptr to next entry
    str r1, [r8, #4]              // store ptr to next entry in previous entry

    bl free

    cmn r0, #-1
    beq bucket_remove.err

    pop { r0, r1, lr }
    bx lr

bucket_remove.err:
    add sp, sp, #8
    mov r0, #-1
    pop { lr }
    bx lr


/* ptr to bucket in r0 */
/* ptr to key to find in r1 */
/* returns -1 on not found */
/* returns ptr to entry on success */
/* finds bucket entry in bucket and returns a pointer to it */

    .align 16
bucket_find:
    push { lr }               // save link reg
    mov r8, r0
    ldr r7, [r0, #4]

    cmp r7, #0
    beq bucket_find.end

    mov r6, r1
1:
    ldr r0, [r7]
    mov r1, r6
    bl strcmp
    
    cmp r0, #0
    bge bucket_find.found

    mov r8, r7
    ldr r7, [r7, #4]
    cmp r7, #0
    bne 1b

    
bucket_find.end:
    mov r0, #-1               // might be unecessary
    pop { lr }
    bx lr

bucket_find.found:
    mov r0, r7
    pop { lr }
    bx lr


/* ptr to bucket in r0 */
/* returns -1 on failure */
/* returns 1 on success */
/* frees all memory owned by bucket */

    .align 16
bucket_dealloc:
    push { lr }

    ldr r1, [r0]             // load length of bucket
    ldr r2, [r0, #4]         // load ptr to first entry
    push { r0, r1, r2 }      // no need to save r0, pushing to create space for loop counter

    bl free
    cmn r0, #1
    beq bucket_dealloc.err

    ldr r0, [sp, #8]
    cmp r0, #0
    beq bucket_dealloc.end

    eor r0, r0, r0           // loop counter
    str r0, [sp]
1:

    ldr r0, [sp, #8]
    ldr r0, [r0]

    bl free
    cmn r0, #1
    beq bucket_dealloc.err

    ldr r0, [sp, #8]
    ldr r0, [r0, #8]

    bl free
    cmn r0, #1
    beq bucket_dealloc.err

    ldr r0, [sp, #8]
    ldr r1, [r0, #4]
    str r1, [sp, #8]

    bl free
    cmn r0, #1
    beq bucket_dealloc.err

    ldr r0, [sp]
    ldr r1, [sp, #4]
    add r0, r0, #1
    str r0, [sp]

    cmp r0, r1
    blt 1b

bucket_dealloc.end:
    add sp, sp, #12
    pop { lr }
    bx lr

bucket_dealloc.err:
    add sp, sp, #12
    mov r0, #-1
    pop { lr }
    bx lr

    
    .ENDIF
