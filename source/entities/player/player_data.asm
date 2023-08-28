INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/player.inc"
INCLUDE "struct/vram/tower.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Loads the sprites needed for the player entity.
; These sprites include base-, equipment- and weapon sprites.  
; Assumes player equipment- and weapon IDs are set correctly.
entity_player_load::
    ld de, player_vprep_base
    call vqueue_enqueue

    ;Get equipment spritetable address
    ld hl, player_spritetable
    ld a, [w_player_equipment]
    add a, a
    add a, a
    add a, l
    ld l, a
    jr nc, :+
        inc h
    :
    
    ;Read source data pointer + length
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a
    ld d, [hl]

    ;Write VQUEUE transfer
    call vqueue_get
    ld a, VQUEUE_TYPE_DIRECT
    ld [hl+], a
    ld a, d
    ld [hl+], a
    xor a
    ld [hl+], a

    ;Write destination
    ld a, low(VT_TOWER_PLAYER + 16*(PLAYER_SPRITE_VAR - VTI_TOWER_PLAYER))
    ld [hl+], a
    ld a, high(VT_TOWER_PLAYER + 16*(PLAYER_SPRITE_VAR - VTI_TOWER_PLAYER))
    ld [hl+], a

    ;Write source
    ld a, bank(@)
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a

    ;Set writeback
    xor a
    ld [hl+], a
    ld [hl+], a

    ;Get destination -> stack
    ld hl, VT_TOWER_PLAYER + 16*(PLAYER_SPRITE_VAR - VTI_TOWER_PLAYER)
    ld a, d
    ld [w_player_woffset], a
    add a, a
    add a, a
    add a, a
    add a, a
    jr nc, :+
        inc h
    :
    add a, l
    ld l, a
    jr nc, :+
        inc h
    :
    push hl

    ;Get weapon spritetable address
    ld hl, player_spritetable
    ld a, [w_player_weapon]
    add a, a
    add a, a
    add a, l
    ld l, a
    jr nc, :+
        inc h
    :

    ;Read source data pointer + length
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a
    ld d, [hl]

    ;Write VQUEUE transfer
    call vqueue_get
    ld a, VQUEUE_TYPE_DIRECT
    ld [hl+], a
    ld a, d
    ld [hl+], a
    xor a
    ld [hl+], a

    ;Write destination
    pop de
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a

    ;Write source
    ld a, bank(@)
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a

    ;Set writeback
    xor a
    ld [hl+], a
    ld [hl+], a

    ;Return
    ret
;



; Prepared vqueue transfer for base player base sprites.
player_vprep_base:: vqueue_prepare_copy \
    VQUEUE_TYPE_DIRECT, \
    VT_TOWER_PLAYER, \
    player_sprite_base
;



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



; Adds a sprite table entry for the given label.
; Expands to 4 bytes of data.
;
; Input:
; - `1`: Sprite data (label)
MACRO sprtable
    dw \1
    db (\1.end - \1) >> 4
    db $00
ENDM

; Address table for player sprites.
player_spritetable:
    sprtable player_sprite_jump
    sprtable player_sprite_firebreath
;
