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

; Says a lot about a given entity.
DEF ENTVAR_FLAGS RB 1

; This is where the entity variable space starts.
; Entities using this value cannot be collided with.
DEF ENTVAR_VAR RB 0

; Entity Y-position.
; Little endian.
DEF ENTVAR_YPOS RB 2

; Entity X-position.
; Little endian.
DEF ENTVAR_XPOS RB 2

; Entity height in pixels.
DEF ENTVAR_HEIGHT RB 1

; Entity width in pixels.
DEF ENTVAR_WIDTH RB 1

; This is where variable space begins for collision-enabled objects.
DEF ENTVAR_COL_VAR RB 0

; Callback address when dealing damage.
; This field is assumed to exist, when `ENTSYS_FLAGB_DMGCALL` is set.
DEF ENTVAR_DMGCALL RB 2

; This is where variable space begins for an entity with a damage callback.
DEF ENTVAR_DMGCALL_VAR RB 0


RSRESET

; This entity has collision enabled.
; If this flag is NOT set, `ENTVAR_COL_*` offsets to not apply.
DEF ENTSYS_FLAGF_COLLISION EQU 1 << _RS
DEF ENTSYS_FLAGB_COLLISION RB 1

; This is a player entity.
DEF ENTSYS_FLAGF_PLAYER EQU 1 << _RS
DEF ENTSYS_FLAGB_PLAYER RB 1

; This entity hurts the player.
DEF ENTSYS_FLAGF_HURT EQU 1 << _RS
DEF ENTSYS_FLAGB_HURT RB 1

; This entity damages enemies.
DEF ENTSYS_FLAGF_DAMAGE EQU 1 << _RS
DEF ENTSYS_FLAGB_DAMAGE RB 1

; This entity has a callback when DEALING damage.
DEF ENTSYS_FLAGF_DMGCALL EQU 1 << _RS
DEF ENTSYS_FLAGB_DMGCALL RB 1

    ENDC
