INCLUDE "hardware.inc"
INCLUDE "macros/memcpy.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/tower.inc"

SECTION "PAINTER", ROM0

; Resets painter position.  
; Does NOT clear the paint buffer.  
; Lives in ROM0.
;
; Saves: `f`, `bc`, `de`, `hl`
painter_reset::
    push hl
    ld hl, w_painter_position
    ld a, low(w_paint)
    ld [hl+], a
    ld [hl], high(w_paint)
    pop hl
    ret
;



; Pastes raw tile data into paint buffer.  
; Assumes the correct bank is switched in already.  
; Lives in ROM0.
;
; Input:
; - `bc`: Tile data
; - `de`: Length in bytes
;
; Saves: `de`, `hl`
painter_fill::
    ld a, d
    or a, e
    ret z
    push de
    push hl

    ;Do some copyin'
    ld hl, w_painter_position
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call memcpy

    ;Save pointer
    ld a, l
    ld [w_painter_position], a
    ld a, h
    ld [w_painter_position+1], a

    ;Return
    pop hl
    pop de
    ret
;



; Paints on top of existing canvas.
; Pixels of color 0 saves original background.  
; Assumes the correct bank is switched in already.  
; Lives in ROM0.
;
; Input:
; - `bc`: Tile data
; - `de`: Length in bytes
;
; Saves: `de`, `hl`
painter_paint::
    res 0, e
    ld a, d
    or a, e
    ret z
    push de
    push hl

    ;Get current pointer position
    ld hl, w_painter_position
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    .loop
        ;Decrement counter and save it
        dec de
        dec e
        push de

        ;Read source -> DE
        ld a, [bc]
        inc bc
        ld d, a
        ld a, [bc]
        ld e, a
        inc bc
        push bc

        ;Create counter -> C
        ld c, 8
        .loop_inner
            bit 0, d
            jr nz, .place
            bit 0, e
            jr z, .skip
            .place
                res 0, [hl]
                bit 0, d
                jr z, :+
                    set 0, [hl]
                :
                inc l
                res 0, [hl]
                bit 0, e
                jr z, :+
                    set 0, [hl]
                :
                dec l
            .skip
            rlc d
            rlc e
            rlc [hl]
            inc l
            rlc [hl]
            dec l
            dec c
            jr nz, .loop_inner
        ;

        ;One iteration over
        inc hl
        inc l
        pop bc
        pop de
        ld a, d
        or a, e
        jr nz, .loop
    ;

    ;Save pointer
    ld a, l
    ld [w_painter_position], a
    ld a, h
    ld [w_painter_position+1], a

    ;Return
    pop hl
    pop de
    ret
;



; Paint equipment and weapon tiles, and queue them for transfer.  
; Switches banks.  
; Lives in ROM0.
;
; Destroys: all
painter_item_slots::

    ;Get template bank
    ld a, bank(tower_asset_hud)
    ld [rROMB0], a

    ;Fill templates
    call painter_reset
    ld bc, tower_asset_hud + $40
    ld de, $40
    call painter_fill
    ld de, $40
    call painter_fill

    ;Get item bank
    call painter_reset
    ld a, bank(item_sprites)
    ld [rROMB0], a

    ;Paint equipment sprite
    ld a, [w_player_equipment]
    call item_get_sprite
    ld b, d
    ld c, e
    ld de, $40
    call painter_paint

    ;Paint weapon sprite
    ld a, [w_player_weapon]
    call item_get_sprite
    ld b, d
    ld c, e
    ld de, $40
    call painter_paint

    ;Add VQUEUE transfer
    vqueue_add VQUEUE_TYPE_DIRECT, 8, VT_TOWER_HUD+$40, w_paint

    ;Return
    ret
;
