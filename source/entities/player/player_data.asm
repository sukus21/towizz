INCLUDE "struct/item.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/player.inc"
INCLUDE "struct/vram/tower.inc"

SECTION FRAGMENT "PLAYER", ROMX

; This macro `INCBIN`'s the given file, and adds a `.end` label.  
; Automatically prepends player graphics folder location.
;
; Input:
; - `1`: Name of file (string)
MACRO incspr
    INCBIN STRCAT("graphics/player/", \1)
    .end
ENDM

player_sprite_base:         incspr "player_base.tls"
player_sprite_jump:         incspr "player_equip_jump.tls"
player_sprite_firebreath:   incspr "player_weapon_firebreath.tls"
player_sprite_jetpack:      incspr "player_equip_jetpack.tls"
player_bckspr_jetpack:      incspr "jetpack.tls"



; Adds a sprite table entry for the given label.
; Expands to 4 bytes of data.
;
; Input:
; - `1`: Sprite data (label)
; - `2`: Can be modified (bitmask)
MACRO sprtable
    IF _NARG == 0
        db $FF, $FF, $FF, $FF
    ELSE
        dw \1
        db (\1.end - \1) >> 4
        db \2
    ENDC
ENDM

; Address table for player sprites.
player_spritetable:
    sprtable player_sprite_jump,        %00000001
    sprtable player_sprite_firebreath,  %00000011
    sprtable
    sprtable player_sprite_jetpack,     %00000000
;



; Loads the sprites needed for the player entity.
; These sprites include base-, equipment- and weapon sprites.  
; Assumes player equipment- and weapon IDs are set correctly.  
; Uses painter.
entity_player_load::

    ;Some serious painter shenanigans are about to go down.
    call painter_reset
    
    ;Push weapon table entry
    ld a, [w_player_weapon]
    ld e, a
    add a, a
    add a, a
    add a, low(player_spritetable)
    ld l, a
    ld a, high(player_spritetable)
    adc a, 0
    ld h, a
    push hl
    ld a, l
    add a, 3
    ld l, a
    jr nc, :+
        inc h
    :
    ld a, [hl]
    rlca
    rlca
    rlca
    ld c, a

    ;Push equipment table entry
    ld a, [w_player_equipment]
    ld d, a
    add a, a
    add a, a
    add a, low(player_spritetable)
    ld l, a
    ld a, high(player_spritetable)
    adc a, 0
    ld h, a
    push hl
    ld a, l
    add a, 3
    ld l, a
    jr nc, :+
        inc h
    :
    ld a, [hl]
    or a, c
    ld h, a

    ;What underlay should we use?
    ld a, d
    cp a, ITEM_ID_JETPACK
    ld bc, player_bckspr_jetpack
    jr z, .underlay_go

    ;Nope, no overlay. Just clear paint buffer
    ld de, $0300
    call painter_clear
    jr .underlay_done

    .underlay_go
        ;Paint for all base-sprites
        ld de, $40
        REPT (player_sprite_base.end - player_sprite_base) >> 6
            call painter_fill
        ENDR

        ;Paint for individual equipment things
        ld l, 7
        :   bit 0, h
            call z, painter_clear
            bit 0, h
            call nz, painter_fill
            rr h
            dec l
            jr nz, :-
        ;
    .underlay_done

    ;Start drawing real player sprites on top
    call painter_reset
    ld bc, player_sprite_base
    ld de, $140
    call painter_paint
    pop hl
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld de, $C0
    call painter_paint
    pop hl
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld de, $100
    call painter_paint

    ;Ok, now prepare VQUEUE transfer to get this mess into VRAM
    vqueue_add VQUEUE_TYPE_DIRECT, $300 / $10, VT_TOWER_PLAYER, w_paint
    xor a
    ld [hl+], a
    ld [hl+], a

    ;Return
    ret
;
