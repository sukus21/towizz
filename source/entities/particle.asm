INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/particle.inc"
INCLUDE "struct/vram/tower.inc"

SECTION "ENTITY PARTICLE", ROMX

; Tileset for particle.
particle_tls: INCBIN "graphics/particle.tls"
.end



; Adds VQUEUE transfer for coin tileset.
;
; Input:
; - `de`: Destination
entity_particle_load::
    vqueue_add_copy \
        VQUEUE_TYPE_DIRECT, \
        de, \
        particle_tls
    ;

    ;No writeback needed
    xor a
    ld [hl+], a
    ld [hl+], a

    ;Return
    ret
;



; Create new particle entity.
;
; Input:
; - `b`: X-position (high)
; - `c`: Y-position (high)
;
; Destroys: all
entity_particle_create::
    push bc
    entsys_new 16, entity_particle, PARTICLE_FLAGS

    ;Set X- and Y-position
    pop bc
    relpointer_move ENTVAR_PARTICLE_XPOS
    ld a, b
    add a, 8
    ld [hl], a
    relpointer_move ENTVAR_PARTICLE_YPOS
    ld [hl], c

    ;Reset timer
    relpointer_move ENTVAR_PARTICLE_TIMER
    ld [hl], 0

    ;That was it
    relpointer_destroy
    ret
;



; Particle entity step function.
;
; Input:
; - `de`: Entity pointer
entity_particle:
    ld h, d
    ld l, e
    relpointer_init l

    ;Tick timer
    relpointer_move ENTVAR_PARTICLE_TIMER
    inc [hl]
    ld d, [hl]

    ;Get position
    relpointer_move ENTVAR_PARTICLE_XPOS
    ld b, [hl]
    ld a, [w_camera_xpos+1]
    cpl
    add a, b
    ld b, a
    relpointer_move ENTVAR_PARTICLE_YPOS
    ld c, [hl]

    ;Get sprite ID -> E
    ld a, d
    rra
    rra
    ld d, a
    rra
    and a, %00000111
    bit 2, a
    jr z, :+
        
        ;That was it, destroy and exit
        ld l, e
        call entsys_free
        jp entsys_exit
    :
    add a, a
    add a, VTI_TOWER_PARTICLE
    ld e, a
    ld a, d
    and a, %00001111
    ld d, a

    ;Get sprites
    push bc
    relpointer_destroy
    ldh a, [h_oam_active]
    ld h, a
    ld b, 2*4
    call sprite_get

    ;Write sum data
    pop bc
    ld a, c
    ld [hl+], a
    ld a, b
    sub a, d
    ld [hl+], a
    ld a, e
    ld [hl+], a
    xor a
    ld [hl+], a

    ld a, c
    ld [hl+], a
    ld a, b
    add a, 8
    add a, d
    ld [hl+], a
    ld a, e
    ld [hl+], a
    ld [hl], OAMF_XFLIP

    ;Ok, we are done here
    ret
;
