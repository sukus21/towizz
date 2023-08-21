INCLUDE "entsys.inc"
INCLUDE "shop.inc"
INCLUDE "macros/color.inc"
INCLUDE "macros/farcall.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/item.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/player.inc"
INCLUDE "struct/vram/shop.inc"

SECTION "GAMELOOP SHOP", ROM0

; Setup routine for the shop gameloop.  
; Disables interrupts.  
; Assumes LCD is on.  
; Lives in ROM0.
gameloop_shop_setup:
    di

    ;Camera should be at 0,0 and not move
    xor a
    ld hl, w_camera_xspeed
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a

    ;Lock platform position, floor is solid in shops
    ld hl, w_platform_xspeed
    ld [hl+], a
    ld [hl+], a
    dec a
    ld [hl+], a
    ld [hl+], a

    ;Platform should only be at floor level
    xor a
    ld hl, w_platform_yspeed
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], SCRN_Y - 16

    ;We don't need multiple OAM mirrors
    ld a, high(w_oam_hud)
    ldh [h_oam_active], a

    ;Lock window in place
    ld a, WX_OFS
    ldh [rWX], a
    ld a, SHOP_WY_FOREGROUND
    ldh [rWY], a

    ;Lock background scroll position
    ld a, SHOP_SCY_BACKGROUND
    ldh [rSCY], a
    xor a
    ldh [rSCX], a

    ;Set up entitysystem and create player
    call vqueue_clear
    call entsys_clear
    farcall_0 entity_player_create
    relpointer_init l, ENTVAR_BANK
    relpointer_move ENTVAR_XPOS
    xor a
    ld [hl+], a
    ld a, 16*8
    ld [hl-], a
    relpointer_move ENTVAR_PLAYER_FLAGS
    set PLAYER_FLAGB_FACING, [hl]
    relpointer_destroy

    ;Create item(s)
    xor a
    ld [w_shop_itemsprite], a
    ld b, $08
    ld c, ITEM_ID_BALL
    farcall_0 entity_shopitem_create
    ld b, $28
    ld c, ITEM_ID_BALL
    farcall_0 entity_shopitem_create
    ld b, $48
    ld c, ITEM_ID_BALL
    farcall_0 entity_shopitem_create

    ;Prepare a couple vqueue transfers
    vqueue_enqueue_auto player_vprep_base
    ld a, bank(shop_vprep)
    ld [rROMB0], a
    ld de, shop_vprep
    ld b, 6
    call vqueue_enqueue_multi
    ld hl, shop_vprep_hud_tls

    ;Perform transfers
    call gameloop_loading

    ;Now we wait for the screen to turn on
    xor a
    ldh [rIF], a
    halt

    ;Set palette
    ld a, PALETTE_DEFAULT
    call set_palette_bgp
    ld a, PALETTE_INVERTED
    call set_palette_obp0

    ;Imagine we just drew a frame, now time for its V-blank
    call shop_vblank

    ;Enable certain interrupts
    ld a, IEF_VBLANK | IEF_STAT
    ldh [rIE], a
    ld a, STATF_LYC
    ldh [rSTAT], a
    xor a
    ldh [rIF], a

    ;Return
    reti
;



; Main entrypoint of the shop gameloop.  
; Lives in ROM0.
gameloop_shop::
    call gameloop_shop_setup

    ;This is where the gameloop repeats
    .main::

    ;Perform normal frame things
    call input
    call entsys_step

    ;Do some open-ness stuff
    ld hl, w_shop_preview_current
    ld a, [hl-]
    or a, a ;cp a, 0
    jr z, .preview_close
        ld a, [hl]
        cp a, SHOP_PREVIEW_OPEN
        jr z, .preview_done
        inc [hl]
        inc [hl]
        jr .preview_done
    ;

    .preview_close
        ld a, [hl]
        or a, a ;cp a, 0
        jr z, .preview_done
        dec [hl]
        dec [hl]
        jr .preview_done
    ;
    
    .preview_done

    ;Finish up sprites for this frame
    ldh a, [h_oam_active]
    ld h, a
    call sprite_finish

    ;Wait for Vblank
    .halting
        halt 

        ;Ignore if this wasn't V-blank
        ldh a, [rSTAT]
        and a, STATF_LCD
        cp a, STATF_VBL
        jr nz, .halting
    ;

    ;Run V-blank routine.
    call shop_vblank

    ;Repeat gameloop
    xor a
    ldh [rIF], a
    ei
    jr .main
;
