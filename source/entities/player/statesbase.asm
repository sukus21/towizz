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
; - `d`: Player flags (`ENTVAR_PLAYER_FLAGS`)
;
; Destroys: all
player_state_grounded::
    relpointer_init l, ENTVAR_PLAYER_STATE
    
    ;Stand on top of platform
    relpointer_move ENTVAR_PLAYER_YPOS
    ld a, $FF
    ld [hl+], a
    ld a, [w_platform_ypos+1]
    dec a
    ld [hl-], a

    ;Set Y-speed to 0
    relpointer_move ENTVAR_PLAYER_YSPEED
    xor a
    ld [hl+], a
    ld [hl-], a

    ;Modify speed
    ld e, PLAYER_XSPEED_ACCEL_GROUND
    ld a, PLAYER_XSPEED_FRICTION_GROUND
    call player_xspeed_movement

    ;Apply speed to X-position
    call player_xspeed_apply

    ;Add platform speed
    call player_xspeed_platform

    ;Save speed and position
    call player_xspeed_commit

    ;Are we not on the platform anymore?
    ld a, [w_platform_xpos+1]
    ld b, a
    ld a, d
    cp a, b
    jr c, .return

    ;We are not on the platform anymore.
    relpointer_move ENTVAR_PLAYER_STATE
    ld [hl], PLAYER_STATE_AIRBORNE

    ;Return
    .return
    relpointer_destroy
    ret
;
