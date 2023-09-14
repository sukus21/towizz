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
    ld a, c
    inc a
    ret z

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
    relpointer_init e, ENTVAR_BANK
    call shopitem_draw

    ;Find player
    ld c, ENTSYS_FLAGF_PLAYER
    call entsys_find_all
    ret z

    ;We found a player, find its position
    ld a, l
    or a, ENTVAR_XPOS+1
    ld l, a
    
    ;Find my position
    relpointer_move ENTVAR_SHOPITEM_XPOS
    ld a, [de]
    ld b, a

    ;Compare these
    ld a, [hl]
    add a, PLAYER_WIDTH/2
    cp a, b
    jr c, .no_collision
    ld a, b
    add a, 16
    ld b, a
    ld a, [hl]
    add a, PLAYER_WIDTH/2
    cp a, b
    jr c, .yes_collision

    ;We are not currently colliding with the player.
    .no_collision

        ;Were we previously?
        ld a, [w_shop_preview_current]
        ld b, a
        ld a, [de]
        cp a, b
        ret nz

        ;Yes, that was me, stop preview
        xor a
        ld [w_shop_preview_current], a

        ;Clear namebuffer
        call vqueue_clear
        ld hl, w_shop_namebuffer
        ld a, " "
        ld b, 16
        :
            ld [hl+], a
            dec b
            jr nz, :-
        ld de, item_vprep_name
        call vqueue_enqueue
        ret
    ;

    ;Aw yeah, this is happenin'!
    .yes_collision

        ;Get `ITEM` struct pointer
        relpointer_move ENTVAR_SHOPITEM_PTR
        ld a, [de]
        ld c, a
        inc e
        ld a, [de]
        ld b, a

        ;Do item preview
        call preview_prepare
        call preview_step
    ;

    relpointer_destroy
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
    add a, 8
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

    ;Return
    relpointer_destroy
    pop de
    ret
;



; Prepares preview for the given item + entity combo.
; Exits out if preview is already running, or vqueue is occupied.
; Prepares `w_shop_namebuffer` for transfer to VRAM.  
; Enqueues vqueue transfer.
;
; Input:
; - `bc`: `ITEM` pointer
; - `de`: Shop item entity pointer (anywhere)
;
; Saves: `bc`, `de`  
; Destroys: `af`, `hl`
preview_prepare:
    push de
    push bc
    ld a, e
    and a, %11110000
    or a, ENTVAR_SHOPITEM_XPOS
    ld e, a
    relpointer_init e, ENTVAR_SHOPITEM_XPOS

    ;This is already being previewed, ignore
    ld a, [de]
    ld hl, w_shop_preview_current
    cp a, [hl]
    jr z, .return

    ;Only start preview if vqueue is empty
    call vqueue_empty
    jr nz, .return

    ;Start preview
    ld a, [de]
    ld [hl], a

    ;Clear writeback location
    relpointer_move ENTVAR_SHOPITEM_WRITEBACK
    xor a
    ld [de], a

    ;Write item name
    push de
    inc bc
    ld hl, w_shop_namebuffer+1
    ld d, ITEM_NAME_LENGTH
    memcpy_custom hl, bc, d

    ;Write space and dollar sign
    ld a, " "
    ld [hl+], a
    ld a, "$"
    ld [hl+], a

    ;Get item price
    pop de
    relpointer_move ENTVAR_SHOPITEM_PRICE
    ld a, [bc]
    call item_modify_price
    call bin2bcd
    ld [de], a

    ;Write item price to screen
    ld d, a
    swap a
    and a, %00001111
    jr nz, :+
        ld a, " "
        ld [hl+], a
        jr :++
    :
    add a, "0"
    ld [hl+], a
    :
    ld a, d
    and a, %00001111
    add a, "0"
    ld [hl+], a

    ;Call init function
    inc bc
    ld a, [bc]
    ld l, a
    inc bc
    ld a, [bc]
    ld h, a
    call _hl_

    ;Transfer name box to the screen
    ld de, item_vprep_name
    call vqueue_enqueue

    ;Yup, that'll do it
    .return
    relpointer_destroy
    pop bc
    pop de
    ret
;



; Runs the item preview.  
; Exits if preview pane is not ready yet.  
; Exits if preview assets haven't finished loading yet.
;
; Input:
; - `bc`: `ITEM` pointer
;
; Saves: `bc`, `de`
preview_step:

    ;Is preview pane ready?
    ld a, [w_shop_preview_open]
    cp a, SHOP_PREVIEW_OPEN
    ret nz

    ;Is vqueue empty?
    call vqueue_empty
    ret nz

    ;Save this junk
    push de
    push bc

    ;Load step-function pointer and call it
    ld a, c
    add a, ITEM_PREVIEW_STEP
    ld l, a
    ld h, b
    jr nc, :+
        inc h
    :

    ;Yup, there it is
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call _hl_

    ;And we are done here
    pop bc
    pop de
    ret
;



; Modifies the item price.
; Items become more expensive, the further into the game you get.  
; Lives in ROM0.
;
; Input:
; - `a`: Starting price (n8)
;
; Returns:
; - `a`: Final price
;
; Destroys: `f`
item_modify_price::
    push bc
    push de
    ld b, a
    srl a
    srl c
    inc c

    ;Add expense
    ld a, [w_waves_passed]
    ld d, a
    ld a, b

    .loop
    srl d
    jr z, .return
    add a, c
    jr .loop

    ;Return
    .return
    pop de
    pop bc
    ret
;
