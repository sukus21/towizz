INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/farcall.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/knightling.inc"

SECTION "ENTITY KNIGHTLING", ROMX

; Knightling tileset.
knightling_tls: INCBIN "graphics/enemy_knightling.tls"
.end



; Queues up knightling sprites.
; Sets writeback to `w_vqueue_writeback`.
entity_knightling_load::
    ld b, 1
    call tower_sprite_alloc
    ld a, b
    ld [w_knightling_sprite], a
    vqueue_add_copy \
        VQUEUE_TYPE_DIRECT, \
        de, \
        knightling_tls
    ;

    ;Set writeback
    ld a, low(w_vqueue_writeback)
    ld [hl+], a
    ld [hl], high(w_vqueue_writeback)

    ;Return
    ret
;



; Create a new knightling entity.
;
; Input:
; - `b`: X-position
; - `c`: Y-position
;
; Returns:
; - `hl`: Entity pointer
;
; Destroys: all
entity_knightling_create::
    ld hl, w_knightling_count
    inc [hl]

    ;Allocate entity
    push bc
    entsys_new 32, entity_knightling, KNIGHTLING_FLAGS
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
    ld [hl], KNIGHTLING_HEIGHT
    relpointer_move ENTVAR_WIDTH
    ld [hl], KNIGHTLING_WIDTH

    ;Set state and flags
    relpointer_move ENTVAR_KNIGHTLING_STATE
    ld [hl], KNIGHTLING_STATE_WALK
    relpointer_move ENTVAR_KNIGHTLING_FLAGS
    ld [hl], 0

    ;Reset speeds
    relpointer_move ENTVAR_KNIGHTLING_XSPEED
    xor a
    ld [hl+], a
    ld [hl-], a

    ;Set health and stun
    relpointer_move ENTVAR_KNIGHTLING_HEALTH
    ld [hl], KNIGHTLING_HEALTH
    relpointer_move ENTVAR_KNIGHTLING_STUN
    ld [hl], 0

    ;Ok, we are gucci
    relpointer_move ENTVAR_BANK
    relpointer_destroy
    ret
;



; Knightling step function.
;
; Input:
; - `de`: Entity pointer
entity_knightling:
    ld h, d
    ld l, e

    ;Do some crazy stuff
    call knightling_update
    call knightling_draw

    ;Return
    ret
;



; Main update function for knightlings.
;
; Input:
; - `hl`: Knightling entity pointer (0)
;
; Saves: `hl`
knightling_update:
    push hl
    relpointer_init l

    ;How to handle vertical movement?
    relpointer_move ENTVAR_KNIGHTLING_STATE
    ld a, [hl]
    cp a, KNIGHTLING_STATE_WAIT
    jr z, .return
    cp a, KNIGHTLING_STATE_FALLING
    call nz, knightling_speed_stand
    call z, knightling_speed_fall

    ;Ok, now go into the state machine
    ld bc, .poststate
    push bc
    ld a, [hl]
    cp a, KNIGHTLING_STATE_WALK
    jp z, knightling_walk
    cp a, KNIGHTLING_STATE_TURNAROUND
    jp z, knightling_turnaround
    cp a, KNIGHTLING_STATE_FIGHT
    jp z, knightling_fight
    cp a, KNIGHTLING_STATE_ATTACK
    jp z, knightling_attack
    cp a, KNIGHTLING_STATE_FALLING
    jp z, knightling_fall

    ;Unknow state
    ld hl, error_invst_knightln
    rst v_error

    ;Take damage?
    .poststate
    relpointer_move ENTVAR_XPOS+1
    push hl
    ld c, ENTSYS_FLAGF_COLLISION | ENTSYS_FLAGF_DAMAGE
    call entsys_find_collision
    ld a, bank(@)
    call nz, entsys_do_dmgcall
    pop hl
    jr z, .no_damage
        
        ;Deal damage, maybe even destroy
        relpointer_push ENTVAR_KNIGHTLING_HEALTH
        dec [hl]
        ld b, h ;non-zero
        jp z, knightling_destroy

        ;No more speed?
        relpointer_move ENTVAR_KNIGHTLING_STATE
        ld a, [hl]
        cp a, KNIGHTLING_STATE_WALK
        jr nz, :+
            ld e, l
            relpointer_push ENTVAR_KNIGHTLING_XSPEED, 0
            ld [hl], 0
            relpointer_pop 0
            ld l, e
        :

        ;Set stun
        relpointer_move ENTVAR_KNIGHTLING_STUN
        ld [hl], KNIGHTLING_STUN_TIME
        relpointer_pop
    .no_damage

    ;Decrement stun (maybe)
    relpointer_move ENTVAR_KNIGHTLING_STUN
    ld a, [hl]
    or a, a
    jr z, :+
        dec [hl]
    :

    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
knightling_walk:
    push hl
    entsys_relpointer_init ENTVAR_KNIGHTLING_FLAGS
    ld b, [hl]
    relpointer_move ENTVAR_KNIGHTLING_STUN
    ld c, [hl]
    relpointer_move ENTVAR_KNIGHTLING_XSPEED

    ;Stop if stunned (briefly)
    ld a, c
    cp a, KNIGHTLING_STUN_PERIOD
    ld a, 0
    jr nc, .xspeed_add

    ;Add speed
    bit KNIGHTLING_FLAGB_FACING, b
    ld a, [hl]
    jr z, :+
        dec a
        cp a, -KNIGHTLING_XSPEED_MAX
        jr nc, .xspeed_add
        ld a, -KNIGHTLING_XSPEED_MAX
        jr .xspeed_add
    :
        inc a
        cp a, KNIGHTLING_XSPEED_MAX
        jr c, .xspeed_add
        ld a, KNIGHTLING_XSPEED_MAX
    .xspeed_add
    ld [hl], a
    add a, a
    ld c, a
    relpointer_move ENTVAR_KNIGHTLING_ANIMATE
    ld a, [hl]
    add a, c
    ld [hl], a

    ;Apply speed to X-position
    xor a
    sra c
    rra
    sra c
    rra
    sra c
    rra
    sra c
    rra
    ld e, a
    relpointer_move ENTVAR_XPOS
    ld a, e
    add a, [hl]
    ld [hl+], a
    ld a, c
    adc a, [hl]
    ld [hl-], a
    ld d, a

    ;Get turnaround condition
    bit KNIGHTLING_FLAGB_FACING, b
    jr nz, :+
        ld a, [w_platform_xpos+1]
        sub a, 20
        cp a, d
        jr .turnaround
    :
        ld a, [w_camera_xpos+1]
        cp a, d
        ccf
    .turnaround

    ;So do turnaround?
    jr nc, .no_turnaround

        ;Reset speed and timer
        relpointer_push ENTVAR_KNIGHTLING_XSPEED, 0
        ld [hl], 0
        relpointer_move ENTVAR_KNIGHTLING_TIMER
        ld [hl], 0

        ;Change state
        relpointer_move ENTVAR_KNIGHTLING_STATE
        ld [hl], KNIGHTLING_STATE_TURNAROUND

        relpointer_pop 0
        jr .return
    .no_turnaround

    ;Engage player?
    call knightling_engage
    jr z, .no_engage
        call knightling_face_engaged

        ;Reset speed and timer
        relpointer_push ENTVAR_KNIGHTLING_XSPEED, 0
        ld [hl], 0
        relpointer_move ENTVAR_KNIGHTLING_TIMER
        ld [hl], 0

        ;Change state
        relpointer_move ENTVAR_KNIGHTLING_STATE
        ld [hl], KNIGHTLING_STATE_FIGHT

        relpointer_pop 0
        jr .return
    .no_engage

    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
knightling_turnaround:
    ld e, l
    entsys_relpointer_init ENTVAR_KNIGHTLING_TIMER
    inc [hl]
    ld a, [hl]

    ;Actually do the thing
    cp a, KNIGHTLING_TURNAROUND_STEP*2
    jr nz, :+
        relpointer_push ENTVAR_KNIGHTLING_FLAGS, 0
        ld a, [hl]
        xor a, KNIGHTLING_FLAGF_FACING
        ld [hl], a
        jr .return
        relpointer_pop 0
    :

    ;End state?
    cp a, KNIGHTLING_TURNAROUND_STEP*4
    jr nz, :+
        relpointer_push ENTVAR_KNIGHTLING_STATE, 0
        ld [hl], KNIGHTLING_STATE_WALK
        relpointer_move ENTVAR_KNIGHTLING_XSPEED
        ld [hl], 0
        relpointer_move ENTVAR_KNIGHTLING_ANIMATE
        ld [hl], $C0
        jr .return
        relpointer_pop 0
    :

    .return
    relpointer_destroy
    ld l, e
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
knightling_fight:
    push hl
    entsys_relpointer_init ENTVAR_KNIGHTLING_TIMER
    ld a, [hl]
    cp a, KNIGHTLING_CHARGE_TIME
    jr nc, .no_engage
    call knightling_engage
    jr nz, .engaged

        ;No longer engaged, go back to walking
        relpointer_push ENTVAR_KNIGHTLING_STATE, 0
        ld [hl], KNIGHTLING_STATE_WALK
        relpointer_move ENTVAR_KNIGHTLING_ANIMATE
        ld [hl], $C0
        relpointer_pop 0
        jr .return

    .engaged
    call knightling_face_engaged
    .no_engage

    ;Get flags -> D
    relpointer_move ENTVAR_KNIGHTLING_FLAGS
    ld d, [hl]

    ;Tick down timer
    relpointer_move ENTVAR_KNIGHTLING_TIMER
    inc [hl]
    ld a, [hl]
    cp a, KNIGHTLING_FIGHT_TIME
    jr nz, .no_fight
        ld [hl], 0

        ;Oh yeah, start fightin'
        relpointer_push ENTVAR_KNIGHTLING_STATE, 0
        ld [hl], KNIGHTLING_STATE_ATTACK

        ;Set fight speed
        relpointer_move ENTVAR_KNIGHTLING_XSPEED
        bit KNIGHTLING_FLAGB_FACING, d
        ld [hl], KNIGHTLING_XSPEED_ATTACK
        jr z, :+
            ld [hl], -KNIGHTLING_XSPEED_ATTACK
        :

        ;Reset timer
        relpointer_move ENTVAR_KNIGHTLING_TIMER
        ld [hl], 0
        relpointer_pop 0
        jr .return
    .no_fight

    ;Charge back
    cp a, KNIGHTLING_CHARGE_TIME
    jr c, .no_charge
        ld bc, -(KNIGHTLING_XSPEED_CHARGE << 4)
        bit KNIGHTLING_FLAGB_FACING, d
        jr z, :+
            ld bc, KNIGHTLING_XSPEED_CHARGE << 4
        :

        ;Apply stepback speed
        ld e, l
        relpointer_push ENTVAR_XPOS, 0
        ld a, c
        add a, [hl]
        ld [hl+], a
        ld a, b
        adc a, [hl]
        ld [hl-], a

        ;Yup
        relpointer_pop 0
        ld l, e
    .no_charge

    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
knightling_attack:
    push hl
    entsys_relpointer_init ENTVAR_KNIGHTLING_FLAGS
    ld d, [hl]

    ;Get speed decrease -> B
    relpointer_move ENTVAR_KNIGHTLING_TIMER
    inc [hl]
    ld a, [hl]
    cp a, 1
    ld b, 0
    jr c, :+
        ld [hl], 0
        ld b, $01
        bit KNIGHTLING_FLAGB_FACING, d
        jr z, :+
        ld b, $FF
    :

    ;Get X-speed -> C
    relpointer_move ENTVAR_KNIGHTLING_XSPEED
    ld a, [hl]
    sub a, b
    ld [hl], a
    ld c, a
    jr nz, .no_stop
        relpointer_push ENTVAR_KNIGHTLING_STATE, 0

        ;Stop movin'
        .turnaround
        ld [hl], KNIGHTLING_STATE_TURNAROUND
        relpointer_move ENTVAR_KNIGHTLING_TIMER
        ld [hl], 0
        jr .return
        relpointer_pop 0
    .no_stop

    ;Add to animation
    relpointer_move ENTVAR_KNIGHTLING_ANIMATE
    ld a, c
    add a, [hl]
    ld [hl], a
    
    ;Add X-speed to X-position -> B
    relpointer_move ENTVAR_XPOS
    xor a
    sra c
    rra
    sra c
    rra
    sra c
    rra
    sra c
    rra
    add a, [hl]
    ld [hl+], a
    ld a, c
    adc a, [hl]
    ld [hl-], a
    ld b, a

    ;Move into tower?
    bit KNIGHTLING_FLAGB_FACING, d
    jr z, .no_tower
    ld a, [w_camera_xpos+1]
    cp a, b
    jr c, .no_tower
        relpointer_push ENTVAR_KNIGHTLING_STATE, 0
        jr .turnaround
        relpointer_pop 0
    .no_tower

    ;Move out of platform?
    ld a, [w_platform_xpos+1]
    cp a, b
    jr nc, .no_platform
        relpointer_push ENTVAR_KNIGHTLING_STATE, 0
        ld [hl], KNIGHTLING_STATE_FALLING
        relpointer_move ENTVAR_KNIGHTLING_YSPEED
        ld [hl], 0
        jr .return
        relpointer_pop 0
    .no_platform

    .return
    relpointer_destroy
    pop hl
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
knightling_fall:
    push hl

    ;Get X-speed -> BC
    entsys_relpointer_init ENTVAR_KNIGHTLING_XSPEED
    ld b, [hl]
    xor a
    sra b
    rra
    sra b
    rra
    sra b
    rra
    sra b
    rra
    ld c, a

    ;Add X-speed to position
    relpointer_move ENTVAR_XPOS
    ld a, c
    add a, [hl]
    ld [hl+], a
    ld a, b
    adc a, [hl]
    ld [hl-], a

    ;Now check Y-position
    relpointer_move ENTVAR_YPOS+1
    ld a, [hl]
    cp a, 160
    ld b, 0
    call nc, knightling_destroy

    .return
    relpointer_destroy
    pop hl
    ret
;



; Stand on the platform.
;
; Input:
; - `hl`: Knightling entity pointer (anywhere)
;
; Saves: `af`, `hl`
knightling_speed_stand:
    push af
    push hl
    entsys_relpointer_init ENTVAR_YPOS+1

    ;Stand on platform
    ld a, [w_platform_ypos+1]
    dec a
    ld [hl-], a
    xor a
    ld [hl+], a

    ;Move with platform
    relpointer_move ENTVAR_XPOS
    ld a, [w_platform_xspeed]
    add a, [hl]
    ld [hl+], a
    ld a, [w_platform_xspeed+1]
    adc a, [hl]
    ld [hl-], a

    ;Reset Y-position
    relpointer_move ENTVAR_KNIGHTLING_YSPEED
    ld [hl], 0

    ;Return
    relpointer_destroy
    pop hl
    pop af
    ret
;



; Falling into the abyss.
;
; Input:
; - `hl`: Knightling entity pointer (anywhere)
;
; Saves: `af`, `hl`
knightling_speed_fall:
    push af
    push hl

    ;Add gravity to Y-speed
    entsys_relpointer_init ENTVAR_KNIGHTLING_YSPEED
    ld a, [hl]
    add a, KNIGHTLING_YSPEED_GRAVITY ;I'll just assume this one doesn't overflow...
    ld [hl], a

    ;Elongate to 16-bit
    ld b, a
    xor a
    sra b
    rra
    sra b
    rra
    sra b
    rra
    sra b
    rra
    ld c, a

    ;Move downward
    relpointer_move ENTVAR_YPOS
    ld a, [hl]
    add a, c
    ld [hl+], a
    ld a, [hl]
    adc a, b
    ld [hl-], a

    ;Return
    relpointer_destroy
    pop hl
    pop af
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Returns:
; - `fZ`: Engaged (z = no, nz = yes)
; - `bc`: Engaged entity
;
; Saves: `hl`
knightling_engage:
    push hl
    entsys_relpointer_init ENTVAR_XPOS+1

    ;Get X-positions
    ld a, [hl]
    sub a, KNIGHTLING_ENGAGE_DISTANCE
    ld b, a
    ld a, [hl]
    add a, KNIGHTLING_ENGAGE_DISTANCE + KNIGHTLING_WIDTH
    ld d, a

    ;Get Y-positions
    relpointer_move ENTVAR_YPOS+1
    ld a, [hl]
    sub a, KNIGHTLING_ENGAGE_HEIGHT
    ld c, a
    ld e, [hl]

    ;Write these to buffer
    relpointer_destroy
    ld hl, h_colbuf1
    ld a, b
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ld a, e
    ld [hl+], a

    ;Get player entity
    ld c, ENTSYS_FLAGF_COLLISION | ENTSYS_FLAGF_PLAYER
    call entsys_find
    jr z, .return
    push hl

    .find_player
        ;Get its collision data
        call entsys_collision_prepare2
        call entsys_collision_rr8f
        pop hl
        ld b, h
        ld c, l
        jr nz, .return

        ;Find next entity
        ld c, ENTSYS_FLAGF_COLLISION | ENTSYS_FLAGF_PLAYER
        call entsys_find_continue
        jr z, .return
        push hl
        jr .find_player
    ;

    .return
    pop hl
    ret
;



; Face the engaged entity.
;
; Input:
; - `hl`: Entity pointer (anywhere)
; - `bc`: Engaged entity pointer
;
; Saves: `hl`
knightling_face_engaged:
    ld e, l
    entsys_relpointer_init ENTVAR_XPOS+1
    ld d, [hl]
    relpointer_move ENTVAR_KNIGHTLING_FLAGS
    ld a, c
    or a, ENTVAR_XPOS+1
    ld c, a

    ;Compare positiond
    ld a, [bc]
    cp a, d
    res KNIGHTLING_FLAGB_FACING, [hl]
    jr nc, :+
        set KNIGHTLING_FLAGB_FACING, [hl]
    :

    ;Return
    relpointer_destroy
    ld l, e
    ret
;



; Call when knightling is defeated/falls off the edge.
; Does NOT return, exits entity code execution entirely.
;
; Input:
; - `b`: Death effects (0 = no)
; - `hl`: Entity pointer (anywhere)
knightling_destroy:
    entsys_relpointer_init 0

    ;Spawn death effects + coin(s)
    ld a, b
    or a, a ;cp a, 0
    jr z, .no_effects
        relpointer_push ENTVAR_XPOS+1
        ld b, [hl]
        relpointer_move ENTVAR_YPOS+1
        ld c, [hl]
        push bc

        ;Create smoke particle
        farcall_x entity_particle_create

        ;Create coin(s)
        pop bc
        ;TODO: coins

        ;Alrighty
        relpointer_pop
    .no_effects

    ;Free the entity
    call entsys_free

    ;Decrement entity count
    ld hl, w_knightling_count
    dec [hl]

    ;Exit
    relpointer_destroy
    jp entsys_exit
;



; Draw call for knightling enemy.
;
; Input:
; - `hl`: Knightling entity pointer (anywhere)
;
; Saves: `hl`
knightling_draw:
    push hl

    entsys_relpointer_init ENTVAR_KNIGHTLING_STUN
    ld a, [hl]
    and a, %00000110
    cp a, %00000110
    jr nz, :+
        pop hl
        ret
    :

    ;Tile ID based on state -> C
    ld a, [w_knightling_sprite]
    ld c, a
    relpointer_move ENTVAR_KNIGHTLING_ANIMATE
    ld b, [hl]
    relpointer_move ENTVAR_KNIGHTLING_STATE
    ld a, [hl]

    ;Fall sprite
    cp a, KNIGHTLING_STATE_FALLING
    jr nz, :+
        ld a, c
        add a, KNIGHTLING_SPRITE_WALK
        ld c, a
        jr .sprited
    :

    ;Walk sprite
    cp a, KNIGHTLING_STATE_WALK
    jr nz, :+
        bit 7, b
        jr z, .sprited
        ld a, c
        add a, KNIGHTLING_SPRITE_WALK
        ld c, a
        jr .sprited
    :

    ;Turnaround sprites
    cp a, KNIGHTLING_STATE_TURNAROUND
    jr nz, :+
        ld e, l
        relpointer_push ENTVAR_KNIGHTLING_TIMER, 0
        ld a, [hl]
        relpointer_pop 0
        ld l, e
        sub a, KNIGHTLING_TURNAROUND_STEP
        cp a, KNIGHTLING_TURNAROUND_STEP*2
        jr nc, .sprited
        ld a, c
        add a, KNIGHTLING_SPRITE_WALK
        ld c, a
        jr .sprited
    :

    ;Fight sprites
    cp a, KNIGHTLING_STATE_FIGHT
    jr c, .sprited

        ;Draw sword
        call knightling_draw_sword
        ld a, c
        add a, KNIGHTLING_SPRITE_FIGHT
        ld c, a
    .sprited

    ;X-position -> D
    relpointer_move ENTVAR_XPOS+1
    ld a, [w_camera_xpos+1]
    cpl
    add a, [hl]
    add a, 8
    ld d, a

    ;Y-position -> E
    relpointer_move ENTVAR_YPOS+1
    ld e, [hl]
    inc e

    ;Get OAM attributes -> stack
    ld b, 0
    relpointer_move ENTVAR_KNIGHTLING_FLAGS
    bit KNIGHTLING_FLAGB_FACING, [hl]
    jr z, :+
        inc c
        inc c
        ld b, OAMF_XFLIP
    :
    push bc

    ;Get sprites
    relpointer_destroy
    ldh a, [h_oam_active]
    ld h, a
    ld b, 8
    call sprite_get

    ;Write data to sprites
    pop bc
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ld a, e
    ld [hl+], a
    ld a, d
    add a, 8
    ld [hl+], a
    ld a, c
    add a, 2
    bit OAMB_XFLIP, b
    jr z, :+
        sub a, 4
    :
    ld [hl+], a
    ld [hl], b

    ;Return
    .return
    pop hl
    ret
;



; Draw the knightlings sword.
;
; Input:
; - `hl`: Knightling entity pointer (anywhere)
;
; Saves: `bc`, `hl`
knightling_draw_sword:
    push bc
    push hl

    ;Sprite tile -> stack
    entsys_relpointer_init ENTVAR_KNIGHTLING_STATE
    ld a, [w_knightling_sprite]
    add a, KNIGHTLING_SPRITE_SWORD_WAIT
    ld b, a
    ld a, [hl]
    cp a, KNIGHTLING_STATE_ATTACK
    jr nz, :+
        inc b
        inc b
    :
    push bc

    ;Flags -> C
    relpointer_move ENTVAR_KNIGHTLING_FLAGS
    ld c, [hl]

    ;X-position -> D
    relpointer_move ENTVAR_XPOS+1
    ld a, [w_camera_xpos+1]
    cpl
    add a, [hl]
    bit KNIGHTLING_FLAGB_FACING, c
    ld c, OAMF_XFLIP
    jr nz, :+
        add a, 24
        ld c, 0
    :
    ld d, a

    ;Y-position -> E
    relpointer_move ENTVAR_YPOS+1
    ld e, [hl]
    inc e

    ;Get sprite
    relpointer_destroy
    ld b, 4
    ldh a, [h_oam_active]
    ld h, a
    call sprite_get

    ;Start writing information
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    pop af
    ld [hl+], a
    ld [hl], c

    ;Return
    pop hl
    pop bc
    ret
;
