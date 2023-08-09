INCLUDE "hardware.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/player.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Change speed according to some variables and input.  
; Nothing except flags are committed to memory.
; Actual X-position not updated.
;
; Input:
; - `hl`: Player entity pointer (anywhere)
; - `d`: Acceleration speed
; - `e`: Friction speed
;
; Returns:
; - `bc`: New X-speed
;
; Saves: `hl`
player_xspeed_movement::
    push hl

    ;Get X-speed in BC
    player_relpointer_init ENTVAR_PLAYER_XSPEED
    ld a, [hl+]
    ld c, a
    ld a, [hl-]
    ld b, a

    ;Not moving?
    ldh a, [h_input]
    and a, PADF_LEFT | PADF_RIGHT
    jr nz, :+
        ld d, 0
        pop hl
        jp player_speed_slow
    :

    ;Update facing direction
    relpointer_move ENTVAR_PLAYER_FLAGS
    ld e, d
    ld d, 0
    ldh a, [h_input]
    bit PADB_RIGHT, a
    jr z, :+
        res PLAYER_FLAGB_FACING, [hl]
        pop hl
        jp player_speed_add
    :
        set PLAYER_FLAGB_FACING, [hl]
        pop hl
        jp player_speed_sub
    ;

    relpointer_destroy
;



; Update player position based on the given speed.
; Output X-position is NOT truncated.
; Does not commit anything to memory.
;
; Input:
; - `hl`: Player entity pointer (anywhere)
; - `bc`: X-speed to add
;
; Returns:
; - `bc`: New X-speed
; - `de`: New X-position
;
; Saves: `hl`
player_xspeed_apply::
    push hl

    ;Get X-position -> DE
    player_relpointer_init ENTVAR_PLAYER_XPOS
    ld a, [hl+]
    ld e, a
    ld a, [hl-]
    ld d, a

    ;Add speed
    ld a, e
    add a, c
    ld e, a
    ld a, d
    adc a, b
    ld d, a

    ;How to handle carry?
    bit 7, b
    jr c, .carried
        jr z, .return

        ;Beyond right side
        ld a, $FF
        jr .nowrap
    .carried
        jr nz, .return

        ;Beyond left side
        xor a
        ;jr .nowrap
    ;

    ;Do not wrap
    .nowrap
        ld d, a
        ld e, a
        ld bc, $0000
    ;

    ;Return
    .return
    relpointer_destroy
    pop hl
    ret
;



; Update player position by platform speed.
; Should only be used in the grounded state.
; Does not commit anything to memory.
; Output X-position is NOT truncated.
;
; Input:
; - `de`: Player X-position
;
; Output:
; - `de`: New X-position
;
; Saves: `hl`, `bc`
player_xspeed_platform::
    
    ;Add platform speed to player position.
    ld a, [w_platform_xspeed]
    add a, e
    ld e, a
    ld a, [w_platform_xspeed+1]
    adc a, d
    ld d, a

    ;Figure out how to handle carry
    ld a, [w_platform_xspeed+1]
    bit 7, a
    jr c, .carried
        ret z

        ;Beyond right side
        ld d, $FF
        ld e, d
        ret
    .carried
        ret nz

        ;Beyond left side
        xor a
        ld d, a
        ld e, a
        ret
    ;
;



; Commit player X-speed and X-position to memory.
;
; Input:
; - `bc`: Player X-speed
; - `de`: Player X-position
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`
player_xspeed_commit::
    push hl

    ;Save X-position
    player_relpointer_init ENTVAR_PLAYER_XPOS
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl-], a

    ;Save X-speed
    relpointer_move ENTVAR_PLAYER_XSPEED
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl-], a

    ;Stay within screen bounds
    call player_boundscheck

    ;Return
    relpointer_destroy
    pop hl
    ret
;
