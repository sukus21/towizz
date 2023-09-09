INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/farcall.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/pajamaman.inc"

SECTION "ENTITY PAJAMAMAN", ROMX

; Pajamaman tileset.
pajamaman_tls: INCBIN "graphics/enemy_pajamaman.tls"
.end



; Queues up pajamaman sprites.
; Sets writeback to `w_vqueue_writeback`.
entity_pajamaman_load::
    ld b, 2
    call tower_sprite_alloc
    ld a, b
    ld [w_pajamaman_sprite], a
    vqueue_add_copy \
        VQUEUE_TYPE_DIRECT, \
        de, \
        pajamaman_tls
    ;

    ;Set writeback
    ld a, low(w_vqueue_writeback)
    ld [hl+], a
    ld [hl], high(w_vqueue_writeback)

    ;Return
    ret
;



; Create a new pajamaman entity.
;
; Input:
; - `b`: X-position
; - `c`: Y-position
;
; Returns:
; - `hl`: Entity pointer
;
; Destroys: all
entity_pajamaman_create::
    ld hl, w_pajamaman_count
    inc [hl]

    ;Allocate entity
    push bc
    entsys_new 32, entity_pajamaman, PAJAMAMAN_FLAGS
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
    ld [hl], PAJAMAMAN_HEIGHT
    relpointer_move ENTVAR_WIDTH
    ld [hl], PAJAMAMAN_WIDTH

    ;Set state and flags
    relpointer_move ENTVAR_PAJAMAMAN_STATE
    ld [hl], PAJAMAMAN_STATE_SIT
    relpointer_move ENTVAR_PAJAMAMAN_FLAGS
    ld [hl], PAJAMAMAN_FLAGF_FACING

    ;Reset speeds
    relpointer_move ENTVAR_PAJAMAMAN_XSPEED
    ld e, l
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ld l, e

    ;Set timers
    relpointer_move ENTVAR_PAJAMAMAN_TIMER1
    xor a
    ld [hl+], a
    ld [hl-], a

    ;Set health and stun
    relpointer_move ENTVAR_PAJAMAMAN_HEALTH
    ld [hl], PAJAMAMAN_HEALTH
    relpointer_move ENTVAR_PAJAMAMAN_STUN
    ld [hl], 0

    ;Ok, we are gucci
    relpointer_move ENTVAR_BANK
    relpointer_destroy
    ret
;



; Pajamaman step function.
;
; Input:
; - `de`: Entity pointer
entity_pajamaman:
    ld h, d
    ld l, e

    ;Do some crazy stuff
    call pajamaman_update
    call pajamaman_draw

    ;Return
    ret
;



; Call when pajamaman is defeated/flies off.
; Does NOT return, exits entity code execution entirely.
;
; Input:
; - `b`: Death effects (0 = no)
; - `hl`: Entity pointer (anywhere)
pajamaman_destroy:
    entsys_relpointer_init 0

    ;Spawn death effects + coin(s)
    ld a, b
    or a, a ;cp a, 0
    jr z, .no_effects
        relpointer_push ENTVAR_XPOS+1
        ld b, [hl]
        relpointer_move ENTVAR_YPOS+1
        ld c, [hl]

        ;Create smoke particle
        farcall_x entity_particle_create

        ;Create coin(s)
        ld a, b
        add a, ((PAJAMAMAN_WIDTH - 8) / 2)
        ld b, a
        farcall_x entity_coin_create
        farcall_x entity_coin_create

        ;Alrighty
        relpointer_pop
    .no_effects

    ;Free the entity
    call entsys_free

    ;Decrement entity count
    ld hl, w_pajamaman_count
    dec [hl]

    ;Exit
    relpointer_destroy
    jp entsys_exit
;



; Main update function for pajamaman.
;
; Input:
; - `hl`: Entity pointer (0)
;
; Saves: `hl`
pajamaman_update:
    push hl
    relpointer_init l

    ;Increment animate
    relpointer_move ENTVAR_PAJAMAMAN_ANIMATE
    inc [hl]

    ;Decrement stun (maybe)
    relpointer_move ENTVAR_PAJAMAMAN_STUN
    ld a, [hl]
    or a, a
    jr z, :+
        dec [hl]
    :

    ;Prepare state-machine1
    relpointer_move ENTVAR_PAJAMAMAN_STATE
    ld a, [hl]
    ld bc, .poststate
    push bc

    ;State machine nonsense
    cp a, PAJAMAMAN_STATE_SIT
    jp z, pajamaman_sit
    cp a, PAJAMAMAN_STATE_TAKEOFF
    jp z, pajamaman_takeoff
    cp a, PAJAMAMAN_STATE_FLY
    jp z, pajamaman_fly
    cp a, PAJAMAMAN_STATE_OFFSCREEN
    jp z, pajamaman_offscreen
    cp a, PAJAMAMAN_STATE_WARNING
    jp z, pajamaman_warning
    cp a, PAJAMAMAN_STATE_LAND
    jp z, pajamaman_land
    cp a, PAJAMAMAN_STATE_TIRED
    jp z, pajamaman_tired

    ;Unknown state
    ld hl, error_invst_pjamaman
    rst v_error

    ;Take damage?
    .poststate
    relpointer_move ENTVAR_FLAGS
    bit ENTSYS_FLAGB_COLLISION, [hl]
    jr z, .return

    ;Take damage indeed.
    push hl
    ld c, ENTSYS_FLAGF_COLLISION | ENTSYS_FLAGF_DAMAGE
    call entsys_collision_all
    ld a, bank(@)
    call nz, entsys_do_dmgcall
    pop hl
    jr z, .no_damage
        
        ;Deal damage, maybe even destroy
        relpointer_move ENTVAR_PAJAMAMAN_HEALTH
        dec [hl]
        ld b, h ;non-zero
        jp z, pajamaman_destroy

        ;Set stun
        relpointer_move ENTVAR_PAJAMAMAN_STUN
        ld [hl], PAJAMAMAN_STUN_TIME

        ;Should we slow speed?
        relpointer_move ENTVAR_PAJAMAMAN_STATE
        ld a, [hl]
        cp a, PAJAMAMAN_STATE_FLY
        jr nz, .no_damage

        ;Get desired X-speed -> DE
        relpointer_move ENTVAR_PAJAMAMAN_FLAGS
        ld de, PAJAMAMAN_XSPEED_SLOWED
        bit PAJAMAMAN_FLAGB_FACING, [hl]
        jr z, :+
            ld de, -PAJAMAMAN_XSPEED_SLOWED
        :

        ;Slow X-speed
        relpointer_move ENTVAR_PAJAMAMAN_XSPEED
        ld a, e
        ld [hl+], a
        ld a, d
        ld [hl-], a
    .no_damage

    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
pajamaman_sit:
    push hl
    entsys_relpointer_init ENTVAR_PAJAMAMAN_TIMER1

    ;Stay on platform
    call pajamaman_move_platform

    ;Tick tha timers
    inc [hl]
    jr nz, .no_force
        ld e, l
        relpointer_push ENTVAR_PAJAMAMAN_TIMER2, 0
        inc [hl]
        ld a, [hl]
        cp a, PAJAMAMAN_SIT_TIME
        jr c, .skip_force

            ;Alrighty, force hero-guy to fly off
            .takeoff
            relpointer_move ENTVAR_PAJAMAMAN_STATE
            ld [hl], PAJAMAMAN_STATE_TAKEOFF
            relpointer_move ENTVAR_PAJAMAMAN_TIMER1
            xor a
            ld [hl+], a
            ld [hl-], a

            ;Face away from tower
            relpointer_move ENTVAR_PAJAMAMAN_FLAGS
            res PAJAMAMAN_FLAGB_FACING, [hl]

            ;Now what
            jr .return

        .skip_force
        relpointer_pop 0
        ld l, e
    .no_force

    ;Prepare collision buffer
    relpointer_move ENTVAR_XPOS+1
    ld a, [hl]
    sub a, PAJAMAMAN_FLEE_RANGE
    ldh [h_colbuf1+0], a
    add a, PAJAMAMAN_FLEE_RANGE*2 + PAJAMAMAN_WIDTH
    ldh [h_colbuf1+1], a
    relpointer_move ENTVAR_YPOS+1
    ld a, [hl]
    ldh [h_colbuf1+3], a
    sub a, PAJAMAMAN_HEIGHT*2
    ldh [h_colbuf1+2], a

    ;Find dangerous entity
    relpointer_move ENTVAR_PAJAMAMAN_TIMER2
    push hl
    ld c, ENTSYS_FLAGF_PLAYER | ENTSYS_FLAGF_DAMAGE
    call entsys_collision_any.prepared
    pop hl
    jr nz, .takeoff

    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
pajamaman_takeoff:
    push hl
    call pajamaman_move_platform

    ;Tick timer
    entsys_relpointer_init ENTVAR_PAJAMAMAN_TIMER1
    inc [hl]
    ld a, [hl]
    cp a, PAJAMAMAN_TAKEOFF_TIME
    jr c, .no_fly

        ;Start flyin'
        relpointer_move ENTVAR_PAJAMAMAN_STATE
        ld [hl], PAJAMAMAN_STATE_FLY

        ;Set new X-speed
        relpointer_move ENTVAR_PAJAMAMAN_XSPEED
        ld a, low(PAJAMAMAN_XSPEED_FLY)
        ld [hl+], a
        ld a, high(PAJAMAMAN_XSPEED_FLY)
        ld [hl-], a

        ;Set new Y-speed
        relpointer_move ENTVAR_PAJAMAMAN_YSPEED
        ld a, low(-PAJAMAMAN_YSPEED_TAKEOFF)
        ld [hl+], a
        ld a, high(-PAJAMAMAN_YSPEED_TAKEOFF)
        ld [hl-], a
    .no_fly

    ;My job here is done
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
pajamaman_fly:
    push hl
    push hl

    ;Find a player
    ld c, ENTSYS_FLAGF_PLAYER | ENTSYS_FLAGF_COLLISION
    call entsys_find_all
    jr nz, :+
        pop hl
        jr .speed_modified
    :

    ;Grab player Y-position -> C
    relpointer_init l
    relpointer_move ENTVAR_YPOS+1
    ld c, [hl]
    relpointer_destroy

    ;Compare with my Y-position
    pop hl
    entsys_relpointer_init ENTVAR_YPOS+1
    ld b, [hl]
    relpointer_move ENTVAR_PAJAMAMAN_YSPEED
    ld a, b
    cp a, c
    jr c, :+
        ld a, [hl]
        sub a, low(PAJAMAMAN_YSPEED_ADJUST)
        ld [hl+], a
        ld a, [hl]
        sbc a, high(PAJAMAMAN_YSPEED_ADJUST)
        ld [hl-], a
        jr .speed_modified
    :
        ld a, [hl]
        add a, low(PAJAMAMAN_YSPEED_ADJUST)
        ld [hl+], a
        ld a, [hl]
        adc a, high(PAJAMAMAN_YSPEED_ADJUST)
        ld [hl-], a
    .speed_modified

    ;Get X-speed addition -> DE & BC
    relpointer_move ENTVAR_PAJAMAMAN_FLAGS
    ld b, [hl]
    ld de, PAJAMAMAN_XSPEED_ACCEL
    bit PAJAMAMAN_FLAGB_FACING, b
    jr z, :+
        ld de, -PAJAMAMAN_XSPEED_ACCEL
    :

    ;Add to X-speed
    relpointer_move ENTVAR_PAJAMAMAN_XSPEED
    ld a, [hl+]
    add a, e
    ld e, a
    ld a, [hl-]
    adc a, d
    ld d, a

    ;Is this above the speed limit?
    bit PAJAMAMAN_FLAGB_FACING, b
    jr z, :+
        ld a, d
        cp a, high(-PAJAMAMAN_XSPEED_FLY)
        jr c, .cap_speed
        ld a, e
        cp a, low(-PAJAMAMAN_XSPEED_FLY)
        jr c, .cap_speed
        jr .save_speed
    :
        ld a, d
        cp a, high(PAJAMAMAN_XSPEED_FLY)
        jr c, .save_speed
        ld a, e
        cp a, e
        cp a, low(PAJAMAMAN_XSPEED_FLY)
        jr c, .save_speed
    ;

    .cap_speed
    ld de, PAJAMAMAN_XSPEED_FLY
    bit PAJAMAMAN_FLAGB_FACING, b
    jr z, :+
        ld de, -PAJAMAMAN_XSPEED_FLY
    :

    .save_speed
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl-], a
    
    ;Schmooves
    call pajamaman_move_speed

    ;Go offscreen?
    relpointer_move ENTVAR_PAJAMAMAN_FLAGS
    ld b, [hl]
    relpointer_move ENTVAR_XPOS+1
    bit PAJAMAMAN_FLAGB_FACING, b
    ld a, [w_camera_xpos+1]
    jr z, :+
        sub a, 16
        cp a, [hl]
        jr c, .return
        jr .offscreen
    :
        add a, SCRN_X
        cp a, [hl]
        jr nc, .return
    ;

    ;Make buddy go off-screen
    .offscreen
        relpointer_move ENTVAR_PAJAMAMAN_STATE
        ld [hl], PAJAMAMAN_STATE_OFFSCREEN
        relpointer_move ENTVAR_FLAGS
        ld [hl], 0
        
        ;Reset timer
        relpointer_move ENTVAR_PAJAMAMAN_TIMER1
        xor a
        ld [hl+], a
        inc [hl]
        ld a, [hl-]
        ld b, a

        ;Start landing?
        call rng_run_single
        and a, %00000111
        add a, 2
        cp a, b
        jr nc, .return
    ;

    ;Start landing sequence
    .landing

        ;Sometimes we just vanish
        call rng_run_single
        ld d, a
        and a, %11000000
        ld b, 0
        jp z, pajamaman_destroy
        
        ;Nevermind, don't clear flags anyway
        relpointer_move ENTVAR_FLAGS
        ld [hl], PAJAMAMAN_FLAGS

        ;Get landing position -> B
        ld a, d
        and a, %00011111
        ld b, a
        ld a, [w_platform_xpos+1]
        sub a, PAJAMAMAN_WIDTH
        sub a, b
        ld b, a

        ;Set positions
        relpointer_move ENTVAR_YPOS
        xor a
        ld [hl+], a
        ld [hl-], a
        relpointer_move ENTVAR_XPOS+1
        ld [hl], b

        ;Set state
        relpointer_move ENTVAR_PAJAMAMAN_STATE
        ld [hl], PAJAMAMAN_STATE_LAND

        ;Set speeds
        relpointer_move ENTVAR_PAJAMAMAN_XSPEED
        xor a
        ld [hl+], a
        ld [hl-], a
        relpointer_move ENTVAR_PAJAMAMAN_YSPEED
        ld a, low(PAJAMAMAN_YSPEED_FALL)
        ld [hl+], a
        ld a, high(PAJAMAMAN_YSPEED_FALL)
        ld [hl-], a
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
pajamaman_offscreen:
    push hl
    entsys_relpointer_init ENTVAR_PAJAMAMAN_TIMER1
    inc [hl]
    ld a, [hl]
    cp a, PAJAMAMAN_OFFSCREEN_TIME
    jr c, .return

        ;Reset timer
        ld [hl], 0

        ;Find player to target
        relpointer_move ENTVAR_YPOS
        relpointer_push ENTVAR_YPOS, 0
        ld d, h
        ld e, l
        ld c, ENTSYS_FLAGF_PLAYER
        call entsys_find_all
        jr z, .return
        relpointer_set 0
        relpointer_move ENTVAR_YPOS+1
        ld c, [hl]

        ;Move to that position
        relpointer_pop 0
        ld h, d
        ld l, e
        xor a
        ld [hl+], a
        ld a, c
        ld [hl-], a

        ;Flip direction
        relpointer_move ENTVAR_PAJAMAMAN_FLAGS
        ld a, [hl]
        xor a, PAJAMAMAN_FLAGF_FACING
        ld [hl], a

        ;Reset Y-speed
        relpointer_move ENTVAR_PAJAMAMAN_YSPEED
        ld a, low(PAJAMAMAN_YSPEED_SWOOP)
        ld [hl+], a
        ld a, high(PAJAMAMAN_YSPEED_SWOOP)
        ld [hl-], a

        ;Reset animation counter
        relpointer_move ENTVAR_PAJAMAMAN_ANIMATE
        ld [hl], 0

        ;Change state
        relpointer_move ENTVAR_PAJAMAMAN_STATE
        ld [hl], PAJAMAMAN_STATE_WARNING
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
pajamaman_warning:
    push hl
    entsys_relpointer_init ENTVAR_PAJAMAMAN_TIMER1
    inc [hl]
    ld a, [hl]
    cp a, PAJAMAMAN_WARNING_TIME
    jr c, .return

        ;Restore flags
        relpointer_move ENTVAR_FLAGS
        ld [hl], PAJAMAMAN_FLAGS

        ;Get X-position -> B
        relpointer_move ENTVAR_PAJAMAMAN_FLAGS
        ld a, [w_camera_xpos+1]
        sub a, PAJAMAMAN_WIDTH
        ld c, [hl]
        bit PAJAMAMAN_FLAGB_FACING, c
        jr z, :+
            add a, SCRN_X + PAJAMAMAN_WIDTH
        :
        ld b, a

        ;Set X-position
        relpointer_move ENTVAR_XPOS+1
        ld [hl], b

        ;Set state
        relpointer_move ENTVAR_PAJAMAMAN_STATE
        ld [hl], PAJAMAMAN_STATE_FLY

        ;Set X-speed
        relpointer_move ENTVAR_PAJAMAMAN_XSPEED
        bit PAJAMAMAN_FLAGB_FACING, c
        ld de, PAJAMAMAN_XSPEED_FLY
        jr z, :+
            ld de, -PAJAMAMAN_XSPEED_FLY
        :
        ld a, e
        ld [hl+], a
        ld a, d
        ld [hl-], a
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
pajamaman_land:
    push hl
    call pajamaman_move_speed

    ;Are we on the ground yet?
    entsys_relpointer_init ENTVAR_YPOS+1
    ld a, [w_platform_ypos+1]
    cp a, [hl]
    jr nc, .return
        ld [hl], a

        ;Yes we are, switch state!
        relpointer_move ENTVAR_PAJAMAMAN_STATE
        ld [hl], PAJAMAMAN_STATE_TIRED

        ;Reset animation and timer
        relpointer_move ENTVAR_PAJAMAMAN_TIMER1
        ld [hl], 0
        relpointer_move ENTVAR_PAJAMAMAN_ANIMATE
        ld [hl], 0
    ;

    ;Return
    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
pajamaman_tired:
    push hl
    call pajamaman_move_platform

    ;Face away in shame
    entsys_relpointer_init ENTVAR_PAJAMAMAN_FLAGS
    ld [hl], 0

    ;Wait out the timer
    relpointer_move ENTVAR_PAJAMAMAN_TIMER1
    inc [hl]
    ld a, [hl]
    cp a, PAJAMAMAN_TIRED_TIME
    jr c, .return

        ;Go back to sitting state
        xor a
        ld [hl+], a
        ld [hl-], a
        relpointer_move ENTVAR_PAJAMAMAN_STATE
        ld [hl], PAJAMAMAN_STATE_SIT

        ;Face the tower
        relpointer_move ENTVAR_PAJAMAMAN_FLAGS
        ld [hl], PAJAMAMAN_FLAGF_FACING
    ;

    .return
    relpointer_destroy
    pop hl
    ret
;



; Move pajamaman with platform.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
pajamaman_move_platform:
    push hl

    ;Do Y-position first (because it is easy)
    entsys_relpointer_init ENTVAR_YPOS
    xor a
    ld [hl+], a
    ld a, [w_platform_ypos+1]
    ld [hl-], a

    ;Now do X-position
    relpointer_move ENTVAR_XPOS
    ld a, [w_platform_xspeed]
    add a, [hl]
    ld [hl+], a
    ld a, [w_platform_xspeed+1]
    adc a, [hl]
    ld [hl-], a

    ;Wow really, that was it?
    relpointer_destroy
    pop hl
    ret
;



; Move pajamaman according to speed variables.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
pajamaman_move_speed:
    push hl

    ;X-speed -> DE
    entsys_relpointer_init ENTVAR_PAJAMAMAN_XSPEED
    ld a, [hl+]
    ld e, a
    ld a, [hl-]
    ld d, a

    ;Y-speed -> BC
    relpointer_move ENTVAR_PAJAMAMAN_YSPEED
    ld a, [hl+]
    ld c, a
    ld a, [hl-]
    ld b, a

    ;Apply X-speed
    relpointer_move ENTVAR_XPOS
    ld a, e
    add a, [hl]
    ld [hl+], a
    ld a, d
    adc a, [hl]
    ld [hl-], a

    ;Apply Y-speed
    relpointer_move ENTVAR_YPOS
    ld a, c
    add a, [hl]
    ld [hl+], a
    ld a, b
    adc a, [hl]
    ld [hl-], a

    ;Yup, we are done now
    relpointer_destroy
    pop hl
    ret
;



; Draw call for pajamaman enemy.
;
; Input:
; - `hl`: Entity pointer (0)
;
; Saves: `hl`
pajamaman_draw:
    push hl
    relpointer_init l

    ;Don't draw if stun thing
    relpointer_move ENTVAR_PAJAMAMAN_STUN
    ld a, [hl]
    and a, %00000110
    cp a, %00000110
    jr nz, :+
        pop hl
        ret
    :

    ;Flags -> B
    relpointer_move ENTVAR_PAJAMAMAN_FLAGS
    ld a, [hl]
    ld b, 0
    bit PAJAMAMAN_FLAGB_FACING, a
    jr z, :+
        ld b, OAMF_XFLIP
    :

    ;X/Y-position -> stack
    relpointer_move ENTVAR_XPOS+1
    ld a, [w_camera_xpos+1]
    cpl
    add a, [hl]
    add a, 9
    bit OAMB_XFLIP, b
    jr nz, :+
        add a, 8
    :
    ld d, a
    relpointer_move ENTVAR_YPOS+1
    ld e, [hl]
    push de

    ;Flags -> E
    ld e, b

    ;Animate var -> D
    relpointer_move ENTVAR_PAJAMAMAN_ANIMATE
    ld d, [hl]

    ;State -> C
    relpointer_move ENTVAR_PAJAMAMAN_STATE
    ld a, [hl]
    cp a, PAJAMAMAN_STATE_OFFSCREEN
    jr z, .early
    cp a, PAJAMAMAN_STATE_WARNING
    jr nz, :+
        bit 4, d
        jr nz, :+
        .early
        pop hl
        pop hl
        ret
    :
    ld c, a

    ;Get sprites
    relpointer_destroy
    ld b, 4*2
    ldh a, [h_oam_active]
    ld h, a
    call sprite_get

    ;Switch by state
    ld a, c
    pop bc
    cp a, PAJAMAMAN_STATE_SIT
    jr z, .sit
    cp a, PAJAMAMAN_STATE_FLY
    jr z, .fly
    cp a, PAJAMAMAN_STATE_LAND
    jr z, .land
    cp a, PAJAMAMAN_STATE_TAKEOFF
    jr z, .takeoff
    cp a, PAJAMAMAN_STATE_TIRED
    jr z, .tired
    cp a, PAJAMAMAN_STATE_WARNING
    jr z, .warning

    ;I don't know?
    pop hl
    ret

    .sit
        ld a, PAJAMAMAN_SPRITE_IDLE
        jr .capeflash

    .fly
        ld a, PAJAMAMAN_SPRITE_FLY
        jr .capeflash

    .land
        ld a, PAJAMAMAN_SPRITE_LAND
        jr .capeflash

    .takeoff
        ld d, PAJAMAMAN_SPRITE_TAKEOFF
        jr .straight

    .tired
        bit 4, d
        jr z, :+
            ld d, PAJAMAMAN_SPRITE_INHALE
            jr .straight
        :
        ld d, PAJAMAMAN_SPRITE_EXHALE
        jr .straight
    
    .warning
        ld b, $08
        bit OAMB_XFLIP, e
        jr z, :+
            ld b, SCRN_X-16
        :
        ld a, [w_pajamaman_sprite]
        add a, PAJAMAMAN_SPRITE_WARNING
        ld e, a
        
        ;Write sprite
        ld a, c
        ld [hl+], a
        ld a, b
        ld [hl+], a
        ld a, e
        ld [hl+], a
        xor a
        ld [hl+], a
        ld a, c
        ld [hl+], a
        ld a, b
        add a, 8
        ld [hl+], a
        ld a, e
        ld [hl+], a
        ld [hl], OAMF_XFLIP
        jr .return
    ;

    .capeflash
        ld [hl], c
        inc l
        ld [hl], b
        inc l
        ld [hl], a
        ld a, [w_pajamaman_sprite]
        add a, [hl]
        ld [hl+], a
        ld [hl], e
        inc l
        ld [hl], c
        inc l

        ;Second X-position
        ld c, a
        ld a, b
        add a, 8
        bit OAMB_XFLIP, e
        jr nz, :+
            sub a, 16
        :
        ld [hl+], a

        ;Second tile ID
        inc c
        inc c
        bit 3, d
        jr z, :+
            ld a, c
            sub a, 4
            ld c, a
        :
        ld [hl], c
        inc l
        ld [hl], e
        jr .return

    .straight
        ld a, [w_pajamaman_sprite]
        add a, d
        add a, 2
        ld d, a

        ld a, c
        ld [hl+], a
        ld a, b
        ld [hl+], a
        add a, 8
        bit OAMB_XFLIP, e
        jr nz, :+
            sub a, 16
        :
        ld b, a
        ld a, d
        ld [hl+], a
        ld a, e
        ld [hl+], a

        ld a, c
        ld [hl+], a
        ld a, b
        ld [hl+], a
        ld a, d
        sub a, 2
        ld [hl+], a
        ld [hl], e

        jr .return
    ;

    .return
    pop hl
    ret
;
