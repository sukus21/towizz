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
