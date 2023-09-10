INCLUDE "hardware.inc"
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

    ;Reset grounded flag
    relpointer_move ENTVAR_PLAYER_FLAGS
    res PLAYER_FLAGB_GROUNDED, [hl]
    
    ;Vertical momentum
    push de
    call player_yspeed_gravity
    call player_yspeed_commit
    call player_yspeed_fallen
    pop bc
    ret nz
    ld c, d
    ld a, PLAYER_STATE_STOMPERS_LAND
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
    relpointer_init l, ENTVAR_PLAYER_STATE

    ;Tick timer
    relpointer_move ENTVAR_PLAYER_TIMER
    inc [hl]
    ld a, [hl]

    ;Start GOING?
    cp a, PLAYER_STOMPERS_SPIN_TIME
    jr c, .no_go

        ;Absolutely
        ld e, l
        relpointer_push ENTVAR_PLAYER_YSPEED, 0
        ld a, low(PLAYER_YSPEED_STOMPERS_STOMP)
        ld [hl+], a
        ld a, high(PLAYER_YSPEED_STOMPERS_STOMP)
        ld [hl-], a

        ;This is now a DMGcall entity
        relpointer_move ENTVAR_FLAGS
        ld [hl], PLAYER_STOMPERS_FLAGS
        relpointer_move ENTVAR_DMGCALL
        ld a, low(player_stompers_dmgcall)
        ld [hl+], a
        ld a, high(player_stompers_dmgcall)
        ld [hl-], a

        ;Set this (important)
        relpointer_move ENTVAR_PLAYER_ATTR
        ld [hl], 0

        ;Stomp time
        relpointer_move ENTVAR_PLAYER_STATE
        ld [hl], PLAYER_STATE_STOMPERS_STOMP
        relpointer_pop 0
        ld l, e
    .no_go

    ;Check platform collision
    relpointer_move ENTVAR_XPOS+1
    ld a, [w_platform_xpos+1]
    cp a, [hl]
    jr c, .no_platform
    relpointer_move ENTVAR_YPOS+1
    ld a, [w_platform_ypos+1]
    cp a, [hl]
    jr nc, .no_platform

        ;Set position
        ld [hl-], a
        xor a
        ld [hl+], a

        ;Set this (important)
        relpointer_move ENTVAR_PLAYER_ATTR
        ld [hl], 0

        ;Ok, landing state it is
        relpointer_move ENTVAR_PLAYER_TIMER
        ld [hl], 0
        relpointer_move ENTVAR_PLAYER_STATE
        ld [hl], PLAYER_STATE_STOMPERS_LAND
    .no_platform

    ;Return
    relpointer_destroy
    ret
;



; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`, `de`
player_animate_stompers_spin::
    push hl

    ;Figure out sprite and attributes
    player_relpointer_init ENTVAR_PLAYER_TIMER
    ld a, [hl]
    ld b, PLAYER_SPRITE_AIRBORNE_DOWN
    ld c, 0
    bit 3, a
    jr nz, .sprited
    bit 2, a
    jr z, :+
        ld c, OAMF_XFLIP | OAMF_YFLIP
    :
    bit 1, a
    jr z, :+
        ld b, PLAYER_SPRITE_STOMPERS_ROTATE
    :
    
    ;Apply sprite and attribute
    .sprited
    relpointer_move ENTVAR_PLAYER_SPRITE
    ld [hl], b
    relpointer_move ENTVAR_PLAYER_ATTR
    ld [hl], c

    ;Return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: `ENTVAR_PLAYER_STATE`
player_state_stompers_stomp::
    relpointer_init l, ENTVAR_PLAYER_STATE

    ;Set armor
    relpointer_move ENTVAR_PLAYER_FLAGS
    set PLAYER_FLAGB_ARMORED, [hl]

    ;Tick animation
    relpointer_move ENTVAR_PLAYER_ANIMATION
    inc [hl]

    ;Vertical momentum
    call player_yspeed_gravity
    call player_yspeed_commit
    call player_yspeed_fallen
    jr nz, .quit
    relpointer_move ENTVAR_XPOS+1
    ld b, [hl]
    ld c, d
    ld a, PLAYER_STATE_STOMPERS_LAND
    call player_yspeed_platform
    jr nz, .quit

    ;Return
    relpointer_destroy
    ret

    .quit
        ;Reset armor
        player_relpointer_init ENTVAR_PLAYER_FLAGS
        res PLAYER_FLAGB_ARMORED, [hl]
        relpointer_move ENTVAR_FLAGS
        ld [hl], PLAYER_FLAGS

        ;Reset timer
        relpointer_move ENTVAR_PLAYER_TIMER
        ld [hl], 0

        ;Return
        relpointer_destroy
        ret
    ;
;



; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`, `de`
player_animate_stompers_stomp::
    push hl

    ;Figure out sprite and attributes
    player_relpointer_init ENTVAR_PLAYER_ANIMATION
    ld b, [hl]
    relpointer_move ENTVAR_PLAYER_SPRITE
    ld [hl], PLAYER_SPRITE_STOMPERS_FALL1
    bit 2, b
    jr z, :+
        ld [hl], PLAYER_SPRITE_STOMPERS_FALL2
    :

    ;Return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: `ENTVAR_PLAYER_STATE`
player_state_stompers_land::
    relpointer_init l, ENTVAR_PLAYER_STATE
    
    ;Move with platform
    call player_yspeed_stand
    relpointer_move ENTVAR_XPOS
    ld a, [hl+]
    ld c, a
    ld a, [hl-]
    ld b, a
    call player_xspeed_platform

    ;Tick timer
    relpointer_move ENTVAR_PLAYER_TIMER
    inc [hl]
    ld a, [hl]
    cp a, PLAYER_STOMPERS_LAND_TIME
    ret c

    ;Landing
    relpointer_move ENTVAR_PLAYER_STATE
    ld [hl], PLAYER_STATE_GROUNDED

    ;Return
    relpointer_destroy
    ret
;



; Called when damage is dealt by stomping.
; Bounce and go to airborne state.
;
; Input:
; - `de`: Entity pointer
player_stompers_dmgcall:
    ld h, d
    ld l, e
    relpointer_init l

    ;Reset flags
    relpointer_move ENTVAR_FLAGS
    ld [hl], PLAYER_FLAGS
    relpointer_move ENTVAR_PLAYER_FLAGS
    res PLAYER_FLAGB_ARMORED, [hl]

    ;Set state
    relpointer_move ENTVAR_PLAYER_STATE
    ld [hl], PLAYER_STATE_AIRBORNE

    ;Set Y-speed
    relpointer_move ENTVAR_PLAYER_YSPEED
    ld a, low(PLAYER_YSPEED_STOMPERS_BOUNCE)
    ld [hl+], a
    ld a, high(PLAYER_YSPEED_STOMPERS_BOUNCE)
    ld [hl-], a
    
    ;Return
    relpointer_destroy
    ret
;
