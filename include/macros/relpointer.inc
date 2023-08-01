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



; Purge all relpointer symbols.
; Required call if you want multiple relpointers in one file.
MACRO relpointer_destroy
    PURGE __RELPOINTER_DIFF
    PURGE __RELPOINTER_POSITION
    PURGE __RELPOINTER_REGISTER
ENDM
