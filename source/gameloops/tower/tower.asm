INCLUDE "hardware.inc"
INCLUDE "macros/lyc.inc"
INCLUDE "tower.inc"


SECTION "GAMELOOP TOWER", ROM0

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
    call set_palette_bgp
    call set_palette_obp0

    ;Clear entity system
    call entsys_clear

    ;Allocate platform tester
    call entsys_new16
    ld h, b
    ld l, c
    ld [hl], bank(entity_platform_test)
    inc l
    inc l
    ld [hl], low(entity_platform_test)
    inc l
    ld [hl], high(entity_platform_test)

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
    call entsys_step

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
