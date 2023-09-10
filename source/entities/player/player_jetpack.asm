INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/player.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Moves player into the air, uses jetpack fuel, sets Y-speed, etc.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Returns:
; - `fZ`: Changed state (z = no, nz = yes)
;
; Saves: `hl`
player_jetpack_use::
    push hl

    ;Do we have any fuel left?
    player_relpointer_init ENTVAR_PLAYER_JETPACK_FUEL
    ld a, [hl]
    or a, a
    jr z, .return
    dec [hl]

    ;Set use and tick
    relpointer_move ENTVAR_PLAYER_JETPACK_USE
    ld [hl], ENTVAR_PLAYER_JETPACK_USE
    relpointer_move ENTVAR_PLAYER_JETPACK_TICK
    inc [hl]

    ;Spawn particle?
    ld a, [hl]
    and a, %00001000
    jr z, .no_particle
        nop
    .no_particle

    ;Set state and Y-speed
    relpointer_move ENTVAR_PLAYER_STATE
    ld [hl], PLAYER_STATE_AIRBORNE
    relpointer_move ENTVAR_PLAYER_YSPEED
    ld a, low(PLAYER_JETPACK_YSPEED)
    ld [hl+], a
    ld a, high(PLAYER_JETPACK_YSPEED)
    ld [hl-], a

    .return
    relpointer_destroy
    pop hl
    or a, h
    ret
;
