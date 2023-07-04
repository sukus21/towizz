INCLUDE "hardware.inc"
INCLUDE "macros/lyc.inc"


SECTION "GAMELOOP TOWER", ROM0

; Some test-tiles.
; Lives in ROM0.
; TODO: make a proper tileset.
; TODO: move to ROMX.
tower_tiles:
    dw `30000003
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `30000003

    dw `31111113
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `31111113

    dw `32222223
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `32222223

    dw `23333332
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `23333332

    dw `30110013
    dw `00110011
    dw `11001100
    dw `11001100
    dw `00110011
    dw `00110011
    dw `11001100
    dw `31001103
.end
; Height of the HUD.
DEF HUD_HEIGHT EQU $14

; Coordinate for SCX when displaying HUD.
DEF HUD_SCX EQU $00

; Coordniate for SCY when displaying HUD.
DEF HUD_SCY EQU -$30

; Height of the platform.
DEF PLATFORM_HEIGHT EQU $18

; Resting position of platform when not in use
DEF PLATFORM_DISABLE EQU SCRN_Y + 1

; Platform scroll position
DEF PLATFORM_SCY EQU -$18



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

    ;Wait for H-blank
    LYC_wait_hblank

    ;Move background
    ld a, l
    cpl
    ldh [rSCY], a

    ;Set LCDC flags
    ld a, LCDCF_ON | LCDCF_BLK21 | LCDCF_BGON | LCDCF_BG9800 | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_OBJON | LCDCF_OBJ16
    ldh [rLCDC], a

    ;Return
    pop hl
    pop af
    reti
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

    ;Return
    pop hl
    pop af
    reti
;



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

    ;Reset background for HUD
    ld a, HUD_SCX
    ldh [rSCX], a
    ld a, HUD_SCY
    ldh [rSCY], a

    ;Reset window position
    ldh a, [h_background_xpos]
    ldh [rWX], a
    ldh a, [h_background_ypos]
    ldh [rWY], a

    ;Set the correct LCDC flags
    ld a, LCDCF_ON | LCDCF_BLK21 | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_OBJ16
    ldh [rLCDC], a

    ;Do interrupt when HUD is drawn
    LYC_set_jumppoint tower_hblank_segment
    ld a, HUD_HEIGHT-1
    ldh [rLYC], a

    ;Set First tower interrupt position
    ldh a, [h_tower_ypos]
    ld e, a
    ld a, HUD_HEIGHT-1
    sub a, e
    ldh [h_tower_lyc], a

    ;platform start -> b
    ldh a, [h_platform_ypos]
    ld b, a
    cp a, SCRN_Y
    jr nz, :+
        ;Disable platform, or the LYC interrupt will clash with Vblank
        .no_platform
        ld a, PLATFORM_DISABLE
        ldh [h_platform_ypos], a
        ret
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
    ret nc
    
    .yes_platform
    LYC_set_jumppoint tower_hblank_platform

    ;That's it I guess
    ret
;



; Tower gameloop.
; Does not return, resets stack.
; Lives in ROM0.
;
; Saves: none
gameloop_tower::
    
    ;Copy tiles to VRAM
    ld hl, $8800
    ld bc, tower_tiles
    ld de, tower_tiles.end - tower_tiles
    call memcpy

    ;Set tower tiles on background layer
    ld hl, $9800
    ld b, $83 ;tower
    ld de, $20 * 2
    call memset
    ld b, $84 ;invisible
    ld de, $20 * 30
    call memset

    ;Set backdrop tiles on window layer
    ld b, $80
    ld de, $20 * 26
    call memset
    ld de, $20 * 3
    call memset
    ld b, $82 ;platform
    ld b, $81 ;hud
    ld de, $20 * 3
    call memset

    ;Clear OAM mirror
    ld hl, w_oam_mirror
    ld a, 80
    ld [hl+], a
    ld a, 124
    ld [hl+], a
    ld a, $84
    ld [hl+], a
    xor a
    ld [hl+], a
    ld b, a
    ld de, $A0
    call memset
    call h_dma_routine

    ;Set palette
    ld a, $E4
    ldh [rBGP], a
    ldh [rOBP0], a

    ;Call regular V-blank routine
    call tower_vblank

    ;Set STAT mode
    ld a, STATF_LYC
    ldh [rSTAT], a

    ;Reset interrupt registers
    xor a
    ldh [rIF], a
    ld a, IEF_STAT | IEF_VBLANK
    ldh [rIE], a
    ei

    ;Re-enable LCD
    ld a, LCDCF_BLK21 | LCDCF_BG9800 | LCDCF_WIN9C00 | LCDCF_BGON | LCDCF_WINON | LCDCF_ON
    ldh [rLCDC], a


    ; This is where the gameloop repeats.
    .mainloop

    call input
    ldh a, [h_input]
    ld hl, w_platform_ypos

    bit PADB_B, a
    jr z, :+
        ld hl, w_tower_height
    :

    bit PADB_SELECT, a
    jr z, :+
        ldh a, [h_input_pressed]
    :
    ld b, a

    ;Move platform
    bit PADB_UP, b
    jr z, :+
        dec [hl]
    :
    bit PADB_DOWN, b
    jr z, :+
        inc [hl]
    :

    ;Move tower
    ld hl, w_tower_ypos
    bit PADB_LEFT, b
    jr z, :+
        inc [hl]
    :
    bit PADB_RIGHT, b
    jr z, :+
        dec [hl]
    :

    ;Scrolled below the thing?
    ld a, $FF
    cp a, [hl]
    ld a, [w_tower_height]
    jr nz, :+
        dec a
        ld [hl], a
        inc a
    :
    dec a
    cp a, [hl]
    jr nc, :+
        ld [hl], 0
    :

    ;Wait for Vblank
    .halting
        halt 
        xor a
        ldh [rIF], a

        ;Ignore if this wasn't V-blank
        ldh a, [rSTAT]
        and a, STATF_LCD
        cp a, STATF_VBL
        jr nz, .halting
    ;

    ;Call V-blank routine
    call tower_vblank

    ;Repeat gameloop
    xor a
    ldh [rIF], a
    ei
    jr .mainloop
;



SECTION UNION "TOWER VRAM", VRAM[$8000]
    ;Reserved for future use
    ds $10 * $80

    ; Location of platform tileset.
    vt_tower_platform:: ds $10 * $20

    ; Test tiles location.
    vt_tower_testtiles:: ds $10 * $10

    ;Reserved for future use
    ds $10 * $40

    ; HUD tiles
    vt_tower_hud:: ds $10 * $10

    ;Location of tower tileset.
    vt_tower_tower:: ds $10 * $20

    ;Reserved for future use
    ds $10 * $60

    ; Location of tower tilemap.
    ; Spans a full background layer, at 32x32 tiles.
    vm_tower_tower:: ds $20 * $20

    ; Location of background tilemap.
    ; Drawn using the window layer.
    ; Most of the right side of this segment is unused.
    ; (at most) 20 * 26 tiles.
    vm_tower_background:: ds $20 * 26


    ; Location of HUD tilemap.
    ; HUD elements go here.
    ; 32 * 3 tiles.
    vm_tower_hud:: ds $20 * 3

    ; Location of platform tilemap.
    ; I have not yet decided if I'll need the full 3-tile length.
    ; Still reserving it, just in case.
    ; 32 * 3 tiles.
    vm_tower_platform:: ds $20 * 3
;
