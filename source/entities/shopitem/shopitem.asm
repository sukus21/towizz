INCLUDE "entsys.inc"
INCLUDE "shop.inc"
INCLUDE "macros/memcpy.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/item.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/player.inc"
INCLUDE "struct/entity/shopitem.inc"
INCLUDE "struct/vram/shop.inc"

SECTION FRAGMENT "SHOPITEM", ROMX

; Creates a new shopitem entity.
; Queues up a VRAM transfer for the item.
;
; Input:
; - `b`: X-position (n8)
; - `c`: Item ID (`ITEM_ID_*`)
;
; Returns:
; - `hl`: Shopitem entity pointer
entity_shopitem_create::

    ;Allocate new entity
    push bc
    call entsys_new16
    ld h, b
    ld l, c
    pop bc
    push hl
    relpointer_init l

    ;Set bank
    ld [hl], bank(entity_shopitem)

    ;Set pointer
    relpointer_move ENTVAR_STEP
    ld a, low(entity_shopitem)
    ld [hl+], a
    ld a, high(entity_shopitem)
    ld [hl-], a

    ;Set X-position
    relpointer_move ENTVAR_SHOPITEM_XPOS
    ld [hl], b

    ;Set sprite
    relpointer_move ENTVAR_SHOPITEM_SPRITE
    ld a, [w_shop_itemsprite]
    add a, VTI_SHOP_ITEMS
    ld [hl], a

    ;Set item pointer
    relpointer_move ENTVAR_SHOPITEM_PTR
    ld a, c
    call item_get_data
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl-], a

    ;Get sprite source pointer
    ld a, [de]
    call item_get_sprite

    ;Get sprite destination pointer
    ld hl, w_shop_itemsprite
    ld a, [hl]
    add a, 4
    ld [hl], a
    sub a, 4
    swap a
    ld c, a
    and a, %00001111
    add a, high(VT_SHOP_ITEMS)
    ld b, a
    ld a, c
    and a, %11110000
    add a, low(VT_SHOP_ITEMS)
    ld c, a
    jr nc, :+
        inc b
    :
    
    ;Prepare VQUEUE transfer
    call vqueue_get
    ld a, VQUEUE_TYPE_DIRECT | VQUEUE_MODEFLAG_COPYMODE
    ld [hl+], a ;type
    ld a, 4
    ld [hl+], a ;length
    xor a
    ld [hl+], a ;progress
    ld a, c
    ld [hl+], a ;destination low
    ld a, b
    ld [hl+], a ;destination high
    ld a, bank(item_sprites)
    ld [hl+], a ;source bank
    ld a, e
    ld [hl+], a ;source low
    ld a, d
    ld [hl+], a ;source high
    xor a
    ld [hl+], a ;writeback low
    ld [hl+], a ;writeback high

    ;Return
    relpointer_destroy
    pop hl
    ret
;



; Step function for shopitem entity.
; This entity should only exist in the shop gameloop.
;
; Input:
; - `de`: Entity pointer
entity_shopitem::
    call shopitem_draw
    ret
;



; Drawing routine for a shopitem.
;
; Input:
; - `de`: Shopitem entity pointer (anywhere)
;
; Saves: `de`
shopitem_draw:
    push de
    ld a, e
    and a, %11110000
    or a, ENTVAR_SHOPITEM_SPRITE
    ld e, a

    ;Read sprite -> C
    relpointer_init e, ENTVAR_SHOPITEM_SPRITE
    ld a, [de]
    ld c, a
    
    ;Read X-position
    relpointer_move ENTVAR_SHOPITEM_XPOS
    ld a, [de]
    ld e, a

    ;Obtain sprites
    ld b, 2*4
    ld h, high(w_oam_hud)
    call sprite_get

    ;Start writin' data
    ld a, $75
    ld [hl+], a
    ld a, e
    ld [hl+], a
    ld a, c
    ld [hl+], a
    xor a
    ld [hl+], a
    ld a, $75
    ld [hl+], a
    ld a, e
    add a, 8
    ld [hl+], a
    ld a, c
    add a, 2
    ld [hl+], a
    ld [hl], 0
    relpointer_destroy
    pop de
    ret
;
