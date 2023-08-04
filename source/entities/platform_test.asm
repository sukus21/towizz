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
    bit PADB_START, a
    jr z, :+

        ;Transfer tower tiles
        vqueue_add_copy VQUEUE_TYPE_DIRECT, VT_TOWER_TOWER, tower_asset_bricks
        
        ;Set writeback pointer
        ld a, e
        add a, low(ENTVAR_VAR)
        ld e, a
        ld [hl+], a
        ld [hl], d

        ;Transfer platform tiles
        vqueue_add_copy VQUEUE_TYPE_DIRECT, VT_TOWER_PLATFORM, tower_asset_platform_grassy

        ;Set writeback pointer
        ld a, e
        ld [hl+], a
        ld [hl], d

        ;Set writeback to 0
        xor a
        ld [de], a
    :

    ;Modify tower with the B button
    ldh a, [h_input]
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
        ld de, w_camera_xpos
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
    ld a, [w_tower_flags]
    bit TOWERMODEB_TOWER_REPEAT, a
    jr z, .tower_adjusted
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
