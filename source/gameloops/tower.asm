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



; V-blank routine for the tower gameloop.
; Assumes VRAM access.
; Lives in ROM0.
;
; Saves: none
tower_vblank::
    ;Set the correct LCDC flags
    ld a, LCDCF_ON | LCDCF_BLK21 | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_OBJ16
    ldh [rLCDC], a
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
    ld b, $81 ;gui
    ld de, $20 * 3
    call memset
    ld b, $82 ;platform
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
