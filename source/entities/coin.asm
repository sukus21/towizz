INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/coin.inc"
INCLUDE "struct/vram/tower.inc"


SECTION "SHARED COIN", ROM0

; Get tile ID to use for coins this frame.  
; Lives in ROM0.
;
; Returns:
; - `a`: Tile ID
;
; Destroys: `af`, `b`
coin_get_sprite::
    ld a, [w_coin_animate]
    swap a
    rlca
    and a, %00000111
    ld b, a
    ld a, [w_coin_sprite]

    ;Based on this information, what do?
    bit 0, b
    jr z, :+
        add a, COIN_SPRITE_FLIPPING
        ret
    :
    bit 1, b
    jr z, :+
        add a, COIN_SPRITE_SIDE
        ret
    :
    bit 2, b
    jr z, :+
        add a, COIN_SPRITE_TAILS
        ret
    :
    add a, COIN_SPRITE_HEADS
    ret
;



; Draws a coin using sprites.
; Position is top-left pixel.  
; Lives in ROM0.
;
; Input:
; - `hl`: OAM mirror
; - `d`: X-position
; - `e`: Y-position
coin_draw::
    ld b, 4
    call sprite_get

    ;Write sprite data
    ld a, e
    add a, 8
    ld [hl+], a
    ld a, d
    add a, 8
    ld [hl+], a
    call coin_get_sprite
    ld [hl+], a
    ld [hl], 0

    ;Return
    ret
;



SECTION "ENTITY COIN", ROMX

; Tileset for particle.
coin_tls: INCBIN "graphics/coin.tls"
.end



; Adds VQUEUE transfer for coin tileset.
;
; Input:
; - `de`: Destination
entity_coin_load::
    
    ;Get tile ID from address (somehow)
    ld b, d
    ld a, c
    srl b
    rra 
    srl b
    rra
    srl b
    rra
    srl b
    rra
    set 0, a
    ld [w_coin_sprite], a

    ;Add VQUEUE transfer
    vqueue_add_copy \
        VQUEUE_TYPE_DIRECT, \
        de, \
        coin_tls
    ;

    ;No writeback needed
    xor a
    ld [hl+], a
    ld [hl+], a

    ;Return
    ret
;



; Create new coin entity.
;
; Input:
; - `b`: X-position (high)
; - `c`: Y-position (high)
;
; Destroys: all
entity_coin_create::
    ld hl, w_coin_count
    inc [hl]

    push bc
    entsys_new 16, entity_coin, COIN_FLAGS
    pop bc

    ;Set positions
    relpointer_move ENTVAR_YPOS
    xor a
    ld [hl+], a
    ld a, c
    ld [hl-], a
    relpointer_move ENTVAR_XPOS
    xor a
    ld [hl+], a
    ld a, b
    ld [hl-], a

    ;Set width and height
    relpointer_move ENTVAR_HEIGHT
    ld a, COIN_HEIGHT
    ld [hl+], a
    ld a, COIN_WIDTH
    ld [hl-], a

    ;Set speeds
    relpointer_move ENTVAR_COIN_YSPEED
    call rng_run
    ld a, d
    and a, %00001111
    add a, $17
    cpl
    ld [hl+], a
    ld a, e
    and a, %00000111
    add a, $03
    bit 7, e
    jr z, :+
        cpl
        inc a
    :
    ld [hl-], a

    ;That was it
    relpointer_destroy
    ret
;



; Coin entity step function.
;
; Input:
; - `de`: Entity pointer
entity_coin:
    ld h, d
    ld l, e
    
    ;Update and draw
    call entity_coin_update
    call entity_coin_draw

    ;Return
    ret
;



; Input:
; - `hl`: Entity pointer
;
; Saves: `hl`
entity_coin_update:
    push hl
    entsys_relpointer_init 0, COIN_BITMASK
    
    ;OOB check
    call entsys_oob
    jp nz, coin_destroy

    ;Get X-speed -> BC
    relpointer_move ENTVAR_COIN_XSPEED
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

    ;Add X-speed to X-position
    relpointer_move ENTVAR_XPOS
    ld a, c
    add a, [hl]
    ld [hl+], a
    ld a, b
    adc a, [hl]
    ld [hl-], a
    ld d, a

    ;Perform gravity + get Y-speed -> BC
    relpointer_move ENTVAR_COIN_YSPEED
    inc [hl]
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

    ;Add Y-speed to position
    relpointer_move ENTVAR_YPOS
    ld a, c
    add a, [hl]
    ld [hl+], a
    ld a, b
    adc a, [hl]
    ld [hl-], a
    ld b, a

    ;Are we now inside platform?
    ld a, [w_platform_xpos+1]
    cp a, d
    jr c, .no_platform
    ld a, [w_platform_ypos+1]
    cp a, b
    jr nc, .no_platform

        ;Ok, time to react to the platform
        inc l
        inc a
        ld [hl-], a
        ld [hl], 0

        ;Change speed ?maybe
        relpointer_push ENTVAR_COIN_YSPEED, 0
        ld a, [hl]
        bit 7, a
        jr nz, :+
            sra a
            cpl
            inc a
            ld [hl], a
        :
        relpointer_pop 0
    .no_platform

    ;Return
    relpointer_destroy
    pop hl
    ret
;



; Draw routine for coin.
;
; Input:
; - `hl`: Entity pointer
;
; Saves: `hl`
entity_coin_draw:
    push hl

    ;Grab position -> DE
    entsys_relpointer_init ENTVAR_YPOS+1, COIN_BITMASK
    ld a, [hl]
    sub a, 8
    ld e, a
    relpointer_move ENTVAR_XPOS+1
    ld a, [w_camera_xpos+1]
    cpl
    add a, [hl]
    ld d, a
    
    ;Draw coin
    relpointer_destroy
    ldh a, [h_oam_active]
    ld h, a
    call coin_draw

    ;Return
    pop hl
    ret
;



; Coin is dead. No more coin.  
; Does not return.
;
; Input:
; - `hl`: Entity pointer (anywhere)
coin_destroy:
    
    ;Free entity
    ld a, l
    and a, %11110000
    ld l, a
    call entsys_free

    ;Decrement coin entity count
    ld hl, w_coin_count
    dec [hl]

    ;Hard exit
    jp entsys_exit
;
