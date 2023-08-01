INCLUDE "hardware.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/player.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Grounded state for the player entity.
; Player is assumed to be standing on the platform.
; No vertical collision shenanigans here.
;
; Input:
; - `hl`: `ENTVAR_PLAYER_STATE`
;
; Destroys: all
player_state_grounded::
    relpointer_init l, ENTVAR_PLAYER_STATE
    
    ;Stand on top of platform
    relpointer_move ENTVAR_PLAYER_YPOS
    ld a, $FF
    ld [hl+], a
    ld a, [w_platform_ypos]
    dec a
    ld [hl-], a

    ;Set Y-speed to 0
    relpointer_move ENTVAR_PLAYER_YSPEED
    xor a
    ld [hl+], a
    ld [hl-], a

    ;Get X-position -> stack
    relpointer_move ENTVAR_PLAYER_XPOS
    ld a, [hl+]
    ld c, a
    ld a, [hl-]
    ld b, a
    push bc

    ;Get X-speed in BC
    relpointer_move ENTVAR_PLAYER_XSPEED
    ld a, [hl+]
    ld c, a
    ld a, [hl-]
    ld b, a

    ;Not moving?
    ldh a, [h_input]
    and a, PADF_LEFT | PADF_RIGHT
    jr nz, :+
        ld e, PLAYER_XSPEED_FRICTION_GROUND
        call player_speed_slow
        jr .moved_horizontal
    :

    ;Add or subtract speed?
    ld e, 0
    bit PADB_RIGHT, a
    jr z, :+
        res PLAYER_FLAGB_FACING, d
    :
    bit PADB_LEFT, a
    jr z, :+
        set PLAYER_FLAGB_FACING, d
        inc e
    :
    xor a
    bit PLAYER_FLAGB_DIRX, d
    jr z, :+
        inc a
    :
    xor a, e

    ;Do some schmoovement
    ld e, PLAYER_XSPEED_ACCEL_GROUND
    jr nz, .hsub
        call player_speed_add
        jr .moved_horizontal
    .hsub
        call player_speed_sub
        ;jr .moved_horizontal
    ;

    ;Save flags
    .moved_horizontal
    relpointer_move ENTVAR_PLAYER_FLAGS
    ld [hl], d

    ;Apply speed to X-position
    relpointer_move ENTVAR_PLAYER_XPOS
    bit PLAYER_FLAGB_DIRX, d
    pop de
    jr nz, .speed_sub
        ld a, e
        add a, c
        ld [hl+], a
        ld a, d
        adc a, b
        ld [hl-], a
        jr .speed_save
    .speed_sub
        ld a, e
        sub a, c
        ld [hl+], a
        ld a, d
        sbc a, b
        ld [hl-], a
        jr nc, .speed_save

        ;We cannot move into the wall, set everything to 0
        xor a
        ld [hl+], a
        ld [hl-], a
        ld b, a
        ld c, a
        ;jr .speed_save
    ;
    
    ;Save X-speed
    .speed_save
    relpointer_move ENTVAR_PLAYER_XSPEED
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl-], a

    ;Return
    relpointer_destroy
    ret
;
