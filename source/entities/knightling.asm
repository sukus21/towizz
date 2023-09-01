INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
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
    ld [w_sprite_knightling], a
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
    relpointer_init l

    ;Do some crazy stuff
    call knightling_draw

    ;Return
    relpointer_destroy
    ret
;



; Draw call for knightling enemy.
;
; Input:
; - `hl`: Knightling entity pointer (anywhere)
;
; Saves: `hl`
knightling_draw:
    push hl

    ;Tile ID based on state -> C
    ld a, [w_sprite_knightling]
    ld c, a
    entsys_relpointer_init ENTVAR_KNIGHTLING_ANIMATE
    ld b, [hl]
    relpointer_move ENTVAR_KNIGHTLING_STATE
    ld a, [hl]

    ;Walk sprite
    cp a, KNIGHTLING_STATE_WALK
    jr nz, :+
        bit 4, b
        jr z, .sprited
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
    ld a, [w_sprite_knightling]
    add a, KNIGHTLING_SPRITE_SWORD_WAIT
    ld b, a
    ld a, [hl]
    cp a, KNIGHTLING_STATE_ATTACK
    jr z, :+
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
