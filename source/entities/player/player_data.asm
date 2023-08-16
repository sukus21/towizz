INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/tower.inc"

SECTION FRAGMENT "PLAYER", ROMX

player_sprite_base:
    INCBIN "graphics/player_base.tls"
.end

; Prepared vqueue transfer for base player sprites.
player_vprep_base:: vqueue_prepare_copy \
    VQUEUE_TYPE_DIRECT, \
    VT_TOWER_PLAYER, \
    player_sprite_base, \
    w_vqueue_writeback
;
