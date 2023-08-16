    IF !DEF(STRUCT_VRAM_SHOP_INC)
    DEF STRUCT_VRAM_SHOP_INC EQU 1

INCLUDE "hardware.inc"
INCLUDE "macros/tilemap.inc"

;Block 0 (sprites only)
RSSET $00

    ; Player tileset.
    DEF VT_SHOP_PLAYER EQU $8000 + $10 * _RS
    DEF VTI_SHOP_PLAYER RB $30

    ; Preview tileset.
    DEF VT_SHOP_PREVIEW EQU $8000 + $80 * _RS
    DEF VTI_SHOP_PREVIEW RB $40
ASSERT _RS <= $80

;Block 1 (sprites + background)
RSSET $80

    ; HUD tileset.
    DEF _RS += _RS & 1
    DEF VT_SHOP_HUD EQU $8000 + $10 * _RS
    DEF VTI_SHOP_HUD RB $10
ASSERT _RS <= $100

;Block 2 (backgrounds only)
RSSET $00

    ; Background tileset.
    DEF VT_SHOP_TILESET EQU $9000 + $10 * _RS
    DEF VTI_SHOP_TILESET RB $20

    ; Shop font tileset.
    DEF VT_SHOP_FONT EQU $9000 + $10 * _RS
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

    tilemap_alloc_finish
;

    ENDC
