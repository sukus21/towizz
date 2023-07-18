INCLUDE "hardware.inc"
INCLUDE "macros/lyc.inc"
INCLUDE "tower.inc"

SECTION "TOWER VBLANK+HBLANK", ROM0

; V-blank routine for the tower gameloop.
; Assumes VRAM access.
; Lives in ROM0.
;
; Saves: none
tower_vblank::
    ;Copy buffered scroll positions
    ld hl, w_tower_xpos
    ld bc, h_tower_xpos
    REPT 10
        ld a, [hl+]
        ld [bc], a
        inc c
    ENDR
    ldh a, [h_background_xpos]
    add a, 7
    ldh [h_background_xpos], a

    ;Flip selected OAM mirror
    ldh a, [h_oam_active]
    cpl
    add a, low(high(w_oam2) + high(w_oam1) + 1)
    ldh [h_oam_active], a

    ;Reset background for HUD
    ld a, HUD_SCX
    ldh [rSCX], a
    ld a, HUD_SCY
    ldh [rSCY], a

    ;Reset window position
    ld a, BACKGROUND_OFFSCREEN_SCX
    ldh [rWX], a
    ldh a, [h_background_ypos]
    ldh [rWY], a

    ;Set the correct LCDC flags
    ld a, LCDCF_ON | LCDCF_BLK21 | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_OBJON | LCDCF_OBJ16
    ldh [rLCDC], a

    ;Set mid-hud interrupt
    ld a, $0F
    ldh [rLYC], a
    LYC_set_jumppoint tower_hblank_gui

    ;Execute VRAM transfers
    call vqueue_execute

    ;Do DMA and return
    ld a, high(w_oam_hud)
    call h_dma
    ret
;



; H-blank routine for the tower gameloop.
; Called a bit before the end of the GUI.
; Performs DMA.
; Lives in ROM0.
tower_hblank_gui::
    push af
    push bc

    ;Do interrupt when HUD is drawn
    LYC_set_jumppoint tower_hblank_segment
    ld a, HUD_HEIGHT-1
    ldh [rLYC], a
    
    ;Set First tower interrupt position
    ldh a, [h_tower_ypos]
    ld c, a
    ld a, HUD_HEIGHT-1
    sub a, c
    ldh [h_tower_lyc], a

    ;Platform drawn entirely with sprites?
    ldh a, [h_background_xpos]
    sub a, 7
    ld b, a
    ldh a, [h_platform_xpos]
    cp a, b
    jr c, .no_platform

    ;platform start -> b
    ldh a, [h_platform_ypos]
    ld b, a
    cp a, SCRN_Y
    jr nz, :+
        ;Disable platform, or the LYC interrupt will clash with Vblank
        .no_platform
        ld a, PLATFORM_DISABLE
        ldh [h_platform_ypos], a
        jr .lyc_isset
    :

    ;platform end -> c
    ld a, [w_platform_height]
    add a, b
    ld c, a

    ;Skip platform?
    cp a, HUD_HEIGHT
    jr z, .no_platform
    jr c, .no_platform

    ;Start by drawing platform?
    cp a, b
    jr c, .yes_platform

    ld a, b
    cp a, HUD_HEIGHT
    jr z, .yes_platform
    jr nc, .lyc_isset
    
    .yes_platform
    LYC_set_jumppoint tower_hblank_platform
    .lyc_isset

    ;Get OAM mirror for DMA
    ldh a, [h_oam_active]
    cpl
    add a, low(high(w_oam1) + high(w_oam2) + 1)
    ld b, a

    LYC_wait_hblank
    ld a, LCDCF_ON | LCDCF_BLK21 | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_WINOFF | LCDCF_OBJOFF
    ldh [rLCDC], a
    ld a, b
    call h_dma

    ;Return
    ei
    pop bc
    pop af
    ret
;



; H-blank routine for the tower gameloop.
; Called when drawing a segment.
; Switches to drawing platform when the time comes.
; Lives in ROM0.
;
; Saves: all
tower_hblank_segment::
    push af
    push hl

    ;Platform Y-position -> H
    ldh a, [h_platform_ypos]
    ld h, a
    dec h

    ;Next segment interrupt position
    ldh a, [h_tower_lyc]
    ld l, a
    ldh a, [h_tower_height]
    add a, l

    ;Compare with platform position
    cp a, h
    jr c, .tower

        ;Apply platform settings
        ld a, h
        ldh [rLYC], a
        LYC_set_jumppoint tower_hblank_platform
        jr :+
    .tower
        ;Save LYC position
        ldh [rLYC], a
        ldh [h_tower_lyc], a
    :

    ;Camera X
    ldh a, [h_background_xpos]
    cpl
    add a, $08
    ld h, a

    ;Wait for H-blank
    LYC_wait_hblank

    ;Move background
    ld a, l
    cpl
    ldh [rSCY], a
    ld a, h
    ldh [rSCX], a

    ;Move background into view
    ldh a, [h_background_xpos]
    ldh [rWX], a

    ;Set LCDC flags
    ld a, LCDCF_ON | LCDCF_BLK21 | LCDCF_BGON | LCDCF_BG9800 | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_OBJON | LCDCF_OBJ16
    ldh [rLCDC], a

    ;Return
    ei
    pop hl
    pop af
    ret
;



; H-blank routine for the tower gameloop.
; Called when drawing the platform.
; Lives in ROM0.
;
; Saves: all
tower_hblank_platform::
    push af
    push hl
    
    ;Set next interrupt
    ldh a, [h_tower_height]
    ld l, a
    ldh a, [h_platform_ypos]
    ld h, a
    ldh a, [h_platform_height]
    add a, h
    dec a
    ldh [rLYC], a
    ld h, a
    LYC_set_jumppoint tower_hblank_segment

    ;Set next segment interrupt
    ldh a, [h_tower_lyc]
    .loop
        add a, l
        cp a, h
        jr z, .loop
        jr c, .loop
    :
    sub a, l
    ldh [h_tower_lyc], a

    ;Calculate background position
    ldh a, [h_platform_ypos]
    ld h, a
    ld a, PLATFORM_SCY
    sub a, h
    ld h, a
    ldh a, [h_platform_xpos]
    cpl
    add a, $81
    ld l, a

    ;This will make the section routine faster
    ld a, PLATFORM_DISABLE
    ldh [h_platform_ypos], a

    ;Wait for H-blank
    LYC_wait_hblank

    ;Set LCDC mode
    ld a, LCDCF_ON | LCDCF_BLK21 | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_OBJON | LCDCF_OBJ16
    ldh [rLCDC], a

    ;Set background position
    ld a, h
    ldh [rSCY], a
    ld a, l
    ldh [rSCX], a

    ;Move background into view
    ldh a, [h_background_xpos]
    ldh [rWX], a

    ;Return
    ei
    pop hl
    pop af
    ret
;
