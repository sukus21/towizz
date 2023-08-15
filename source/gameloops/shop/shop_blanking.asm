

SECTION "SHOP VBLANK+HBLANK", ROM0

; Assumes VRAM access.  
; Lives in ROM0.
shop_vblank::
    ;VRAM transfers
    call vqueue_execute

    ;DMA
    ld a, high(w_oam_hud)
    call h_dma

    ;Return
    ret
;
