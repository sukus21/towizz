INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "tower.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/tower.inc"

SECTION "ENTITY PLATFORM TEST", ROMX

; Entity used exclusively for testing platform behaviour.,
;
; Input:
; - `de`: Entity pointer
;
; Destroys: all
entity_platform_test::
    call input
    ldh a, [h_input_pressed]

    ;Modify tower with the B button
    ldh a, [h_input]
    bit PADB_B, a
    jr z, :+
        ld hl, w_tower_ypos+1
        ld de, w_tower_height
        jr .select
    :

    ;Modify background with the A button
    bit PADB_A, a
    jr z, :+
        ld hl, w_background_ypos+1
        ld de, w_camera_xpos+1
        jr .select
    :

    ;Modify platform with no button
    ld hl, w_platform_ypos+1
    ld de, w_platform_xpos+1

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
    push bc
    call tower_truncate
    pop bc

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
    call tower_truncate

    ;Return
    ret
;
