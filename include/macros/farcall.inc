; Switches banks, and jumps to the given symbol.
; `a` and `hl` will be clobbered before the jump,
; and can therefore not be used as function arguments.
; Does not switch banks back when returning.
;
; Input:
; - `1`: Symbol to call
;
; Destroys: `a`, `hl`, unknown
MACRO farcall_0
    ld a, bank(\1)
    ld [rROMB0], a
    ld hl, \1
    call _hl_
ENDM
