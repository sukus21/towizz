INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/memcpy.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/player.inc"
INCLUDE "struct/vram/tower.inc"
INCLUDE "entsys.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Create a new player entity.  
; Allocates new entity.
;
; Output:
; - `hl`: Player entity pointer
;
; Saves: none
entity_player_create::
    call entsys_new32
    ld h, b
    ld l, c

    ;Set bank
    ld a, bank(@)
    ld [hl+], a
    inc l

    ;Set step function
    ld a, low(entity_player)
    ld [hl+], a
    ld a, high(entity_player)
    ld [hl+], a

    ;Reset variables
    ld a, l
    and a, %11100000
    add a, ENTVAR_VAR
    ld l, a
    xor a
    REPT ENTVAR_PLAYER_COUNT
        ld [hl+], a
    ENDR

    ;Load sprites
    push bc
    memcpy_label entity_player_sprite_base, VT_TOWER_PLAYER

    ;Return
    pop bc
    ret
;



; Player entity step function.
;
; Input:
; - `de`: Entity pointer
entity_player::
    ld h, d
    ld l, e
    relpointer_init l, ENTVAR_BANK

    ;Flags -> C, input -> B
    relpointer_move ENTVAR_PLAYER_FLAGS
    ld c, [hl]
    ld a, [h_input]
    ld b, a

    ;Move horizontally
    relpointer_move ENTVAR_PLAYER_XPOS+1
    bit PADB_LEFT, b
    jr z, :+
        set PLAYER_FLAGB_FACING, c
        dec [hl]
    :
    bit PADB_RIGHT, b
    jr z, :+
        res PLAYER_FLAGB_FACING, c
        inc [hl]
    :

    ;Move vertically
    relpointer_move ENTVAR_PLAYER_YPOS+1
    bit PADB_UP, b
    jr z, :+
        dec [hl]
    :
    bit PADB_DOWN, b
    jr z, :+
        inc [hl]
    :

    ;Save flags
    relpointer_move ENTVAR_PLAYER_FLAGS
    ld [hl], c

    ;Draw
    call entity_player_draw

    ;Return
    relpointer_destroy
    ret 
;



; Draw player entity.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
entity_player_draw:
    push hl

    ld a, l
    and a, %11100000
    or a, ENTVAR_PLAYER_XPOS+1
    ld l, a

    ;Get X and Y position -> DE
    relpointer_init l, ENTVAR_PLAYER_XPOS+1
    ld a, [hl]
    add a, 8
    ld d, a
    relpointer_move ENTVAR_PLAYER_YPOS+1
    ld a, [hl]
    add a, 16
    ld e, a

    ;Get flags -> C
    relpointer_move ENTVAR_PLAYER_FLAGS
    ld b, [hl]
    ld c, OAMF_PAL0
    bit PLAYER_FLAGB_FACING, b
    jr z, :+
        set OAMB_XFLIP, c

        ;Scooch X-position over
        ld a, d
        add a, 8
        ld d, a
    :

    ;Get sprite address -> HL
    ldh a, [h_oam_active]
    ld h, a
    ld b, 4*2
    call sprite_get

    ;Get tile ID -> B
    ld b, VTI_TOWER_PLAYER

    ;Write sprite 0
    ld [hl], e
    inc l
    ld [hl], d
    inc l
    ld [hl], b
    inc l
    ld [hl], c
    inc l

    ;Move to sprite 1
    inc b
    inc b
    ld a, d
    add a, 8
    bit OAMB_XFLIP, c
    jr z, :+
        sub a, 16
    :
    ld d, a

    ;Write sprite 1
    ld [hl], e
    inc l
    ld [hl], d
    inc l
    ld [hl], b
    inc l
    ld [hl], c

    ;Return
    relpointer_destroy
    pop hl
    ret
;
