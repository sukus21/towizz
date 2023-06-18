INCLUDE "hardware.inc"
INCLUDE "macros/color.inc"

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
    cp a, 0
    jr nz, .skip_dmg
        ld a, %11100100 ;default DMG palette
        ld [w_buffer], a
        ld bc, intro_tilemap.dmg
    .skip_dmg

    ;Copy tilemap to screen, 20 tiles at a time
    .mapcopy_loop
        ;Copy data
        ld de, 20
        call memcpy

        ;Increment data pointer
        ld a, l
        add a, 32 - 20
        jr nc, :+
            inc h
        :

        ;End of loop
        ld l, a
        add a, h
        cp a, $9A + $40
        jr nz, .mapcopy_loop
    ;

    ;Check if attributes should be set?
    ldh a, [h_is_color]
    cp a, 0
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

    ;Set intro flags
    xor a
    ld [w_intro_timer], a
    ld [w_intro_state], a

    ;Set DMG palette
    ldh [rBGP], a

    ;Reenable LCD
    ld hl, rLCDC
    ld a, LCDCF_ON | LCDCF_BGON
    ld [hl], a

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
    ld a, 1
    ld [w_intro_state], a
    ld [hl], 0

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

    ;Wait for Vblank again
    xor a
    ldh [rIF], a
    ld a, IEF_VBLANK
    ldh [rIE], a
    halt

    ;Resume whatever was happening
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
    cp a, 0
    jr nz, .color_real

        ;DMG mode
        ld a, c
        ld e, c
        and a, %00001111
        cp a, 0
        ret nz

        ;Set values
        ldh a, [rBGP]
        ld b, a
        ld hl, w_buffer ;stores DMG palette
        ld a, [w_intro_state]
        cp a, 1
        jr z, .fadeout
            ;Fade in
            rr [hl]
            rr b
            rr [hl]
            rr b
            ld a, b
            ldh [rBGP], a
            ret 

        .fadeout
            ;Fade out
            sla b
            sla b
            ld a, b
            ldh [rBGP], a
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
