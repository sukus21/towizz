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
    ld bc, .return
    push bc

    ;State machine nonsense
    cp a, PAJAMAMAN_STATE_SIT
    jp z, pajamaman_sit
    cp a, PAJAMAMAN_STATE_TAKEOFF
    jp z, pajamaman_takeoff

    ;Unknown state
    ld hl, error_invst_pjamaman
    rst v_error

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
        ld a, low(PAJAMAMAN_YSPEED_TAKEOFF)
        ld [hl+], a
        ld a, high(PAJAMAMAN_YSPEED_TAKEOFF)
        ld [hl-], a
    .no_fly

    ;My job here is done
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
    ld c, [hl]

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

    ;I don't know?
    jr .return

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
