    IF !DEF(RELPOINTER_INC)
    DEF RELPOINTER_INC EQU 1

; Initializes a relative pointer.
; The relative pointer is a single 8-bit register, and cannot cross pages.
; Assumes the input register is already set to the starting value.
;
; Input:
; - `1`: 8-bit register
; - `2`: Pointer starting position
;
; Output:
; - register `1`: Value of `2`
MACRO relpointer_init
    DEF __RELPOINTER_REGISTER EQUS "\1"
    DEF __RELPOINTER_POSITION = \2
    DEF __RELPOINTER_DIFF = 0
    DEF __RELPOINTER_STACK = 0
ENDM



; Move the relative pointer.
;
; Input:
; - `1`: Where to move the relative pointer
;
; Output:
; - `RELPOINTER_REGISTER`: Value of `1`
;
; Destroys: `af`
MACRO relpointer_move
    DEF __RELPOINTER_DIFF = \1 - __RELPOINTER_POSITION
    DEF __RELPOINTER_POSITION = \1

    IF __RELPOINTER_DIFF > 0 && __RELPOINTER_DIFF < 5
        REPT __RELPOINTER_DIFF
            inc __RELPOINTER_REGISTER
        ENDR
    ELIF __RELPOINTER_DIFF < 0 && __RELPOINTER_DIFF > -5
        REPT -__RELPOINTER_DIFF
            dec __RELPOINTER_REGISTER
        ENDR
    ELIF __RELPOINTER_DIFF != 0
        ld a, __RELPOINTER_REGISTER
        add a, low(__RELPOINTER_DIFF)
        ld __RELPOINTER_REGISTER, a
    ENDC
ENDM



; Move the relative pointer.
; Also saves the state of the relative pointer.
; The state can be restored with `relpointer_pop`.
;
; Input:
; - `1`: Where to move the relative pointer
;
; Output:
; - `RELPOINTER_REGISTER`: Value of `1`
;
; Destroys: `af`
MACRO relpointer_push
    DEF __RELPOINTER_STACK_{d:__RELPOINTER_STACK} = __RELPOINTER_POSITION
    DEF __RELPOINTER_STACK += 1
    push hl
    relpointer_move \1
ENDM



; Pops a value from the relative pointer stack.
; Assumes `relpointer_push` has been called.
;
; Output:
; - `RELPOINTER_REGISTER`: Value stored on stack
MACRO relpointer_pop
    ASSERT __RELPOINTER_STACK != 0, "Cannot pop from an empty relpointer stack"
    DEF __RELPOINTER_STACK -= 1
    DEF __RELPOINTER_POSITION = __RELPOINTER_STACK_{d:__RELPOINTER_STACK}
    pop hl
ENDM



; Does not move the actual pointer.
; Just updates the interla relpointer logic.
;
; Input:
; - `1`: Where to move the relative pointer
MACRO relpointer_set
    DEF __RELPOINTER_POSITION = \1
ENDM



; Purge all relpointer symbols.
; Required call if you want multiple relpointers in one file.
MACRO relpointer_destroy
    PURGE __RELPOINTER_DIFF
    PURGE __RELPOINTER_POSITION
    PURGE __RELPOINTER_REGISTER
    PURGE __RELPOINTER_STACK
ENDM

    ENDC
