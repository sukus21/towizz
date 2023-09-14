    IF !DEF(STRUCT_VRAM_SHOP_INC)
    DEF STRUCT_VRAM_SHOP_INC EQU 1

INCLUDE "hardware.inc"
INCLUDE "macros/tilemap.inc"

;Block 0 (sprites only)
RSSET $00
    IF DEF(EQRB)
        PURGE EQRB
    ENDC
    DEF EQRB EQUS "$8000 + $10 * _RS"

    ; Player tileset.
    DEF VT_SHOP_PLAYER EQU EQRB
    DEF VTI_SHOP_PLAYER RB $30

    ; Preview tileset.
    DEF VT_SHOP_PREVIEW EQU EQRB
    DEF VTI_SHOP_PREVIEW RB $40

    ; Shopdoor tiles
    DEF VT_SHOP_SHOPDOOR EQU EQRB
    DEF VTI_SHOP_SHOPDOOR RB $02
ASSERT _RS <= $80

;Block 1 (sprites + background)
RSSET $80
    PURGE EQRB
    DEF EQRB EQUS "$8000 + $10 * _RS"

    ; Shop item tiles.
    DEF VT_SHOP_ITEMS EQU EQRB
    DEF VTI_SHOP_ITEMS RB $2C

    DEF VT_SHOP_PLAYERPURCHASE EQU EQRB
    DEF VTI_SHOP_PLAYERPURCHASE RB $04

    ; Location of coin tileset.
    DEF VT_SHOP_COIN EQU EQRB
    DEF VTI_SHOP_COIN RB $08

    ; Location of particle tileset.
    DEF VT_SHOP_PARTICLE EQU EQRB
    DEF VTI_SHOP_PARTICLE RB $08

    ; HUD tiles.
    DEF VT_SHOP_HUD EQU EQRB
    DEF VTI_SHOP_HUD RB $1A
ASSERT _RS <= $100

;Block 2 (backgrounds only)
RSSET $00
    PURGE EQRB
    DEF EQRB EQUS "$9000 + $10 * _RS"

    ; Background tileset.
    DEF VT_SHOP_TILESET EQU EQRB
    DEF VTI_SHOP_TILESET RB $20

    ; Shop font tileset.
    DEF VT_SHOP_FONT EQU EQRB
    DEF VTI_SHOP_FONT RB $60
ASSERT _RS <= $80

;SCRN 0
    tilemap_alloc _SCRN0, "VM_SHOP_BACKGROUND", 0, 0, 20, 18
    ; Static background, with item name and preview.  
    ; The bottom part being blank is required.  
    ; Spans 20x18 tiles.  
    ; Located on `SCRN0`.
    DEF VM_SHOP_BACKGROUND EQU tlmv_addr

    tilemap_ptr _SCRN0, "VM_SHOP_ITEMNAME", 2, 1
    ; Item name location on tilemap.  
    ; This is where the item name text should be copied to.  
    ; Spans 10x1 tiles.  
    ; Located on `SCRN0`.
    DEF VM_SHOP_ITEMNAME EQU tlmv_addr

    tilemap_ptr _SCRN0, "VM_SHOP_ITEMPRICE", 14, 1
    ; Price of previewed item.  
    ; Spans 3x1 tiles.  
    ; Located on `SCRN0`.
    DEF VM_SHOP_ITEMPRICE EQU tlmv_addr

    tilemap_alloc_finish
;

;SCRN1
    tilemap_alloc _SCRN1, "VM_SHOP_FOREGROUND", 0, 0, 20, 5
    ; Static foreground elements inside shop.  
    ; Includes floor, exit, and item stands.  
    ; Spans 20x6 tiles.  
    ; Located on `SCRN1`.
    DEF VM_SHOP_FOREGROUND EQU tlmv_addr

    tilemap_ptr _SCRN1, "VM_SHOP_STAND1", 1, 3
    ; Leftmost item stand.  
    ; 2x1 tiles.  
    ; Located on `SCRN1`.
    DEF VM_SHOP_STAND1 EQU tlmv_addr

    tilemap_ptr _SCRN1, "VM_SHOP_STAND2", 5, 3
    ; Middle item stand.  
    ; 2x1 tiles.  
    ; Located on `SCRN1`.
    DEF VM_SHOP_STAND2 EQU tlmv_addr

    tilemap_ptr _SCRN1, "VM_SHOP_STAND3", 9, 3
    ; Rightmost item stand.  
    ; 2x1 tiles.  
    ; Located on `SCRN1`.
    DEF VM_SHOP_STAND3 EQU tlmv_addr

    tilemap_alloc _SCRN1, "VM_SHOP_HUD", 0, 29, 20, 3
    ; The HUD area inside the shop.  
    ; 32x3 tiles.  
    ; Located on `SCRN1`.
    DEF VM_SHOP_HUD equ tlmv_addr

    tilemap_alloc_finish
;

    ENDC
