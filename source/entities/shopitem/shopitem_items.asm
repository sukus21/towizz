INCLUDE "struct/item.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/shop.inc"

SECTION FRAGMENT "SHOPITEM", ROMX

; Contains a list of all item sprites.  
; Each sprite is 4 tiles (64 bytes) of data.
; A sprite can be looked up using ab `ITEM_ID_*` constant.
item_sprites::
    INCBIN "graphics/items/ball.tls"
;



; Contains a list of `ITEM` structs.
; Data can be looked up using an `ITEM_ID_*` constant.
item_data::
    item_define ITEM_ID_BALL, "BALL", 5, item_preview_ball_init, item_preview_ball_run
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
