INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/smoke.inc"

SECTION "ENTITY SMOKE", ROMX

; Creates a new smoke particle.
;
; Input:
; - `b`: X-position
; - `c`: Y-position
;
; Returns:
; - `hl`: Entity pointer
entity_smoke_create::
    push bc
    entsys_new 16, entity_smoke_step, 0

    ;Set timer and speed
    relpointer_move ENTVAR_SMOKE_TIMER
    ld [hl], 0
    relpointer_move ENTVAR_SMOKE_SPEED
    call rng_run_single
    and a, 1
    jr nz, :+
        ld a, $FF
    :
    ld [hl], a

    ;Set position
    pop bc
    relpointer_move ENTVAR_SMOKE_XPOS
    ld [hl], b
    relpointer_move ENTVAR_SMOKE_YPOS
    ld [hl], c

    ;Set attribute
    relpointer_move ENTVAR_SMOKE_ATTR
    call rng_run_single
    and a, OAMF_XFLIP
    ld [hl], a

    ;Return
    relpointer_destroy
    ret
;



; Update + draw function for smoke entity.
;
; Input:
; - `de`: Entity pointer
entity_smoke_step:
    ld h, d
    ld l, e
    relpointer_init l

    ;Tick timer
    relpointer_move ENTVAR_SMOKE_TIMER
    inc [hl]
    ld a, [hl]
    cp a, SMOKE_TIMER_DESTROY
    jr c, :+
        ld l, e
        jp entsys_free
    :

    ;Update X/Y-position -> D/E
    relpointer_move ENTVAR_SMOKE_YPOS
    inc [hl]
    ld e, [hl]
    relpointer_move ENTVAR_SMOKE_SPEED
    ld d, [hl]
    relpointer_move ENTVAR_SMOKE_XPOS
    bit 0, e
    jr z, :+
        ld a, d
        add a, [hl]
        ld [hl], a
    :
    ld d, [hl]

    ;Grab attributes -> C
    relpointer_move ENTVAR_SMOKE_ATTR
    ld c, [hl]

    ;Draw
    relpointer_destroy
    ld b, 4
    ldh a, [h_oam_active]
    ld h, a
    call sprite_get
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld a, SMOKE_SPRITE
    ld [hl+], a
    ld [hl], c

    ;Return
    ret
;
