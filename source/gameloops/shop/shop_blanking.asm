INCLUDE "hardware.inc"
INCLUDE "shop.inc"
INCLUDE "macros/lyc.inc"

SECTION "SHOP VBLANK+HBLANK", ROM0

; V-blank routine for shop gameloop.  
; Assumes VRAM access.  
; Lives in ROM0.
shop_vblank::
    ;VRAM transfers
    call vqueue_execute

    ;DMA
    ld a, high(w_oam_hud)
    call h_dma

    ;Prepare to display HUD
    ld a, SHOP_LCDC_HUD
    ldh [rLCDC], a
    ld a, SHOP_SCY_HUD
    ldh [rSCY], a

    ;Set HUD interrupt
    ld a, SHOP_LYC_HUD
    ldh [rLYC], a
    LYC_set_jumppoint shop_hblank_hud

    ;Return
    ret
;



; H-blank routine for shop gameloop.
; I designed my tiles in a bad way, so I have to make up for it with code.  
; Lives in ROM0.
;
; Saves: all
shop_hblank_hud::
    push af

    ;Wait for H-blank
    LYC_wait_hblank

    ;Show the background
    ld a, SHOP_LCDC_BACKGROUND
    ldh [rLCDC], a
    ld a, SHOP_SCY_BACKGROUND
    ldh [rSCY], a

    ;Return
    ei
    pop af
    ret
;
