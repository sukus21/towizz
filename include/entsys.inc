;Include guard
IF !DEF(ENTSYS_INC)
DEF ENTSYS_INC EQU 1

; Number of entity chunks available
; Assumed to be a multiple of 16.
DEF ENTSYS_CHUNK_COUNT EQU 64


RSRESET

; ROM bank an entity's data is located in.
; Cannot be ROM0, as a value of `0` means an entity is free.
DEF ENTVAR_BANK RB 1

; How many bytes to next entity.
; This value is both a relative pointer to the next entity, and the size of the current entity.  
; Should always be either `$40`, `$20` or `$10`.
DEF ENTVAR_NEXT RB 1

; Pointer to the entity's step function (function that gets run every game frame).
; This should be located in the same ROM bank as specified `ENTVAR_BANK`.
DEF ENTVAR_STEP RB 2

; This is where the entity variable space starts.
DEF ENTVAR_VAR RB 0

ENDC
