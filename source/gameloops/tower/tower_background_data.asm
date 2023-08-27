

SECTION "TOWER BACKGROUND DATA", ROMX

; Tileset for the panoramic background.
tower_background_tls::
INCBIN "graphics/background/background.tls"

; Tilemap for the panoramic background.
tower_background_tlm::
INCBIN "graphics/background/background.tlm"

; How many new tiles to load for each section.
tower_background_newtiles::
    db $12
    db $29
    db $00
    db $00

    db $10
    db $0E
    db $0F
    db $11

    db $0A
    db $12
    db $0C
    db $12

    db $10
    db $07
    db $17
    db $10
;

; What tile is the earliest one for each section.
tower_background_oldtile::
    db $00
    db $00
    db $00
    db $00

    db $00
    db $00
    db $2B
    db $2B

    db $2B
    db $4B
    db $5A
    db $5A

    db $84
    db $94
    db $9B
    db $9B
;
