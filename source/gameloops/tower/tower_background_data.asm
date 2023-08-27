INCLUDE "struct/vram/tower.inc"

SECTION "TOWER BACKGROUND DATA", ROMX

; Tileset for the panoramic background.
tower_background_tls::
INCBIN "graphics/background/background.tls"

; Tilemap for the panoramic background.
tower_background_tlm::
INCBIN "graphics/background/background.tlm"
