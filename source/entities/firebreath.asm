INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/firebreath.inc"
INCLUDE "struct/entity/player.inc"

SECTION "ENTITY FIREBREATH", ROMX

; Create new firebreath entity.
;
; Input:
; - `bc`: X-speed (Y-speed inferred)
; - `d`: X-position (high)
; - `e`: Y-position (high)
;
; Destroys: all
entity_firebreath_create::
    push bc
    push de
    entsys_new 32, entity_firebreath, ENTSYS_FLAGF_COLLISION | ENTSYS_FLAGF_DAMAGE | ENTSYS_FLAGF_DMGCALL

    ;Set X- and Y-position
    pop de
    relpointer_move ENTVAR_XPOS
    xor a
    ld [hl+], a
    ld a, d
    ld [hl-], a
    relpointer_move ENTVAR_YPOS
    xor a
    ld [hl+], a
    ld a, e
    ld [hl-], a

    ;Set dmgcall pointer
    relpointer_move ENTVAR_DMGCALL
    ld a, low(entity_firebreath_dmgcall)
    ld [hl+], a
    ld a, high(entity_firebreath_dmgcall)
    ld [hl-], a

    ;Set X-speed
    pop bc
    relpointer_move ENTVAR_FIREBREATH_XSPEED
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl-], a

    ;Force X-speed into negative
    bit 7, b
    jr nz, :+
        ld a, c
        cpl
        inc a
        ld c, a
        ld b, $FF
    :

    ;Infer Y-speed
    ld a, -FIREBREATH_SPEED_PRIMARY
    cp a, c
    jr nz, :+
        ld a, -FIREBREATH_SPEED_SECONDARY
    :
    ld c, a

    ;Store this
    relpointer_move ENTVAR_FIREBREATH_YSPEED
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl-], a

    ;Get sprite
    relpointer_move ENTVAR_FIREBREATH_SPRITE
    ld a, [w_player_woffset]
    add a, PLAYER_SPRITE_FIREBREATH_BALL1
    ld [hl], a

    ;That was it
    relpointer_destroy
    ret
;



; Firebreath entity step function.
;
; Input:
; - `de`: Entity pointer
entity_firebreath:
    ld h, d
    ld l, e
    relpointer_init l

    ;Outside map?
    relpointer_move ENTVAR_XPOS+1
    ld a, [w_camera_xpos+1]
    cpl
    add a, [hl]
    cp a, 160
    jr c, .checky

    ;Getting warmer
    cp a, 240
    jr nc, .checky

    ;Yup, destroy this one
    .destroy
    ld l, e
    jp entsys_free

    ;Check Y-position
    .checky
    relpointer_move ENTVAR_YPOS+1
    ld a, [hl]
    cp a, 160
    jr nc, .destroy

    ;Get X-position -> BC
    relpointer_move ENTVAR_FIREBREATH_XSPEED
    ld a, [hl+]
    ld c, a
    ld a, [hl-]
    ld b, a

    ;Get Y-position -> DE
    relpointer_move ENTVAR_FIREBREATH_YSPEED
    ld a, [hl+]
    ld e, a
    ld a, [hl-]
    ld d, a

    ;Update X-position
    relpointer_move ENTVAR_XPOS
    ld a, [hl]
    add a, c
    ld [hl+], a
    ld a, [hl]
    adc a, b
    ld [hl-], a
    ld b, a
    ld a, [w_camera_xpos+1]
    cpl
    add a, 8
    add a, b
    ld b, a

    ;Update Y-position
    relpointer_move ENTVAR_YPOS
    ld a, [hl]
    add a, e
    ld [hl+], a
    ld a, [hl]
    adc a, d
    ld [hl-], a
    ld c, a
    push bc

    ;Tick timer -> C
    relpointer_move ENTVAR_FIREBREATH_TIMER
    inc [hl]
    ld c, [hl]

    ;Get sprite tile -> D
    relpointer_move ENTVAR_FIREBREATH_SPRITE
    ld a, [hl]
    bit 2, c
    jr z, :+
        add a, 4
    :
    ld d, a

    ;Get sprite attributes -> E
    ld e, 0
    bit 3, c
    jr z, :+
        ld e, OAMF_XFLIP | OAMF_YFLIP
        inc d
        inc d
    :

    ;Get sprite and draw
    ld b, 8
    ldh a, [h_oam_active]
    ld h, a
    call sprite_get

    ;Start writin' data
    pop bc
    ld [hl], c
    inc l
    ld [hl], b
    inc l
    ld [hl], d
    inc l
    ld [hl], e
    inc l
    ld [hl], c
    inc l
    ld a, b
    add a, 8
    ld [hl+], a
    ld a, d
    bit OAMB_XFLIP, e
    jr z, :+
        sub a, 4
    :
    add a, 2
    ld [hl+], a
    ld [hl], e

    ;Ok, we are done here
    relpointer_destroy
    ret
;



; Called whenever this entity deals damage.
; Just destroy this and move on.
;
; Input:
; - `de`: Entity pointer
entity_firebreath_dmgcall:
    ld h, d
    ld l, e
    jp entsys_free
;
