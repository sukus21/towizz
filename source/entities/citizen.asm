INCLUDE "struct/vqueue.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"

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
