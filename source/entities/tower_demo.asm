INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "struct/entity/towerdemo.inc"

SECTION "TOWER DEMO", ROMX, ALIGN[8]

; Some of that FRESH sine curve.
towerdemo_sinewave:
    DEF SINE = 0
    REPT $100
        DEF SINE += DIV(1.0, 256.0)
        db MUL(40.0, SIN(SINE)) >> 16
    ENDR
;



; Entity used exclusively for testing platform behaviour.
;
; Input:
; - `de`: Entity pointer
entity_towerdemo::
    ld a, e
    or a, ENTVAR_TOWERDEMO_PLATFORM_X
    ld l, a
    ld h, d

    ;Prepare sine pointer
    ld b, high(towerdemo_sinewave)

    ;Platform X-position
    ld a, [hl]
    add a, 5
    ld [hl+], a
    ld c, a
    ld a, [bc]
    sra a
    add a, 9*8
    ld [w_platform_xpos], a

    ;Platform Y-position
    ld a, [hl]
    add a, 2
    ld [hl+], a
    ld c, a
    ld a, [bc]
    add a, $60
    ld [w_platform_ypos], a

    ;Background X-position
    inc [hl]
    ld a, [hl+]
    ld c, a
    ld a, [bc]
    sra a
    sra a
    add a, 9*8
    ld [w_background_xpos], a

    ;Background Y-position
    ld a, [hl]
    add a, 2
    ld [hl+], a
    ld c, a
    ld a, [bc]
    sra a
    sra a
    sra a
    sra a
    ld c, a
    ld a, [w_background_ypos]
    add a, c
    and a, %00001111
    ld [w_background_ypos], a

    ;Tower height
    ld a, [hl]
    add a, 4
    ld [hl+], a
    ld c, a
    ld a, [bc]
    sra a
    sra a
    sra a
    add a, 16
    ld [w_tower_height], a
    ld d, a

    ;Tower Y-position
    inc [hl]
    ld a, [hl]
    cp a, d
    jr c, :+
        xor a
    :
    ld [hl+], a
    ld [w_tower_ypos], a

    ;Return
    ret 
;
