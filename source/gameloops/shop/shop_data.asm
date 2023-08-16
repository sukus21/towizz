INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/shop.inc"

SECTION "SHOP DATA", ROMX

; The main graphics tileset data for the shop gameloop.
shop_tileset::
    INCBIN "graphics/shop/graphics.tls"
    INCBIN "graphics/shop/font.tls"
.end::

; Foreground tilemap data for shop gameloop.
shop_tilemap_foreground::
    INCBIN "graphics/shop/foreground.tlm"
.end::

; Background tilemap data for shop gameloop.
shop_tilemap_background::
    INCBIN "graphics/shop/background.tlm"
.end::



; A list of all prepared VQUEUE transfers, required for shop startup.
shop_vprep::

; Prepared VQUEUE transfer.  
; Transfers all the tiles needed for the tile gameloop.
shop_vprep_tileset:: vqueue_prepare_copy \
    VQUEUE_TYPE_DIRECT, \
    VT_SHOP_TILESET, \
    shop_tileset, \
    w_vqueue_writeback
;

; Prepared VQUEUE transfer.  
; Transfers the foreground tilemap onto the window layer.
shop_vprep_foreground:: vqueue_prepare_copy \
    VQUEUE_TYPE_SCREENROW, \
    VM_SHOP_FOREGROUND, \
    shop_tilemap_foreground, \
    w_vqueue_writeback, \
    20
;

; Prepared VQUEUE transfer.  
; Transfers the background tilemap onto the window layer.
shop_vprep_background:: vqueue_prepare_copy \
    VQUEUE_TYPE_SCREENROW, \
    VM_SHOP_BACKGROUND, \
    shop_tilemap_background, \
    w_vqueue_writeback, \
    20
;

; Prepared VQUEUE transfer.  
; Transfers HUD tileset
shop_vprep_hud_tls:: vqueue_prepare_copy \
    VQUEUE_TYPE_DIRECT, \
    VT_SHOP_HUD, \
    tower_asset_hud, \
    w_vqueue_writeback
;

; A set of 2 prepared VQUEUE transfers.  
; Draws the HUD how I like it.
shop_vprep_hud_tlm::
    vqueue_prepare_set \
        VQUEUE_TYPE_SCREENROW, \
        2, \
        VM_SHOP_HUD+$00, \
        VTI_SHOP_HUD+0, \
        w_vqueue_writeback
    ;

    vqueue_prepare_set \
        VQUEUE_TYPE_SCREENROW, \
        1, \
        VM_SHOP_HUD+$40, \
        VTI_SHOP_HUD+1, \
        w_vqueue_writeback
    ;
;
