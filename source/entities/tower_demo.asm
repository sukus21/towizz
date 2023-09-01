INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "struct/entity/towerdemo.inc"

SECTION "TOWER DEMO", ROMX, ALIGN[8]

; Some of that FRESH sine curve.
towerdemo_sinewave:
    DEF SINE = $4000
    REPT $100
        db (MUL($7F_0000, SIN(SINE)) + $8000) >> 16
        DEF SINE += $100
    ENDR
;



; Creates a tower demo entity.
;
; Returns:
; - `hl`: Towerdemo entity
entity_towerdemo_create::

    ;Get new entity
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
    ld l, c
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
    jp z, towerdemo_nospeed
    :

    ;Prepare sine pointer
    ld b, high(towerdemo_sinewave)

    ;Platform X-position
    ld a, [hl]
    add a, 5
    ld [hl+], a
    ld c, a
    ld a, [bc]
    or a, a ;reset carry flag
    ld d, 0
    bit 7, a
    jr z, :+
        dec d
    :
    rla
    rl d
    sla a
    rl d
    ld e, a
    ld [w_platform_xspeed], a
    ld a, d
    ld [w_platform_xspeed+1], a

    ;Platform Y-position
    ld a, [hl]
    add a, 2
    ld [hl+], a
    ld c, a
    ld a, [bc]
    rlca
    rlca
    ld e, a
    and a, %00000011
    bit 1, a
    jr z, :+
        or a, %11111100
    :
    ld d, a
    ld a, e
    and a, %11111100
    ld [w_platform_yspeed], a
    ld a, d
    ld [w_platform_yspeed+1], a

    ;ld [w_platform_ypos], a

    ;Background X-position
    inc [hl]
    ld a, [hl+]
    ld c, a
    ld a, [bc]
    sra a
    sra a
    sra a
    sra a
    add a, 9*8
    ld [w_camera_xpos+1], a

    ;Tower height
    ld a, [hl]
    add a, 4
    ld [hl+], a
    ld c, a
    ld a, [bc]
    ld c, a
    swap a
    and a, %00001111
    bit 7, c
    jr z, :+
        or a, %11110000
    :
    add a, 18
    ld [w_tower_height], a
    ld d, a
    call tower_truncate

    ;Tower Y-position
    ld a, 1
    ld [w_tower_yspeed+1], a
    call tower_truncate

    ;Return
    ret 
;



; Reset all tower related speeds.
towerdemo_nospeed:
    xor a

    ld hl, w_tower_yspeed
    ld [hl+], a
    ld [hl-], a

    ld hl, w_platform_yspeed
    ld [hl+], a
    ld [hl-], a

    ld hl, w_platform_xspeed
    ld [hl+], a
    ld [hl-], a

    ld hl, w_background_yspeed
    ld [hl+], a
    ld [hl-], a

    ld hl, w_camera_xspeed
    ld [hl+], a
    ld [hl-], a

    ;Return
    ret
;
