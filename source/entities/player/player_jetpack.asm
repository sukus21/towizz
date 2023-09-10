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
    ld [hl], PLAYER_JETPACK_USETIME
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



; Draw the jetpack fuel gauge.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `de`, `hl`
player_jetpack_draw::
    push hl

    ;Should we even draw the fuel gauge?
    player_relpointer_init ENTVAR_PLAYER_JETPACK_USE
    ld a, [hl]
    or a, a
    jr nz, :+
        pop hl
        ret
    :
    dec [hl]

    ;Figure out what sprite to use
    relpointer_move ENTVAR_PLAYER_JETPACK_FUEL
    ld a, [hl]
    ld c, PLAYER_SPRITE_JETPACK_FUEL
    cp a, PLAYER_JETPACK_FUEL_MAX
    jr z, .draw
    inc c
    inc c
    cp a, (PLAYER_JETPACK_FUEL_MAX / 3) * 2
    jr nc, .draw
    inc c
    inc c
    cp a, (PLAYER_JETPACK_FUEL_MAX / 3) * 1
    jr nc, .draw
    inc c
    inc c
    or a, a
    jr nz, .draw
    inc c
    inc c

    ;Get sprite
    .draw
    ldh a, [h_oam_active]
    ld h, a
    ld b, 4
    call sprite_get

    ;Draw
    ld a, e
    ld [hl+], a
    ld a, d
    add a, 16
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ld [hl], 0

    ;Return
    pop hl
    ret
;
