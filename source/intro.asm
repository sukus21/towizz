INCLUDE "hardware.inc"
INCLUDE "macros/color.inc"
INCLUDE "macros/memcpy.inc"

SECTION "INTRO", ROMX, ALIGN[8]

; Creates 32 colors, fading from white to the given color.
;
; Input:
; - 1: Red (0-31)
; - 2: Green (0-31)
; - 3: Blue (0-31)
MACRO white_fade
    DEF iteration = 1.0
    REPT 32
        DEF red = \1.0 + MUL((31.0 - \1.0), iteration)
        DEF green = \2.0 + MUL((31.0 - \2.0), iteration)
        DEF blue = \3.0 + MUL((31.0 - \3.0), iteration)
        color_t red >> 16, green >> 16, blue >> 16
        DEF iteration -= DIV(1.0, 31.0)
    ENDR
    
    ;Cleanup
    PURGE iteration
    PURGE red
    PURGE green
    PURGE blue
ENDM

; Raw palette data.
; Lives in ROM0.
intro_palettes:
    .yellow white_fade 31, 31,  0
    .red    white_fade 31,  0,  0
    .gray   white_fade 21, 21, 21
    .black  white_fade  0,  0,  0
;

; OAM sprite data for GBcompo logo.
; 
gbcompo_oam:
    ;"GB" top
    db $38, $48, $00, 0
    db $38, $50, $02, 0
    db $38, $59, $04, 0
    db $38, $61, $06, 0

    ;"GB" bottom
    db $3C, $48, $08, 0
    db $3C, $50, $0A, 0
    db $3C, $59, $0C, 0
    db $3C, $61, $0A, 0

    ;"COMPO" top
    db $4E, $30, $10, 0
    db $4E, $38, $12, 0
    db $4E, $40, $14, 0
    db $4E, $48, $16, 0
    db $4E, $50, $18, 0
    db $4E, $58, $1A, 0
    db $4E, $60, $1C, 0
    db $4E, $68, $1E, 0
    db $4E, $70, $20, 0
    db $4E, $78, $22, 0

    ;"COMPO" bottom + "2023" top
    db $5E, $31, $24, 0
    db $5E, $39, $26, 0
    db $5E, $41, $28, 0
    db $5E, $49, $2A, 0
    db $5E, $51, $2C, 0
    db $5E, $59, $2E, 0
    db $5E, $61, $30, 0
    db $5E, $69, $32, 0
    db $5E, $72, $24, 0
    db $5E, $7A, $0E, 0

    ;"2023" bottom
    db $6E, $3F, $34, 0
    db $6E, $47, $36, 0
    db $6E, $4F, $38, 0
    db $6E, $57, $3A, 0
    db $6E, $5F, $3C, 0
    db $6E, $67, $3E, 0
    db $6E, $6F, $40, 0

    ds $A0 - (@ - gbcompo_oam)
ASSERT low(gbcompo_oam) == 0

; Tilemap data for logo. 
; Contains a DMG- and CGB version.
; Lives in ROM0.
intro_tilemap:
    .cgb INCBIN "intro/sukus_cgb.tlm"
    .dmg INCBIN "intro/sukus_dmg.tlm"
;

; Tileset for logo and font.
; Lives in ROM0.
intro_tileset:
    INCBIN "intro/intro.tls"
    .end
;

; Graphics data for GBcompo logo.
gbcompo:
    ;Sprite tileset
    .spr INCBIN "intro/gbcompo23_sprites.tls"
    .spr_end

    ;Background tilemap
    .tlm INCBIN "intro/gbcompo23.tlm"
    .tlm_end
    
    ;Background tileset
    .tls INCBIN "intro/gbcompo23.tls"
    .tls_end
;



; Plays the "Sukus Production" splash screen.
; Routine will keep running until the animation is over, then return.
; Modifies screen data.
; Assumes LCD is turned on.
;
; Destroys: all
intro::

    ;Wait for VBLANK
    xor a
    ldh [rIF], a
    ld a, IEF_VBLANK
    ldh [rIE], a
    halt 

    ;There is Vblank!
    ;Disable LCD
    xor a
    ldh [rLCDC], a

    ;Copy font to VRAM
    ld hl, _VRAM + $1000
    ld bc, intro_tileset
    ld de, intro_tileset.end - intro_tileset
    call memcpy

    ;Copy tilemap
    xor a
    ldh [rVBK], a
    ld hl, _SCRN0
    ld bc, intro_tilemap

    ;DMG tilemap?
    ldh a, [h_is_color]
    or a, a ;cp a, 0
    jr nz, .skip_dmg
        ld bc, intro_tilemap.dmg
    .skip_dmg
    call mapcopy_screen

    ;Check if attributes should be set?
    ldh a, [h_is_color]
    or a, a ;cp a, 0
    jr z, .attrskip

        ;Set tile attributes
        ld a, 1
        ldh [rVBK], a 
        ld hl, _SCRN0
        ld b, 1
        ld de, $400
        call memset

        ;Make face use palette 0
        ld hl, _SCRN0 + 6 + (32 * 3)
        ld c, 8
        ld a, 0
        ld de, 24
        .face_loop
            ;Set data
            REPT 8
                ld [hl+], a
            ENDR

            ;Jump to next line or break
            add hl, de
            dec c
            jr nz, .face_loop
        ;
        xor a
        ldh [rVBK], a
    .attrskip

    ;Reenable LCD
    ld hl, rLCDC
    ld a, LCDCF_ON | LCDCF_BGON
    ld [hl], a

    ;Fade in
    call intro_fadein

    ;Show the still image for a bit
    .fadenone
        ;Wait for Vblank
        xor a
        ldh [rIF], a
        ld a, IEF_VBLANK
        ldh [rIE], a
        halt 

        ;Set default palette
        ld a, %11100100
        ldh [rBGP], a

        ;Count down
        ld hl, w_intro_timer
        dec [hl]
        ld a, $E0
        cp a, [hl]
        jr nz, .fadenone
    ;

    ;Waiting phase is OVER!
    ;Fade out
    call intro_fadeout

    ;Wait for Vblank again
    xor a
    ldh [rIF], a
    ld a, IEF_VBLANK
    ldh [rIE], a
    halt

    ;Disable LCD in preparation for GBcompo logo
    xor a
    ldh [rLCDC], a

    ;Copy background tiles to VRAM
    ld hl, _VRAM + $1000
    ld bc, gbcompo.tls
    ld de, $0800
    call memcpy
    res 4, h ;hl: $9800 => $8800
    ld de, gbcompo.tls_end - (gbcompo.tls + $0800)
    call memcpy

    ;Copy sprite tiles to VRAM
    ld hl, _VRAM
    ld bc, gbcompo.spr
    ld de, gbcompo.spr_end - gbcompo.spr
    call memcpy

    ;Copy tilemap
    ld hl, _SCRN0
    ld bc, gbcompo.tlm
    call mapcopy_screen

    ;DMA
    ld a, high(gbcompo_oam)
    call h_dma_sourced

    ;Reenable LCD
    ld hl, rLCDC
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BLK21 | LCDCF_OBJON | LCDCF_OBJ16
    ld [hl], a

    ;Fade logo in
    call intro_fadein

    ;Hold image for a bit
    .compo_wait
        ;Wait for Vblank
        xor a
        ldh [rIF], a
        ld a, IEF_VBLANK
        ldh [rIE], a
        halt 

        ;Set default palette
        ld a, %11100100
        ldh [rBGP], a
        ld a, %10010000
        ldh [rOBP0], a

        ;Count down
        ld hl, w_intro_timer
        dec [hl]
        ld a, $E0
        cp a, [hl]
        jr nz, .compo_wait
    ;

    ;Fade logo out
    call intro_fadeout

    ;Return
    ret
;



; Fades the screen from white.
; Assumes LCD is on.
; Modifies palette data.
;
; Destroys: all
intro_fadein:
    ;Set intro flags
    xor a
    ld [w_intro_timer], a
    ld [w_intro_state], a
    ldh [rBGP], a
    ldh [rOBP0], a

    ;Set default DMG palettes
    ld a, %11100100
    ld [w_buffer], a
    ld a, %10010000
    ld [w_buffer+1], a

    ;Fade in
    .fadein
        ;Wait for Vblank
        xor a
        ldh [rIF], a
        ld a, IEF_VBLANK
        ldh [rIE], a
        halt 

        ;Do the fading
        ld hl, w_intro_timer
        inc [hl]
        ld a, [hl]
        add a, a
        and a, %00111111
        ld c, a
        call intro_fading

        ;Are we done fading in?
        ld a, e
        cp a, $3E
        jr nz, .fadein
    ;

    ;Return
    ret
;



; Fades the screen to white.
; Assumes LCD is on.
; Modifies palette data.
;
; Destroys: all
intro_fadeout:
    ;Set flags
    xor a
    ld [w_intro_timer], a
    inc a ;ld a, 1
    ld [w_intro_state], a

    ;Fade colors out
    .fadeout
        ;Wait for Vblank (again)
        xor a
        ldh [rIF], a
        ld a, IEF_VBLANK
        ldh [rIE], a
        halt 

        ;Fade out
        ld hl, w_intro_timer
        dec [hl]
        ld a, [hl]
        add a, a
        and a, %00111111
        ld c, a
        call intro_fading

        ;Are we done yet?
        ld a, c
        cp a, $00
        jr nz, .fadeout
    ;

    ;Return
    ret
;



; Subroutine for `intro`.
; Modifies CGB- or DMG palettes (depends on mode).
; Assumes VRAM access.
;
; Input:
; - `c`: Opacity
;
; Saves: `c`
intro_fading:

    ;Check if this is a color machine or not
    ldh a, [h_is_color]
    or a, a ;cp a, 0
    jr nz, .color_real

        ;DMG mode
        ld a, c
        ld e, c
        and a, %00001111
        or a, a ;cp a, 0
        ret nz

        ;Set values
        ldh a, [rBGP]
        ld d, a
        ldh a, [rOBP0]
        ld e, a
        ld hl, w_buffer ;stores DMG palette
        ld a, [w_intro_state]
        cp a, 1
        jr z, .fadeout
            ;Fade in BGP
            ld a, d
            rr [hl]
            rra
            rr [hl]
            rra
            ldh [rBGP], a

            ;Fade in OBP0
            inc l
            ld a, e
            rr [hl]
            rra
            rr [hl]
            rra
            ldh [rOBP0], a

            ;Return
            ret 

        .fadeout
            ;Fade out BGP
            sla d
            sla d
            ld a, d
            ldh [rBGP], a

            ;Fade out OBP0
            sla e
            sla e
            ld a, d
            ldh [rOBP0], a

            ;Return
            ret
        ;

    ;CGB mode
    .color_real
        ld de, w_buffer

        ;Palette 1, logo
        ld hl, intro_palettes.yellow
        call intro_fade_color
        ld hl, intro_palettes.red
        call intro_fade_color
        ld hl, intro_palettes.gray
        call intro_fade_color
        ld hl, intro_palettes.black
        call intro_fade_color

        ;Palette 2, text
        ;White, doesn't need to change
        ld a, $FF
        ld [de], a
        inc e
        ld [de], a
        inc e

        ld hl, intro_palettes.black
        call intro_fade_color
        ld hl, intro_palettes.gray
        call intro_fade_color
        ld hl, intro_palettes.black
        call intro_fade_color
        
        ;Copy palettes
        ld e, c ;save this from being clobbered
        ld hl, w_buffer
        xor a
        call palette_copy_bg
        call palette_copy_bg

        ;Return
        ld c, e
        ret 
    ;
;



; Helper routine for fading.
; Only used for CGB colors.
;
; Input:
; - `c`: Opacity
; - `de`: Color desination
; - `hl`: Color fade table
;
; Saves: `bc`
intro_fade_color:
    ;Create proper index
    ld a, c
    add a, l
    ld l, a

    ;Copy data
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, [hl]
    ld [de], a
    inc e

    ;Return
    ret
;



; Small custom memory copier.
; 20*18 (360) bytes, enough to fill the screen.
; Every 20 copied bytes, 12 bytes are skipped.
;
; Input:
; - `hl`: Destination
; - `bc`: Source
;
; Destroys: `de`
mapcopy_screen::
    ld e, 18

    .loop
        ;Copy tilemap to screen, 20 tiles at a time
        ld d, 20
        memcpy_custom hl, bc, d

        ;Skip data pointer ahead
        ld a, l
        add a, 32 - 20
        jr nc, :+
            inc h
        :
        ld l, a

        ;End of loop
        dec e
        jr nz, .loop
    ;

    ;Return
    ret
;
