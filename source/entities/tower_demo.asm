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
    ;Sine curve checksum
    ld hl, towerdemo_sinewave
    xor a
    ld b, a
    ld c, a
    :
        ld a, c
        add a, [hl]
        ld c, a
        ld a, l
        add a, 4
        ld l, a
        jr nc, :-
    nop

    ;Another type of curve checksum
    ld hl, towerdemo_sinewave
    ld bc, w_buffer
    .loop
        ld a, [hl]
        set 7, l
        add a, [hl]
        inc l
        res 7, l
        ld c, l
        ld [bc], a
        jr nz, .loop
    nop

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

    ;Background Y-position
    ld a, [hl]
    add a, 2
    ld [hl+], a
    ld c, a
    ld a, [bc]
    ld d, a
    xor a
    bit 7, d
    jr z, :+
        dec a
    :
    sla d
    rla
    sla d
    rla
    dec a
    ld e, a
    ld bc, w_background_ypos
    ld a, [bc]
    add a, d
    ld [bc], a
    inc bc
    ld a, [bc]
    adc a, e
    ld [bc], a
    ld b, high(towerdemo_sinewave)

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

    ;Apply speed changes
    call tower_update

    ;Return
    ret 
;
