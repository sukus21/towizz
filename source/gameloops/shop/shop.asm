INCLUDE "entsys.inc"
INCLUDE "shop.inc"
INCLUDE "macros/color.inc"
INCLUDE "macros/farcall.inc"
INCLUDE "macros/relpointer.inc"
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
    call entsys_clear
    farcall_0 entity_player_create
    relpointer_init l, ENTVAR_BANK
    relpointer_move ENTVAR_PLAYER_XPOS
    xor a
    ld [hl+], a
    ld a, 16*8
    ld [hl-], a
    relpointer_move ENTVAR_PLAYER_FLAGS
    set PLAYER_FLAGB_FACING, [hl]
    relpointer_destroy

    ;Prepare a couple vqueue transfers
    call vqueue_clear
    vqueue_enqueue_auto player_vprep_base
    ld a, bank(shop_vprep)
    ld [rROMB0], a
    ld de, shop_vprep
    ld b, 7
    call vqueue_enqueue_multi
    ld hl, shop_vprep_hud_tls
    xor a
    ld [w_vqueue_writeback], a

    ;Perform transfers
    ld a, IEF_VBLANK
    ldh [rIE], a
    .vqueue_wait
        xor a
        ldh [rIF], a
        halt

        ;Vblank, do transfer
        call vqueue_execute

        ;Are we done yet?
        ld a, [w_vqueue_writeback]
        cp a, 8
        jr nz, .vqueue_wait
        
        ;Reset this
        xor a
        ld [w_vqueue_writeback], a
    ;

    ;Set palette
    ld a, PALETTE_DEFAULT
    call set_palette_bgp
    ld a, PALETTE_INVERTED
    call set_palette_obp0

    ;Imagine we just drew a frame, now time for its V-blank
    call shop_vblank

    ;Now we wait for the screen to turn on
    xor a
    ldh [rIF], a
    halt

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
