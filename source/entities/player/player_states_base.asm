INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/player.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Grounded state for the player entity.
; Player is assumed to be standing on the platform.
; No vertical collision shenanigans here.
;
; Input:
; - `hl`: Player entity pointer (`ENTVAR_PLAYER_STATE`)
;
; Destroys: all
player_state_grounded::
    relpointer_init l, ENTVAR_PLAYER_STATE
    
    ;Stand on top of platform
    call player_yspeed_stand

    ;Modify speed
    ld d, PLAYER_XSPEED_ACCEL_GROUND
    ld e, PLAYER_XSPEED_FRICTION_GROUND
    call player_xspeed_movement

    ;Apply speed to X-position
    call player_xspeed_apply

    ;Add platform speed
    call player_xspeed_platform

    ;Save speed and position
    call player_xspeed_commit

    ;Fall off platform?
    ld c, PLAYER_STATE_AIRBORNE
    call player_left_platform
    ret nz

    ;Jump?
    ldh a, [h_input_pressed]
    bit PADB_A, a
    ret z

    ;Jump
    relpointer_move ENTVAR_PLAYER_STATE
    ld [hl], PLAYER_STATE_JUMPSQUAT
    relpointer_move ENTVAR_PLAYER_TIMER
    ld [hl], PLAYER_JUMPSQUAT_TIME

    ;Return
    relpointer_destroy
    ret
;



; Airborne state for the player entity.
;
; Input:
; - `hl`: `ENTVAR_PLAYER_STATE`
;
; Destroys: all
player_state_airborne::
    relpointer_init l, ENTVAR_PLAYER_STATE

    ;Save old X-position for later
    relpointer_move ENTVAR_XPOS+1
    ld a, [hl]
    push af

    ;Horizontal movement
    ld d, PLAYER_XSPEED_ACCEL_AIR
    ld e, PLAYER_XSPEED_FRICTION_AIR
    call player_xspeed_movement
    call player_xspeed_apply
    call player_xspeed_commit
    pop af
    ld c, a
    ld b, d
    push bc

    ;Vertical movement
    call player_yspeed_gravity
    call player_yspeed_commit

    ;Did we fall down?
    ld a, d
    cp a, SCRN_Y + $18
    jr c, .not_fallen
        add sp, 2
        call player_hurt
        jp player_respawn
    .not_fallen

    ;Do we need to react to the platform?
    ld a, PLAYER_STATE_GROUNDED
    pop bc
    call player_yspeed_platform

    ;Return
    relpointer_destroy
    ret
;



; Jumpsquat for the player entity.
; Wait for timer to tick down, then jump.
;
; Input:
; - `hl`: `ENTVAR_PLAYER_STATE`
;
; Destroys: all
player_state_jumpsquat::
    relpointer_init l, ENTVAR_PLAYER_STATE

    ;Stand on platform
    call player_yspeed_stand

    ;Horizontal movement
    xor a
    ld b, a
    ld c, a
    call player_xspeed_apply
    call player_xspeed_platform
    call player_xspeed_commit
    
    ;Fall off platform?
    ld c, PLAYER_STATE_AIRBORNE
    call player_left_platform
    ret nz

    ;Decrement timer
    relpointer_move ENTVAR_PLAYER_TIMER
    dec [hl]
    ret nz

    ;Move on to next state
    relpointer_move ENTVAR_PLAYER_STATE
    ld [hl], PLAYER_STATE_AIRBORNE

    ;Set Y-speed
    relpointer_move ENTVAR_PLAYER_YSPEED
    ld a, [w_platform_yspeed+1]
    sra a
    ld b, a
    ld a, [w_platform_yspeed]
    rra
    add a, low(-PLAYER_JUMP_STRENGTH)
    ld [hl+], a
    ld a, b
    adc a, high(-PLAYER_JUMP_STRENGTH)
    ld [hl-], a
    
    ;Set X-speed according to direction
    ldh a, [h_input]
    and a, PADF_LEFT | PADF_RIGHT
    jr nz, :+
        ld b, a
        ld c, a
        jr .apply_xspeed
    :
    ld bc, MUL(PLAYER_XSPEED_MAX << 16, 0.85) >> 16
    bit PADB_LEFT, a
    jr z, .apply_xspeed
        ld bc, MUL(PLAYER_XSPEED_MAX << 16, -0.85) >> 16
    ;

    .apply_xspeed
    relpointer_move ENTVAR_PLAYER_XSPEED
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a

    ;Return
    relpointer_destroy
    ret
;
