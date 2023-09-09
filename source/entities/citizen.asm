INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/citizen.inc"

SECTION "ENTITY CITIZEN", ROMX

; Citizen tileset.
citizen_tls: INCBIN "graphics/enemy_citizen.tls"
.end



; Queues up citizen sprites.
; Sets writeback to `w_vqueue_writeback`.
entity_citizen_load::
    ld b, 2
    call tower_sprite_alloc
    ld a, b
    ld [w_citizen_sprite], a
    vqueue_add_copy \
        VQUEUE_TYPE_DIRECT, \
        de, \
        citizen_tls
    ;

    ;Set writeback
    ld a, low(w_vqueue_writeback)
    ld [hl+], a
    ld [hl], high(w_vqueue_writeback)

    ;Return
    ret
;



; Create a new citizen entity.
;
; Input:
; - `b`: X-position
; - `c`: Y-position
;
; Returns:
; - `hl`: Entity pointer
;
; Destroys: all
entity_citizen_create::
    ld hl, w_citizen_count
    inc [hl]

    ;Allocate entity
    push bc
    entsys_new 32, entity_citizen_step, CITIZEN_FLAGS_WAIT
    pop bc

    ;Set Y-position
    relpointer_move ENTVAR_YPOS
    xor a
    ld [hl+], a
    ld a, c
    ld [hl-], a

    ;Set X-position
    relpointer_move ENTVAR_XPOS
    xor a
    ld [hl+], a
    ld a, b
    ld [hl-], a

    ;Set width and height
    relpointer_move ENTVAR_HEIGHT
    ld [hl], CITIZEN_HEIGHT
    relpointer_move ENTVAR_WIDTH
    ld [hl], CITIZEN_WIDTH

    ;Set state and type
    relpointer_move ENTVAR_CITIZEN_STATE
    ld [hl], CITIZEN_STATE_WAIT
    relpointer_move ENTVAR_CITIZEN_TYPE
    call rng_run_single
    and a, %00000011
    ld [hl], a

    ;Reset speeds
    relpointer_move ENTVAR_CITIZEN_XSPEED
    xor a
    ld [hl+], a
    ld [hl-], a
    relpointer_move ENTVAR_CITIZEN_YSPEED
    xor a
    ld [hl+], a
    ld [hl-], a

    ;Give the timer some temporary love
    relpointer_move ENTVAR_CITIZEN_TIMER
    call rng_run_single
    and a, %00001111
    add a, CITIZEN_WAIT_TIME
    ld [hl], a

    ;Set health and stun
    relpointer_move ENTVAR_CITIZEN_HEALTH
    ld [hl], CITIZEN_HEALTH
    relpointer_move ENTVAR_CITIZEN_STUN
    ld [hl], 0

    ;Set sprite
    relpointer_move ENTVAR_CITIZEN_SPRITE
    call rng_run_single
    and a, %00011000
    ld [hl], a

    ;Ok, we are gucci
    relpointer_destroy
    ret
;



; Main step function for citizen entity.
;
; Input:
; - `de`: Entity pointer (0)
entity_citizen_step:
    ld h, d
    ld l, e

    call citizen_update
    call citizen_draw

    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
citizen_update:
    push hl
    relpointer_init l

    ;Decrement stun
    relpointer_move ENTVAR_CITIZEN_STUN
    ld a, [hl]
    or a, a
    jr z, :+
        dec [hl]
    :

    ;You'll never guess what I'm preparing here
    relpointer_move ENTVAR_CITIZEN_STATE
    ld a, [hl]
    ld bc, .poststate
    push bc

    ;That's right, a good ol' reliable state machine
    cp a, CITIZEN_STATE_WAIT
    jp z, citizen_wait
    cp a, CITIZEN_STATE_AWAKE
    jp z, citizen_awake
    cp a, CITIZEN_STATE_AIRBORNE
    jp z, citizen_airborne
    cp a, CITIZEN_STATE_GROUNDED
    jp z, citizen_grounded

    ;Unknown state
    ld hl, error_invst_citizen
    rst v_error

    .poststate

    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
citizen_wait:
    push hl

    ;Do we tick down the timer?
    entsys_relpointer_init ENTVAR_CITIZEN_TIMER
    ld a, [hl]
    or a, a
    jr z, .return

    ;Yes we do!
    dec [hl]
    jr nz, .return

    ;Uh oh, time to awaken
    relpointer_move ENTVAR_CITIZEN_STATE
    ld [hl], CITIZEN_STATE_AWAKE

    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
citizen_awake:
    push hl

    ;Animate
    entsys_relpointer_init ENTVAR_CITIZEN_ANIMATE
    ld a, [hl]
    add a, 13
    ld [hl], a

    ;Tick timer
    relpointer_move ENTVAR_CITIZEN_TIMER
    inc [hl]
    ld a, [hl]

    ;Do we start moving'?
    cp a, CITIZEN_AWAKE_TIME
    jr c, .return

    ;Set speeds
    relpointer_move ENTVAR_CITIZEN_YSPEED
    call rng_run_single
    ld [hl+], a
    call rng_run_single
    or a, %11111110
    sub a, 2
    ld [hl-], a
    relpointer_move ENTVAR_CITIZEN_XSPEED
    call rng_run_single
    or a, %11000000
    ld [hl+], a
    xor a
    ld [hl-], a

    ;Update state
    relpointer_move ENTVAR_CITIZEN_STATE
    ld [hl], CITIZEN_STATE_AIRBORNE

    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
citizen_airborne:
    push hl

    ;Set animation
    entsys_relpointer_init ENTVAR_CITIZEN_ANIMATE
    ld [hl], $FF

    ;Get X-speed -> BC
    relpointer_move ENTVAR_CITIZEN_XSPEED
    ld a, [hl+]
    ld c, a
    ld a, [hl-]
    ld b, a

    ;Add X-speed to X-position -> BC
    relpointer_move ENTVAR_XPOS
    ld a, c
    add a, [hl]
    ld c, a
    ld [hl+], a
    ld a, b
    adc a, [hl]
    ld b, a
    ld [hl-], a

    ;Do gravity and Y-speed -> DE
    relpointer_move ENTVAR_CITIZEN_YSPEED
    ld a, low(CITIZEN_YSPEED_GRAVITY)
    add a, [hl]
    ld e, a
    ld [hl+], a
    ld a, high(CITIZEN_YSPEED_GRAVITY)
    adc a, [hl]
    ld d, a
    ld [hl-], a

    ;Add Y-speed to Y-position -> DE
    relpointer_move ENTVAR_YPOS
    ld a, e
    add a, [hl]
    ld e, a
    ld [hl+], a
    ld a, d
    adc a, [hl]
    ld d, a
    ld [hl-], a

    ;Do we collide with the platform?
    ld a, [w_platform_xpos+1]
    cp a, b
    jr c, .return
    ld a, [w_platform_ypos+1]
    cp a, d
    jr nc, .return

        ;Ok, there is ground collision
        ld [hl], 0
        inc l
        ld [hl-], a

        ;How do we handle this information?
        relpointer_move ENTVAR_CITIZEN_TYPE
        ld a, [hl]
        cp a, CITIZEN_TYPE_BOUNCE
        jr nz, .no_bounce
            
            ;Bouncy goes BOING!
            relpointer_push ENTVAR_CITIZEN_YSPEED, 0
            ld a, [hl]
            cpl
            inc a
            ld [hl+], a
            ld a, [hl]
            jr nz, :+
                dec a
            :
            cpl
            ld [hl-], a
            jr .return
            relpointer_pop 0

        ;Just Enter grounded state
        .no_bounce
        cp a, CITIZEN_TYPE_SKIP
        jr z, .no_run
            
            ;PC speedup
            ld e, l
            relpointer_push ENTVAR_CITIZEN_XSPEED, 0
            xor a ;clear carry flag
            rl [hl]
            inc l
            rl [hl]
            relpointer_pop 0
            ld l, e
        ;

        .no_run
        relpointer_move ENTVAR_CITIZEN_STATE
        ld [hl], CITIZEN_STATE_GROUNDED
        relpointer_move ENTVAR_CITIZEN_TIMER
        ld [hl], 0
    ;

    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
citizen_grounded:
    push hl
    call citizen_move_platform

    ;What do we do from here?
    entsys_relpointer_init ENTVAR_CITIZEN_TYPE
    ld a, [hl]
    cp a, CITIZEN_TYPE_SKIP
    jr nz, .no_skip

        ;Absolutely do NOT animate
        relpointer_push ENTVAR_CITIZEN_ANIMATE, 0
        ld [hl], 0

        ;Tick timer
        relpointer_move ENTVAR_CITIZEN_TIMER
        inc [hl]
        ld a, [hl]
        cp a, CITIZEN_SKIP_TIME
        jr c, .return

        ;Alright, back to jumpin'
        relpointer_move ENTVAR_CITIZEN_STATE
        ld [hl], CITIZEN_STATE_AIRBORNE

        ;Reverse Y-speed
        relpointer_move ENTVAR_CITIZEN_YSPEED
        ld a, [hl]
        cpl
        inc a
        ld [hl+], a
        ld a, [hl]
        jr nz, :+
            dec a
        :
        cpl
        ld [hl-], a

        ;Return
        jr .return
        relpointer_pop 0
    .no_skip

    ;Do I have to do the silly little thing where it stops and goes?
    cp a, CITIZEN_TYPE_CAREFUL
    jr nz, .no_careful

        ;Lower speed
        ld e, l
        relpointer_push ENTVAR_CITIZEN_XSPEED, 0
        ld a, [hl]
        sub a, low(CITIZEN_XSPEED_FRICTION)
        ld [hl+], a
        ld a, [hl]
        sbc a, high(CITIZEN_XSPEED_FRICTION)
        ld [hl-], a

        ;did we lower it TOO much?
        jr nc, .not_under
            ld a, low(CITIZEN_XSPEED_CAREFUL)
            ld [hl+], a
            ld a, high(CITIZEN_XSPEED_CAREFUL)
            ld [hl-], a
        .not_under

        relpointer_pop 0
        ld l, e
    .no_careful

    ;Get X-speed -> BC
    relpointer_move ENTVAR_CITIZEN_XSPEED
    ld a, [hl+]
    ld c, a
    ld a, [hl-]
    ld b, a

    ;Update X-position -> DE
    relpointer_move ENTVAR_XPOS
    ld a, [hl]
    add a, c
    ld [hl+], a
    ld e, a
    ld a, [hl]
    adc a, b
    ld [hl-], a
    ld d, a

    ;Update animation
    xor a
    rl c
    rl b
    rl c
    rl b
    rl b
    relpointer_move ENTVAR_CITIZEN_ANIMATE
    ld a, [hl]
    add a, b
    ld [hl], a

    ;Are we going off the platform?
    ld a, [w_platform_xpos+1]
    cp a, d
    jr nc, .return

        ;Yup, start fallin'
        relpointer_move ENTVAR_CITIZEN_STATE
        ld [hl], CITIZEN_STATE_AIRBORNE
        relpointer_move ENTVAR_CITIZEN_YSPEED
        xor a
        ld [hl+], a
        ld [hl-], a
    ;

    .return
    relpointer_destroy
    pop hl
    ret
;



; Move citizen with platform.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `bc`, `de`, `hl`
citizen_move_platform:
    push hl

    ;Set Y-position to platform position
    entsys_relpointer_init ENTVAR_YPOS
    xor a
    ld [hl+], a
    ld a, [w_platform_ypos+1]
    ld [hl-], a

    ;Add platform speed to my speed
    relpointer_move ENTVAR_XPOS
    ld a, [w_platform_xspeed]
    add a, [hl]
    ld [hl+], a
    ld a, [w_platform_xspeed+1]
    adc a, [hl]
    ld [hl-], a

    ;We done
    relpointer_destroy
    pop hl
    ret
;



; Drawing routine for citizens.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
citizen_draw:
    push hl

    ;Don't draw maybe?
    entsys_relpointer_init ENTVAR_CITIZEN_STUN
    ld a, [hl]
    and a, %00000110
    cp a, %00000110
    jr z, .return

    ;Get animation frame -> C
    relpointer_move ENTVAR_CITIZEN_SPRITE
    ld b, [hl]
    relpointer_move ENTVAR_CITIZEN_ANIMATE
    bit 5, [hl]
    jr z, :+
        set 2, b
    :
    ld a, [w_citizen_sprite]
    add a, b
    ld c, a

    ;Get X/Y-position -> DE
    relpointer_move ENTVAR_XPOS+1
    ld a, [w_camera_xpos+1]
    cpl
    add a, [hl]
    add a, 4
    ld d, a
    relpointer_move ENTVAR_YPOS+1
    ld e, [hl]

    ;Allocate sprites
    relpointer_destroy
    ldh a, [h_oam_active]
    ld h, a
    ld b, 8
    call sprite_get

    ;Start writing data
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld a, c
    ld [hl+], a
    xor a
    ld [hl+], a
    ld a, e
    ld [hl+], a
    ld a, d
    add a, 8
    ld [hl+], a
    ld a, c
    add a, 2
    ld [hl+], a
    xor a
    ld [hl+], a

    .return
    pop hl
    ret
;
