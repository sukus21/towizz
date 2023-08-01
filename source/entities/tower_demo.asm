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



; Creates a tower demo entity.
entity_towerdemo_create::
    call entsys_new16
    ld h, b
    ld l, c

    ;Set bank and step pointer
    ld a, bank(@)
    ld [hl+], a
    inc l
    ld a, low(entity_towerdemo)
    ld [hl+], a
    ld [hl], high(entity_towerdemo)

    ;Return
    ret 
;



; Entity used exclusively for testing platform behaviour.
;
; Input:
; - `de`: Entity pointer
entity_towerdemo::
    ld a, e
    or a, ENTVAR_TOWERDEMO_RUNNING
    ld l, a
    ld h, d

    ;Toggle action
    ldh a, [h_input_pressed]
    ld b, a
    bit PADB_START, b
    jr z, :+
        ld a, 1
        sub a, [hl]
        ld [hl], a
    :

    ;Do anything?
    ld a, [hl+]
    bit PADB_SELECT, b
    jr nz, :+
    cp a, 0
    ret z
    :

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
