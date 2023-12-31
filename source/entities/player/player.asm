INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/memcpy.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/item.inc"
INCLUDE "struct/entity/player.inc"
INCLUDE "struct/vram/tower.inc"
INCLUDE "struct/vram/shop.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Create a new player entity.  
; Does not set X- and Y-positions, do that manually.  
; Allocates new entity.
;
; Output:
; - `hl`: Player entity pointer
;
; Saves: none
entity_player_create::
    entsys_new 64, entity_player, PLAYER_FLAGS

    ;Set width and height
    relpointer_move ENTVAR_HEIGHT
    ld [hl], PLAYER_HEIGHT
    relpointer_move ENTVAR_WIDTH
    ld [hl], PLAYER_WIDTH

    ;Reset variables
    relpointer_move ENTVAR_PLAYER_START
    xor a
    ld b, ENTVAR_PLAYER_COUNT
    :   ld [hl+], a
        dec b
        jr nz, :-
    ;

    ;Return
    relpointer_destroy
    ld l, c
    ret
;



; Player entity step function.
;
; Input:
; - `de`: Entity pointer
entity_player::
    ld h, d
    ld l, e

    ;Process and draw
    call entity_player_update
    call entity_player_draw

    ;Return
    ret 
;



; Does player movement and logic.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
entity_player_update:
    push hl

    ;Handle invincibility
    player_relpointer_init ENTVAR_PLAYER_INVINCIBLE
    ld a, [hl]
    or a, a
    jr z, :+
        dec [hl]
        jr nz, :+
        relpointer_move ENTVAR_PLAYER_FLAGS
        res PLAYER_FLAGB_INVINCIBLE, [hl]
        relpointer_move ENTVAR_PLAYER_INVINCIBLE
    :

    ;Read state
    relpointer_move ENTVAR_PLAYER_STATE
    ld a, [hl]
    push hl

    ;State switch
    ld bc, .animate
    push bc
    cp a, PLAYER_STATE_GROUNDED
    jp z, player_state_grounded
    cp a, PLAYER_STATE_AIRBORNE
    jp z, player_state_airborne
    cp a, PLAYER_STATE_JUMPSQUAT
    jp z, player_state_jumpsquat
    cp a, PLAYER_STATE_FIREBREATH
    jp z, player_state_firebreath
    cp a, PLAYER_STATE_STOMPERS_JUMP
    jp z, player_state_stompers_jump
    cp a, PLAYER_STATE_STOMPERS_SPIN
    jp z, player_state_stompers_spin
    cp a, PLAYER_STATE_STOMPERS_STOMP
    jp z, player_state_stompers_stomp
    cp a, PLAYER_STATE_STOMPERS_LAND
    jp z, player_state_stompers_land
    cp a, PLAYER_STATE_PURCHASE
    jp z, player_state_purchase

    ;Unknown state, oops
    .unknown_state
    ld hl, error_invplayerstate
    rst v_error

    ;Animate player
    .animate
    pop hl
    ld a, [hl]
    ld bc, .collect
    push bc
    cp a, PLAYER_STATE_GROUNDED
    jp z, player_animate_grounded
    cp a, PLAYER_STATE_AIRBORNE
    jp z, player_animate_airborne
    cp a, PLAYER_STATE_JUMPSQUAT
    ld b, PLAYER_SPRITE_JUMP_JUMPSQUAT
    jp z, player_animate_set
    cp a, PLAYER_STATE_FIREBREATH
    jp z, player_animate_firebreath
    cp a, PLAYER_STATE_STOMPERS_JUMP
    ld b, PLAYER_SPRITE_AIRBORNE_UP
    jp z, player_animate_set
    cp a, PLAYER_STATE_STOMPERS_SPIN
    jp z, player_animate_stompers_spin
    cp a, PLAYER_STATE_STOMPERS_STOMP
    jp z, player_animate_stompers_stomp
    cp a, PLAYER_STATE_STOMPERS_LAND
    ld b, PLAYER_SPRITE_STOMPERS_LAND
    jp z, player_animate_set
    cp a, PLAYER_STATE_PURCHASE
    ld b, VTI_SHOP_PLAYERPURCHASE
    jp z, player_animate_set

    ;Unknown state found
    ld b, VTI_TOWER_COIN
    jp player_animate_set

    ;Collect the coinz
    .collect
    pop hl
    push hl
    relpointer_set 0
    ld c, ENTSYS_FLAGF_COIN | ENTSYS_FLAGF_COLLISION
    call entsys_collision_all
    jr z, .no_collision
    .coin_loop
        push hl
        call entsys_free
        ld hl, w_money
        ld a, [hl]
        inc a
        cp a, 100
        jr c, :+
            ld a, 99
        :
        ld [hl], a
        ld c, ENTSYS_FLAGF_COIN | ENTSYS_FLAGF_COLLISION
        pop hl
        call entsys_collision_all.continue
        jr nz, .coin_loop
    .no_collision

    ;How about you touch some enemies instead?
    pop hl
    relpointer_move ENTVAR_PLAYER_FLAGS
    push hl
    ld a, [hl]
    and a, PLAYER_FLAGF_ARMORED | PLAYER_FLAGF_INVINCIBLE | PLAYER_FLAGF_GRACE
    jr nz, .no_hurt

    ;Yeah, do thing
    ld c, ENTSYS_FLAGF_HURT
    call entsys_collision_all
    jr z, .no_hurt
    .hurt_loop
        pop de
        push de
        push hl
        ld h, d
        ld l, e
        call player_hurt
        pop hl
        ld c, ENTSYS_FLAGF_HURT
        call entsys_collision_all.continue
        jr nz, .hurt_loop
    .no_hurt

    ;Decrement grace time
    pop hl
    relpointer_move ENTVAR_PLAYER_GRACETIME
    push hl
    ld a, [hl]
    or a, a
    jr z, :+
        dec [hl]
        jr nz, :+
        relpointer_move ENTVAR_PLAYER_FLAGS
        res PLAYER_FLAGB_GRACE, [hl]
    :

    ;Return
    .return
    relpointer_destroy
    pop hl
    ret
;



; Draw player entity.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
entity_player_draw:
    push hl

    ;Check invincibility
    player_relpointer_init ENTVAR_PLAYER_INVINCIBLE
    ld a, [hl]
    or a, a
    jr z, :+
        and a, %00000111
        cp a, 6
        jr c, :+

        ;Alrighty, ignore
        pop hl
        ret
    :

    ;Get sprite ID -> stack
    relpointer_move ENTVAR_PLAYER_SPRITE
    ld a, [hl]
    push af

    ;Get X and Y position -> DE
    relpointer_move ENTVAR_XPOS+1
    ld a, [w_camera_xpos+1]
    cpl
    add a, [hl]
    add a, 6
    ld d, a
    relpointer_move ENTVAR_YPOS+1
    ld e, [hl]
    inc e

    ;Draw jetpack fuel indicator?
    ld a, [w_player_equipment]
    cp a, ITEM_ID_JETPACK
    call z, player_jetpack_draw

    ;Get attributes -> C
    relpointer_move ENTVAR_PLAYER_ATTR
    ld c, [hl]
    relpointer_move ENTVAR_PLAYER_FLAGS
    ld b, [hl]
    bit PLAYER_FLAGB_FACING, b
    jr z, :+
        ld a, c
        xor a, OAMF_XFLIP
        ld c, a
    :

    ;Scooch X-position over
    bit OAMB_XFLIP, c
    jr z, :+
        ld a, d
        add a, 8
        ld d, a
    :

    ;Get sprite address -> HL
    ldh a, [h_oam_active]
    ld h, a
    ld b, 4*2
    call sprite_get

    ;Get tile ID -> B
    pop af
    add a, VTI_TOWER_PLAYER
    ld b, a

    ;Write sprite 0
    ld [hl], e
    inc l
    ld [hl], d
    inc l
    ld [hl], b
    inc l
    ld [hl], c
    inc l

    ;Move to sprite 1
    inc b
    inc b
    ld a, d
    add a, 8
    bit OAMB_XFLIP, c
    jr z, :+
        sub a, 16
    :
    ld d, a

    ;Write sprite 1
    ld [hl], e
    inc l
    ld [hl], d
    inc l
    ld [hl], b
    inc l
    ld [hl], c

    ;Return
    relpointer_destroy
    pop hl
    ret
;



; Speed subroutine.
;
; Input:
; - `bc`: Current speed
; - `de`:  Change
;
; Returns:
; - `bc`: new speed
;
; Saves: `de`, `hl`
player_speed_add::
    bit 7, b
    jr nz, .valid
    
    ld a, b
    cp a, high(PLAYER_XSPEED_MAX)
    jr c, .valid
    ret nz

    ;Do more testing
    ld a, c
    cp a, low(PLAYER_XSPEED_MAX)
    ret nc

    ;Speed is below cap, Add onto it
    .valid
    ld a, c
    add a, e
    ld c, a
    ld a, b
    adc a, d
    ld b, a

    ;Check high bounds
    bit 7, b
    ret nz
    cp a, high(PLAYER_XSPEED_MAX)
    ret c
    jr nz, .adjust

    ;Check low bounds
    ld a, c
    cp a, low(PLAYER_XSPEED_MAX)
    ret c
    ret z

    ;Set bounds and return
    .adjust
    ld bc, PLAYER_XSPEED_MAX
    ret
;



; Speed subroutine.
;
; Input:
; - `bc`: Current speed
; - `de`: Change
;
; Returns:
; - `bc`: new speed
;
; Saves: `de`, `hl`
player_speed_sub::
    bit 7, b
    jr z, .valid
    
    ld a, b
    cp a, high(-PLAYER_XSPEED_MAX)
    jr nc, .valid
    ret nz

    ;Do more testing
    ld a, c
    cp a, low(-PLAYER_XSPEED_MAX)
    ret c

    ;Speed is below cap, Add onto it
    .valid
    ld a, c
    sub a, e
    ld c, a
    ld a, b
    sbc a, d
    ld b, a

    ;Check high bounds
    bit 7, b
    ret z
    cp a, high(-PLAYER_XSPEED_MAX)
    jr c, .adjust
    ret nz

    ;Check low bounds
    ld a, c
    cp a, low(-PLAYER_XSPEED_MAX)
    ret nc

    ;Set bounds and return
    .adjust
    ld bc, -PLAYER_XSPEED_MAX
    ret
;



; Speed subroutine.
; Moves speed towards 0.
; If 0 is passed, it is set to 0.
;
; Input:
; - `bc`: `ENTVAR_PLAYER_XSPEED` | `ENTVAR_PLAYER_YSPEED`
; - `de`: Change
;
; Returns:
; - `bc`: new speed
;
; Saves: `de`, `hl`
player_speed_slow::
    bit 7, b
    jr nz, .increase
        ;Decrease speed, lower byte
        ld a, c
        sub a, e
        ld c, a

        ;Higher byte
        ld a, b
        sbc a, d
        ld b, a
        ret nc

        ;Set to 0
        ld bc, $0000
        ret
    
    .increase
        ;Increase speed, lower byte
        ld a, c
        add a, e
        ld c, a

        ;Higher byte
        ld a, b
        adc a, d
        ld b, a
        ret nc

        ;Set to 0
        ld bc, $0000
        ret
    ;
;



; Makes sure the player stays within the screen bounds.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Returns:
; - `de`: New X-position
;
; Saves: `bc`, `hl`
player_boundscheck::
    push hl

    ;Get X-position -> DE
    player_relpointer_init ENTVAR_XPOS+1
    ld a, [hl-]
    ld d, a
    ld a, [hl+]
    ld e, a

    ;Get lowest possible screen position
    ld a, [w_camera_xpos+1]
    cp a, [hl]
    jr z, .above_min
    jr c, .above_min
        ld e, $00
        jr .bounds
    ;

    .above_min
    add a, SCRN_X - PLAYER_WIDTH
    cp a, [hl]
    jr nc, .return
        ld e, $FF

        ;Stay inside screen bounds
        .bounds
        ld [hl-], a
        ld d, a
        ld a, e
        ld [hl+], a
        relpointer_move ENTVAR_PLAYER_XSPEED
        xor a
        ld [hl+], a
        ld [hl-], a
    ;

    ;Return
    .return
    relpointer_destroy
    pop hl
    ret
;



; Respawns player at the start.
;
; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`  
; Destroys: `af`, `bc`, `de`
player_respawn::
    push hl

    ;Reset speeds
    player_relpointer_init ENTVAR_PLAYER_XSPEED
    xor a
    ld [hl+], a
    ld [hl-], a
    relpointer_move ENTVAR_PLAYER_YSPEED
    xor a
    ld [hl+], a
    ld [hl-], a

    ;Reset X-position
    relpointer_move ENTVAR_XPOS+1
    ld a, [w_platform_xpos+1]
    ld b, a
    res 0, b
    ld a, [w_camera_xpos+1]
    res 0, a
    add a, b
    adc a, 0
    rrca
    ld [hl], a

    ;Reset Y-position
    relpointer_move ENTVAR_YPOS+1
    ld a, [w_platform_ypos+1]
    sub a, $17
    ld [hl], a

    ;Reset state
    relpointer_move ENTVAR_PLAYER_STATE
    ld [hl], PLAYER_STATE_AIRBORNE ;TODO: respawn state

    ;Return
    relpointer_destroy
    pop hl
    ret
;



; Deal damage to player.
;
; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`, `de`  
; Destroys: `af`, `b`
player_hurt::
    ld b, l
    player_relpointer_init ENTVAR_PLAYER_FLAGS
    set PLAYER_FLAGB_INVINCIBLE, [hl]
    relpointer_move ENTVAR_PLAYER_INVINCIBLE
    ld [hl], PLAYER_INVINCIBLE_TIME
    
    ;Decrease health
    ld a, [w_player_health]
    dec a
    jr nz, :+
        ld hl, error_gameover
        rst v_error
    :
    ld [w_player_health], a

    ;Return
    relpointer_destroy
    ld l, b
    ret
;



; Switch player state based on the weapon equipped.
; Might crash if invalid weapon is selected.
;
; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Returns:
; - `fZ`: Switched state (z = no, nz = yes)
;
; Saves: none
player_use_weapon::
    player_relpointer_init ENTVAR_PLAYER_STATE
    ldh a, [h_input_pressed]
    bit PADB_B, a
    ret z

    ;What weapon to use?
    ld a, [w_player_weapon]

    ;Fire breath
    cp a, ITEM_ID_FIREBREATH
    jr nz, :+
        relpointer_push ENTVAR_PLAYER_STATE, 0
        ld [hl], PLAYER_STATE_FIREBREATH
        relpointer_move ENTVAR_PLAYER_TIMER
        ld [hl], PLAYER_FIREBREATH_TIME
        or a, h ;H is never 0 here, resets Z flag
        ret
        relpointer_pop 0
    :

    ;Stompers
    cp a, ITEM_ID_STOMPERS
    jr nz, :+
        relpointer_push ENTVAR_PLAYER_FLAGS, 0
        ld d, [hl]
        relpointer_move ENTVAR_PLAYER_STATE
        bit PLAYER_FLAGB_GROUNDED, d
        jr nz, .stompers_jump

            ;Ok, start spinnin'
            ld [hl], PLAYER_STATE_STOMPERS_SPIN

            ;Set speed to no
            relpointer_move ENTVAR_PLAYER_XSPEED
            xor a
            ld [hl+], a
            ld [hl-], a
            relpointer_move ENTVAR_PLAYER_YSPEED
            xor a
            ld [hl+], a
            ld [hl-], a

            ;Reset timer
            relpointer_move ENTVAR_PLAYER_TIMER
            ld [hl], 0
            or a, h
            ret
        ;

        ;We gotta reach appropriate height first
        .stompers_jump
            relpointer_set ENTVAR_PLAYER_STATE
            ld [hl], PLAYER_STATE_STOMPERS_JUMP

            ;Set speeds
            relpointer_move ENTVAR_PLAYER_XSPEED
            xor a
            ld [hl+], a
            ld [hl-], a
            relpointer_move ENTVAR_PLAYER_YSPEED
            ld a, low(PLAYER_YSPEED_STOMPERS_JUMP)
            ld [hl+], a
            ld a, high(PLAYER_YSPEED_STOMPERS_JUMP)
            ld [hl-], a

            ;Reset timer
            relpointer_move ENTVAR_PLAYER_TIMER
            ld [hl], 0
            or a, h
            ret
        ;

        relpointer_pop 0
    :

    ;Unknown weapon
    ld hl, error_unknown_weapon
    rst v_error
    relpointer_destroy
;



; Input:
; - `hl`: Player entity pointer (state)
player_state_purchase:
    call vqueue_empty
    ret nz

    player_relpointer_init ENTVAR_PLAYER_TIMER
    ld a, [hl]
    or a, a
    jr z, :+
        relpointer_push ENTVAR_PLAYER_STATE, 0
        ld [hl], PLAYER_STATE_AIRBORNE
        relpointer_pop 0
        ret
    :

    ;Ok, start re-loading player sprites
    ld [hl], 1
    jp entity_player_load
;
