INCLUDE "macros/farcall.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/player.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Input:
; - `hl`: `ENTVAR_PLAYER_STATE`
player_state_stompers_jump::
    relpointer_init l, ENTVAR_PLAYER_STATE
    
    ;Horizontal movement
    ld de, PLAYER_XSPEED_STOMPERS_ACCEL
    call player_xspeed_accel
    call player_xspeed_apply
    call player_xspeed_commit
    
    ;Vertical momentum
    push de
    call player_yspeed_gravity
    call player_yspeed_commit
    call player_yspeed_fallen
    pop bc
    ret nz
    ld c, d
    ld a, PLAYER_STATE_GROUNDED
    call player_yspeed_platform
    jr z, :+
        set PLAYER_FLAGB_GROUNDED, [hl]
    :

    ;Wait for peak
    relpointer_move ENTVAR_PLAYER_YSPEED+1
    bit 7, [hl]
    jr nz, .return
        
        ;Reset speeds
        xor a
        ld [hl-], a
        ld [hl+], a
        relpointer_move ENTVAR_PLAYER_XSPEED
        xor a
        ld [hl+], a
        ld [hl-], a

        ;Start spinnin'
        relpointer_move ENTVAR_PLAYER_STATE
        ld [hl], PLAYER_STATE_STOMPERS_SPIN
        relpointer_move ENTVAR_PLAYER_TIMER
        ld [hl], 0
    ;

    .return
    relpointer_destroy
    ret
;



; Input:
; - `hl`: `ENTVAR_PLAYER_STATE`
player_state_stompers_spin::

    ret
;



; Input:
; - `hl`: `ENTVAR_PLAYER_STATE`
player_state_stompers_stomp::
    ret
;



; Input:
; - `hl`: `ENTVAR_PLAYER_STATE`
player_state_stompers_land::
    ret
;
