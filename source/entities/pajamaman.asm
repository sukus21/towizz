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
    ret
;
