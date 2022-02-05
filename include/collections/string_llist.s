    .code 32
    .IFNDEF _STRING_LLIST_S_
    .EQU    _STRING_LLIST_S_, 0

    .INCLUDE "/home/pi/project/malloc.s"

/*
struct string_llist {
    int length;
    struct string_llist_entry * first;
}

struct string_llist_entry {
    char * value;
    struct string_llist_entry * next;
}
*/


/* returns pointer to string_llist in r0 on success */
/* returns -1 on failure */
string_llist_new:
    push { lr }                 // save link register
    mov r0, #8                  // argument for malloc, number of bytes to allocate
    bl malloc

    cmn r0, #1                  // check for malloc fail (returns -1 on error)
    beq string_llist_new.error

    eor r1, r1, r1
    str r1, [r0, #0]           // set length to zero
    str r1, [r0, #4]           // set first entry ptr to NULL

    pop { lr }                  // restore link register
    bx lr                       // return

string_llist_new.error:
    mov r0, #-1                 // set r0 to -1 to indicate failure
    pop { lr }                  // restore link register
    bx lr                       // return


/* r0 contains ptr to linked list struct */
/* r1 contains ptr to string to add to linked list */
/* r2 contains idx to add new entry */
/* assumes index is positive and less than length of linked list */

string_llist_insert_at_unchecked:
    push { r0, r1, lr }         // save all parameters on the stack
    
    cmp r2, #0
    beq string_llist_insert_at_unchecked.insert

    eor r3, r3, r3
string_llist_insert_at_unchecked.loop:
    ldr r0, [r0, #4]                           // get pointer to next entry
    
    add r3, r3, #1                              // increment loop counter
    cmp r3, r2
    blt string_llist_insert_at_unchecked.loop   // loop until at specified idx

/* r0 contains pointer to linked list entry */
string_llist_insert_at_unchecked.insert:
    push { r0 }                                 // save pointer to entry
    mov r0, #8                                  // argument for malloc, sizeof linked list entry
    bl malloc                                   // allocate 8 bytes

    cmn r0, #1                                  // check for malloc error
    beq string_llist_insert_at_unchecked.error

    pop { r1 }                                  // restore entry ptr
    ldr r2, [r1, #4]                            // load ptr to next entry
    cmp r2, #0                                  // if equal to NULL skip next instruction
    beq 1f

    str r2, [r0, #4]                            // store next entry ptr in new entry

1:
    str r0, [r1, #4]                            // store new entry ptr in entry
    ldr r1, [sp, #4]                            // load value to insert
    str r1, [r0, #0]                            // store value in new entry
    
    pop { r0, r1, lr }                          // restore the stack
    ldr r1, [r0, #0]                            // load length of linked list
    add r1, r1, #1                              // increment by one
    str r1, [r0, #0]                            // store length back into linked list
    bx lr                                       // return

string_llist_insert_at_unchecked.error:
    mov r0, #-1
    add sp, sp, #8
    pop { lr }
    bx lr


/* r0 contains ptr to linked list struct */
/* r1 contains ptr to string to add to linked list */

string_llist_push:
    push { r0, lr }           // save r0 and link register
    ldr r2, [r0, #0]          // load length of linked list

    bl string_llist_insert_at_unchecked  // insert into linked list

    cmn r0, #1                           // check for error
    beq string_llist_push.error          // if error handle properly

    pop { r0, lr }                       // else restore r0 and link register
    bx lr                                // return

string_llist_push.error:
    mov r0, #-1
    add sp, sp, #4
    pop { lr }
    bx lr
    

/* r0 contains ptr to linked list struct */
/* r1 contains idx of linked list to retrieve */
/* return ptr to string */

string_llist_get_at_unchecked:
    ldr r0, [r0, #4]                       // load first entry
    cmp r1, #0                             // if index zero dont loop
    beq string_llist_get_at_unchecked.get

    eor r2, r2, r2                         // zero loop counter
string_llist_get_at_unchecked.loop:
    ldr r0, [r0, #4]                       // load next entry

    add r2, r2, #1                         // increment loop counter
    cmp r2, r1                             // loop until equal to specified idx in r1
    blt string_llist_get_at_unchecked.loop

/* r0 contains ptr to linked list entry */
string_llist_get_at_unchecked.get:
    ldr r0, [r0, #0]                       // load string in current entry
    bx lr                                  // return


/* r0 contains ptr to linked list struct */
/* r1 contains idx to retrieve */
/* returns ptr to string on success */
/* return -1 on failure (index out of bounds, invalid index) */
string_llist_get:
    push { lr }                        // save link register
    cmp r1, #0                         // return -1 on index less than zero
    blt string_llist_get.error

    ldr r2, [r0, #0]                   // load length of linked list
    cmp r1, r2                         // return -1 on index greater than or equal to length
    bge string_llist_get.error

    bl string_llist_get_at_unchecked   // get string at specified index (now guaranteed to be safe)

    pop { lr }                         // restore link register
    bx lr                              // return

string_llist_get.error:
    pop { lr }
    mov r0, #-1
    bx lr

    .ENDIF
