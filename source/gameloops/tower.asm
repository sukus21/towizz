INCLUDE "hardware.inc"
INCLUDE "macros/lyc.inc"


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

; Background SCX when offscreen
DEF BACKGROUND_OFFSCREEN_SCX EQU SCRN_X + 5



SECTION "GAMELOOP TOWER", ROM0

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
    add a, $88
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

    ;Do DMA and return
    ld a, high(w_oam_hud)
    call h_dma
    ret
;



; Setup routine for tower gameloop.
; Assumes VRAM access.
; Enables interrupts and LCD when returning.
; Lives in ROM0.
;
; Saves: none
gameloop_tower_setup:
    ;Switch ROMX bank
    ld a, bank(tower_asset_tower)
    ld [rROMB0], a
    
    ;Copy tower tiles
    ld hl, vt_tower_tower
    ld bc, tower_asset_tower
    ld de, tower_asset_tower.end - tower_asset_tower
    call memcpy

    ;Copy platform tiles
    ld hl, vt_tower_platform
    ld bc, tower_asset_platform
    ld de, tower_asset_platform.end - tower_asset_platform
    call memcpy

    ;Copy HUD tiles
    ld hl, vt_tower_hud
    ld bc, tower_asset_hud
    ld de, tower_asset_hud.end - tower_asset_hud
    call memcpy

    ;Copy test tiles
    ld hl, vt_tower_testtiles
    ld bc, tower_asset_testtiles
    ld de, tower_asset_testtiles.end - tower_asset_testtiles
    call memcpy

    ;This part of the tilemap is invisible
    ld hl, vm_tower_tower
    ld b, $A4
    ld de, $20 * $20
    call memset

    ;Set tower tiles on background layer
    ld hl, vm_tower_tower + $0F
    ld c, 2
    ld a, $1E
    :
        ld [hl-], a
        sub a, c
        jr nc, :-
    ld hl, vm_tower_tower + $2F
    ld a, $1F
    :
        ld [hl-], a
        sub a, c
        jr nc, :-
    ;

    ;Set GUI tiles
    ld hl, vm_tower_hud
    ld b, $F0
    ld d, $20
    ld c, d
    call memset_short
    inc b
    ld c, d
    call memset_short
    inc b
    ld c, d
    call memset_short

    ;Set backdrop tiles on window layer
    ld hl, vm_tower_background
    ld b, $A0
    ld de, $20 * 26
    call memset

    ;Platform tiles
    ld hl, vm_tower_platform + $0F
    ld c, 2
    ld a, $9E
    :
        ld [hl-], a
        sub a, c
        bit 7, a
        jr nz, :-
    ld hl, vm_tower_platform + $2F
    ld a, $9F
    :
        ld [hl-], a
        sub a, c
        bit 7, a
        jr nz, :-
    ;

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

    ;Return
    ret 
;



; Tower gameloop.
; Does not return, resets stack.
; Lives in ROM0.
;
; Saves: none
gameloop_tower::
    call gameloop_tower_setup

    ; This is where the gameloop repeats.
    .mainloop
    call input
    ldh a, [h_input]

    ;Modify tower with the B button
    bit PADB_B, a
    jr z, :+
        ld hl, w_tower_ypos
        ld de, w_tower_height
        jr .select
    :

    ;Modify background with the A button
    bit PADB_A, a
    jr z, :+
        ld hl, w_background_ypos
        ld de, w_background_xpos
        jr .select
    :

    ;Modify platform with no button
    ld hl, w_platform_ypos
    ld de, w_platform_xpos

    ;Single-step or per-frame?
    .select
    bit PADB_SELECT, a
    jr z, :+
        ldh a, [h_input_pressed]
    :
    ld b, a

    ;Move vertical
    bit PADB_UP, b
    jr z, :+
        dec [hl]
    :
    bit PADB_DOWN, b
    jr z, :+
        inc [hl]
    :

    ;Move horizontal
    ld h, d
    ld l, e
    bit PADB_LEFT, b
    jr z, :+
        dec [hl]
    :
    bit PADB_RIGHT, b
    jr z, :+
        inc [hl]
    :

    ;Keep tower within cap
    ld a, [w_tower_height]
    ld hl, w_tower_ypos
    ld c, a
    ld a, [hl]
    cp a, $FF
    jr nz, :+
        dec c
        ld [hl], c
        jr .tower_adjusted
    :
    cp a, c
    jr c, .tower_adjusted
        ld [hl], 0
    .tower_adjusted

    ;Adjust window position
    ld hl, w_background_ypos
    ld a, [hl]
    and a, %00001111
    ld [hl], a

    ;Draw HUD
    call draw_hud

    ;Draw sprite-part of platform
    call tower_platform_sprites

    ;Wait for Vblank
    ldh a, [h_oam_active]
    ld h, a
    call sprite_finish
    .halting
        halt 

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
    jp .mainloop
;



; Draw sprite-parts of platform.
; Lives in ROM0.
;
; Saves: none
tower_platform_sprites:
    ld a, [w_background_xpos]
    ld b, a
    ld a, [w_platform_xpos]
    ld c, a

    ;Quick path
    sub a, b
    ret z

    ;Get number of sprites needed
    jr nc, :+
        ld a, c
    :
    dec a
    rra
    rra
    rra
    and a, %00011111
    inc a
    ld e, a ;iteration count -> E
    ld b, a
    sla b
    sla b

    ;Allocate sprites
    ld a, [h_oam_active]
    ld h, a
    call sprite_get

    ;Prepare sprite data
    ld a, [w_platform_ypos]
    add a, 16
    ld d, a ;sprite Y-position
    ld a, c ;sprite X-position
    ld c, $9E ;sprite tile

    ;Write data
    .loop
        ld [hl], d
        inc l
        ld [hl+], a
        sub a, 8
        ld [hl], c
        dec c
        dec c
        inc l
        ld [hl], OAMF_PAL0
        inc l
        dec e
        jr nz, .loop
    ;

    ;Return
    ret
;



; Draws a number in hexadecimal using sprites.
; Lives in ROM0.
;
; Input:
; - `hl`: Sprite data pointer
; - `a`: Number
; - `b`: X-position
; - `c`: Y-position
;
; Output:
; - `hl`: += 8
;
; Destroys: `af`, `d`
draw_byte:
    ;Upper nybble
    ld [hl], c
    inc l
    ld [hl], b
    inc l
    ld d, a
    swap a
    and a, %00001111
    rla
    set 7, a
    ld [hl+], a
    ld [hl], OAMF_PAL0
    inc l

    ;Lower nybble
    ld [hl], c
    inc l
    ld a, b
    add a, 8
    ld [hl+], a
    ld a, d
    and a, %00001111
    rla
    set 7, a
    ld [hl+], a
    ld [hl], OAMF_PAL0
    inc l

    ;Return
    ret 
;



; Subroutine for the tower gameloop.  
; Draws a couple sprites on the HUD.
;
; Saves: none
draw_hud:
    ;Get a couple sprites
    ld b, 4*8
    ld h, high(w_oam_hud)
    call sprite_get

    ;Draw platform positions
    ld a, [w_platform_xpos]
    ld bc, $11_10
    call draw_byte
    ld a, [w_platform_ypos]
    ld bc, $22_10
    call draw_byte

    ;Draw tower positions
    ;ld a, [w_tower_ypos]
    ;ld bc, $42_10
    ;call draw_byte
    ;ld a, [w_tower_height]
    ;ld bc, $53_10
    ;call draw_byte

    ;Draw background positions
    ld a, [w_background_xpos]
    ld bc, $73_10
    call draw_byte
    ld a, [w_background_ypos]
    ld bc, $84_10
    call draw_byte

    ;Cover up window layer on HUD
    ld h, high(w_oam_hud)
    ld b, 4
    call sprite_get
    ld [hl], $10
    inc l
    ld [hl], $A0
    inc l
    ld [hl], $F0
    inc l
    ld [hl], $00

    ;That's it, we are done drawing the HUD
    call sprite_finish
    ret
;



SECTION "TOWER ASSETS", ROMX

; Platform tileset.
tower_asset_platform::
    INCBIN "graphics/platform_test.tls"
.end

; Tower tileset.
tower_asset_tower::
    INCBIN "graphics/tower_test.tls"
.end

; HUD tileset.
tower_asset_hud::
    INCBIN "graphics/hud_test.tls"
.end

; Some test-tiles.
; TODO: make a proper tileset.
tower_asset_testtiles:
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

    dw `32112213
    dw `22112211
    dw `11221122
    dw `11221122
    dw `22112211
    dw `22112211
    dw `11221122
    dw `31221123

    dw `32112213
    dw `22112211
    dw `11221122
    dw `11221122
    dw `22112211
    dw `22112211
    dw `11221122
    dw `31221123
.end



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
