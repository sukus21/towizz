INCLUDE "hardware.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/player.inc"
INCLUDE "struct/vram/tower.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Set player sprite to a specific sprite.
;
; Input:
; - `b`: Sprite (`PLAYER_SPRITE_*`)
; - `hl`: Player entity pointer (anywhere)
;
; Destroys: `af`, `bc`  
; Saves: `hl`, `de`
player_sprite_set::
    ld c, l

    ;Apply
    player_relpointer_init ENTVAR_PLAYER_SPRITE
    ld [hl], b
    relpointer_move ENTVAR_PLAYER_ANIMATION
    ld [hl], 0
    relpointer_destroy

    ;Return
    ld l, c
    ret
;



; Set player sprite when grounded.
;
; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`, `de`
player_sprite_grounded::
    push hl

    ;How are we doing in the speed department?
    player_relpointer_init ENTVAR_PLAYER_XSPEED
    ld a, [hl+]
    ld c, a
    ld a, [hl-]
    ld b, a

    relpointer_move ENTVAR_PLAYER_ANIMATION
    ld a, b
    or a, c
    jr nz, :+
        ;We are NOT moving, set sprite to base
        ld b, PLAYER_SPRITE_IDLE
        ld c, 0
        ld [hl], c
        jr .return
    :

    ;Add this to speed
    ld a, b
    bit 7, b
    jr z, :+
        cpl
    :
    add a, a
    inc a
    add a, [hl]
    ld [hl], a
    ld c, a

    ;Actually wait, restart animation?
    ldh a, [h_input_pressed]
    and a, PADF_LEFT | PADF_RIGHT
    jr z, :+
        ld a, c
        and a, %00100000
        or a, %00010000
        ld [hl], a
        ld c, a
    :

    ;Save sprite
    .return

    ;What frame should we use?
    ld b, PLAYER_SPRITE_IDLE
    bit 4, c
    jr z, :+
        bit 5, c
        ld b, PLAYER_SPRITE_WALK1
        jr z, :+
        ld b, PLAYER_SPRITE_WALK2
    :

    ;Store it
    relpointer_move ENTVAR_PLAYER_SPRITE
    ld [hl], b

    ;Actually return
    relpointer_destroy
    pop hl
    ret
;



; Set player sprite when airborne.
;
; Input:
; - `hl`: Player entity pointer (anywhere)
player_sprite_airborne::
    ld c, a
    
    ;Get sprite based on Y-speed
    ld b, PLAYER_SPRITE_AIRBORNE_DOWN
    player_relpointer_init ENTVAR_PLAYER_YSPEED+1
    bit 7, [hl]
    jr z, :+
        ld b, PLAYER_SPRITE_AIRBORNE_UP
    :

    ;Apply sprite
    relpointer_move ENTVAR_PLAYER_SPRITE
    ld [hl], b

    ;Return
    relpointer_destroy
    ld l, c
    ret
;
