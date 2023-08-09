INCLUDE "hardware.inc"
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
    relpointer_move ENTVAR_PLAYER_XPOS+1
    ld a, [hl]
    push af

    ;Horizontal movement
    ld d, PLAYER_XSPEED_ACCEL_AIR
    ld e, PLAYER_XSPEED_FRICTION_AIR
    call player_xspeed_movement
    call player_xspeed_apply
    call player_xspeed_commit
    push de

    ;Perform gravity
    relpointer_move ENTVAR_PLAYER_YSPEED
    ld a, [hl]
    add a, low(PLAYER_GRAVITY)
    ld c, a
    ld [hl+], a
    ld a, [hl]
    adc a, high(PLAYER_GRAVITY)
    ld b, a
    ld [hl-], a

    ;Add to position
    relpointer_move ENTVAR_PLAYER_YPOS
    ld a, [hl+]
    add a, c
    ld e, a
    ld a, [hl-]
    adc a, b
    ld d, a

    ;No boundary crossing
    bit 7, b
    jr nz, :+
    jr nc, .not_carried
    jr .carried
    :
    jr c, .not_carried
    .carried
        xor a
        ld d, a
        ld e, a
        ld [hl+], a
        ld [hl-], a
    .not_carried

    ;Did we fall down?
    ld a, d
    cp a, SCRN_Y + $18
    jr c, .not_fallen
        add sp, 4
        call player_hurt
        jp player_respawn
    .not_fallen

    ;Do we need to react to the platform?
    pop af
    ld b, a
    ld a, [w_platform_xpos+1]
    cp a, b
    jr c, .no_platform
    jr z, .no_platform
        
        ;Is bottom above platform?
        ld a, [w_platform_ypos+1]
        ld b, a
        dec a
        cp a, d
        jr nc, .no_platform

        ;Is top below platform?
        ld a, [w_platform_height]
        add a, b
        ld b, a
        ld a, d
        sub a, PLAYER_HEIGHT
        cp a, b
        jr nc, .no_platform

        ;Ok, we have a collision. Now what
        pop af
        ld c, a
        ld a, [w_platform_xpos+1]
        cp a, c
        jr z, .pushed
        jr nc, .not_pushed
            ;Here we are
            .pushed
            ld b, a
            relpointer_push ENTVAR_PLAYER_XSPEED
            xor a
            ld [hl+], a
            ld [hl-], a
            relpointer_move ENTVAR_PLAYER_XPOS
            xor a
            ld [hl+], a
            ld [hl], b
            dec l
            relpointer_pop
            jr .ypos_save
        .not_pushed

        ;Are we above or under the platform?
        ld a, b
        cp a, d
        jr c, .bonkage
            ;Stand on platform
            relpointer_push ENTVAR_PLAYER_STATE
            ld [hl], PLAYER_STATE_GROUNDED
            relpointer_move ENTVAR_PLAYER_YPOS
            ld a, $FF
            ld [hl+], a
            ld a, [w_platform_ypos+1]
            dec a
            ld [hl-], a
            relpointer_pop
            ret
        ;

        ;Bonk tiny little head on bottom of platform
        .bonkage
            add a, PLAYER_HEIGHT
            ld d, a
            relpointer_push ENTVAR_PLAYER_YSPEED
            xor a
            ld e, a
            ld [hl+], a
            ld [hl-], a
            relpointer_pop
            jr .ypos_save
        ;
    .no_platform
    pop af

    ;Save Y-position
    .ypos_save
    relpointer_move ENTVAR_PLAYER_YPOS
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl-], a

    .return
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
