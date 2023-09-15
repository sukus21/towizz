INCLUDE "struct/item.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/shop.inc"

SECTION FRAGMENT "SHOPITEM", ROMX

; Contains a list of all item sprites.  
; Each sprite is 4 tiles (64 bytes) of data.
; A sprite can be looked up using ab `ITEM_ID_*` constant.
item_sprites::
    INCBIN "graphics/items/jump.tls"
    INCBIN "graphics/items/firebreath.tls"
    INCBIN "graphics/items/heart.tls"
    INCBIN "graphics/items/jetpack.tls"
    INCBIN "graphics/items/stompers.tls"
;



; Contains a list of `ITEM` structs.
; Data can be looked up using an `ITEM_ID_*` constant.
item_data::
    item_define ITEM_ID_JUMP,       "JUMP",         0,  item_preview_jump_init,          item_preview_jump_run
    item_define ITEM_ID_FIREBREATH, "FIREBREATH",   3,  item_preview_firebreath_init,    item_preview_firebreath_run
    item_define ITEM_ID_HEART,      "+1 HEALTH",    1,  item_preview_jump_init,          item_preview_jump_init
    item_define ITEM_ID_JETPACK,    "JETPACK",      5,  item_preview_jetpack_init,       item_preview_jetpack_run
    item_define ITEM_ID_STOMPERS,   "STOMPERS",     7,  item_preview_stompers_init,      item_preview_stompers_run
;



; Copies name from `w_shop_namebuffer` to screen.
item_vprep_name:: vqueue_prepare \
    VQUEUE_TYPE_HALFROW | VQUEUE_MODEFLAG_COPYMODE, \
    1, \
    VM_SHOP_ITEMNAME, \
    w_shop_namebuffer, \
    w_vqueue_writeback
;



; Get pointer to sprite data from ID.
;
; Input:
; - `a`: Item ID (`ITEM_ID_*`)
;
; Returns:
; - `de`: Sprite pointer
;
; Saves: `hl`  
; Destroys: `af`, `bc`
item_get_sprite::
    ld de, item_sprites
    or a, a
    ret z

    ;Prepare for loop
    ld b, a
    ld c, $40
    ld a, e

    ;Add offset for every item
    .loop
        add a, c
        ld e, a
        jr nc, :+
            inc d
        :
        dec b
        jr nz, .loop
    ;

    ;We got it
    ret
;



; Get data to sprite data from ID.
;
; Input:
; - `a`: Item ID (`ITEM_ID_*`)
;
; Returns:
; - `de`: `ITEM` pointer
;
; Saves: `hl`  
; Destroys: `af`, `bc`
item_get_data::
    ld de, item_data
    or a, a
    ret z

    ;Prepare for loop
    ld b, a
    ld c, ITEM
    ld a, e

    ;Add offset for every item
    .loop
        add a, c
        ld e, a
        jr nc, :+
            inc d
        :
        dec b
        jr nz, .loop
    ;

    ;We got it
    ret
;
