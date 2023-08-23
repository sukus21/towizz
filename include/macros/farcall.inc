; Switches banks, and jumps to the given symbol.
; `a` will be clobbered before the jump,
; and can therefore not be used as function arguments.
; Does not switch banks back when returning.
;
; Input:
; - `1`: Symbol to call (label)
;
; Destroys: `a`, unknown
MACRO farcall
    ASSERT bank(@) == 0, "farcall - can only do non-returning farcall from ROM0"
    ld a, bank(\1)
    ld [rROMB0], a
    call \1
ENDM
