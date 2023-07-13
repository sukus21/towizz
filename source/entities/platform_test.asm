INCLUDE "hardware.inc"
INCLUDE "entsys.inc"

SECTION "ENTITY PLATFORM TEST", ROMX

; Entity used exclusively for testing platform behaviour.
entity_platform_test::
    call input
    ldh a, [h_input]

    ;Modify tower with the B button
    bit PADB_B, a
    jr z, :+
        ld hl, w_tower_ypos
        ld de, w_tower_height
        jr .select
    :

    ;Modify background with the A button
    bit PADB_A, a
    jr z, :+
        ld hl, w_background_ypos
        ld de, w_background_xpos
        jr .select
    :

    ;Modify platform with no button
    ld hl, w_platform_ypos
    ld de, w_platform_xpos

    ;Single-step or per-frame?
    .select
    bit PADB_SELECT, a
    jr z, :+
        ldh a, [h_input_pressed]
    :
    ld b, a

    ;Move vertical
    bit PADB_UP, b
    jr z, :+
        dec [hl]
    :
    bit PADB_DOWN, b
    jr z, :+
        inc [hl]
    :

    ;Move horizontal
    ld h, d
    ld l, e
    bit PADB_LEFT, b
    jr z, :+
        dec [hl]
    :
    bit PADB_RIGHT, b
    jr z, :+
        inc [hl]
    :

    ;Keep tower within cap
    ld a, [w_tower_height]
    or a, a ;cp a, 0
    jr z, .tower_adjusted
    ld hl, w_tower_ypos
    ld c, a
    ld a, [hl]
    cp a, $FF
    jr nz, :+
        dec c
        ld [hl], c
        jr .tower_adjusted
    :
    cp a, c
    jr c, .tower_adjusted
        ld [hl], 0
    .tower_adjusted

    ;Adjust window position
    ld hl, w_background_ypos
    ld a, [hl]
    and a, %00001111
    ld [hl], a

    ;Return
    ret
;
