INCLUDE "hardware.inc"
INCLUDE "tower.inc"
INCLUDE "macros/color.inc"
INCLUDE "macros/farcall.inc"
INCLUDE "macros/lyc.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/tower.inc"


SECTION "GAMELOOP TOWER", ROM0

; Setup routine for tower gameloop.  
; Enables interrupts when returning.  
; Assumes LCD is turned on.  
; Lives in ROM0.
;
; Saves: none
gameloop_tower_setup:
    di

    ;Set tower flags
    ld a, TOWERMODEF_TOWER_REPEAT
    ld [w_tower_flags], a
    ld a, high(w_oam1)
    ldh [h_oam_active], a

    ;Perform VRAM transfers
    ld b, 3
    call tower_background_fullqueue
    call gameloop_loading

    ld a, bank(tower_vprep)
    ld [rROMB0], a
    ld de, tower_vprep
    ld b, 7
    call vqueue_enqueue_multi
    vqueue_enqueue_auto player_vprep_base
    call gameloop_loading

    ;Initialize entity system
    call entsys_clear
    farcall entity_towerdemo_create
    farcall entity_player_create

    ;Call regular V-blank routine
    call tower_buffer_prepare
    call tower_vblank

    ;Set STAT mode
    ld a, STATF_LYC
    ldh [rSTAT], a

    ;Reset interrupt registers
    ld a, IEF_STAT | IEF_VBLANK
    ldh [rIE], a
    xor a
    ldh [rIF], a
    ei

    ;Prepare colors
    ld a, PALETTE_DEFAULT
    ld [w_bgp+1], a
    ld [w_obp0+1], a
    ld a, COLOR_FADESTATE_IN
    call transition_fade_init

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
    .main::
    call input
    call entsys_step
    call tower_buffer_prepare
    call draw_hud

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
    jr .main
;



; Truncates tower Y-position automatically.  
; Skipped if repeat-mode is disabled.  
; Lives in ROM0.
;
; Destroys: `af`, `b`
tower_truncate::
    ld a, [w_tower_flags]
    bit TOWERMODEB_TOWER_REPEAT, a
    ret z

    ;Compare sizes
    push hl
    ld a, [w_tower_height]
    ld b, a
    ld hl, w_tower_ypos+1
    ld a, [hl]
    cp a, b
    jr c, .return

    ;Subtract height a couple times
    bit 7, a
    jr z, .adjust_sub
    .adjust_add
        add a, b
        jr nc, .adjust_add
        ld [hl], a
        jr .return
    .adjust_sub
        sub a, b
        jr nc, .adjust_sub
        add a, b
        ld [hl], a
    ;

    ;Return
    .return
    pop hl
    ret
;



; Updates positions of tower elements based on speeds.  
; Lives in ROM0.
;
; Saves: `de`
tower_update::
    ;Do tower first
    ld hl, w_tower_yspeed
    call .increment

    ;Now do platform position
    ld hl, w_platform_yspeed
    call .increment
    call .increment

    ;Lastly do background
    ld hl, w_background_yspeed
    call .increment
    call .increment

    ;Clamp background scroll position
    ld hl, w_background_ypos+1
    ld a, [hl]
    and a, %00001111
    ld [hl], a

    ;Clamp tower position.
    call tower_truncate

    ;Return
    ret

    ; Input:
    ; - `hl`: Y-speed
    .increment
        ;Read speed1
        ld a, [hl+]
        ld c, a
        ld a, [hl+]
        ld b, a

        ;Add speed to position
        ld a, c
        add a, [hl]
        ld [hl+], a
        ld a, b
        adc a, [hl]
        ld [hl+], a

        ;Return
        ret
    ;
;



; Prepare the tower buffer.
; This saves me from doing it in the middle of V-blank.  
; Lives in ROM0.
;
; Destroys: all
tower_buffer_prepare:
    ld hl, w_tower_buffer

    ;Flags
    ld a, [w_tower_flags]
    ld b, a
    ld [hl+], a

    ;LYC
    ld a, [w_tower_ypos+1]
    ld c, a
    ld a, TOWER_HUD_HEIGHT-1
    sub a, c
    ld [hl+], a

    ;Tower variables
    ld a, c
    ld [hl+], a
    ld a, [w_camera_xpos+1]
    ld d, a
    add a, $80
    ld [hl+], a
    ld a, [w_tower_height]
    ld [hl+], a
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_WINON | LCDCF_OBJON | LCDCF_BLK21 | LCDCF_OBJ16 | LCDCF_BG9C00
    bit TOWERMODEB_WINDOW_TILEMAP, b
    jr z, :+
        set LCDCB_WIN9C00, a
    :
    ld c, a ;save for later
    bit TOWERMODEB_TOWER_TILEMAP, b
    jr nz, :+
        res LCDCB_BG9C00, a
    :
    ld [hl+], a

    ;Platform variables
    ld a, [w_platform_ypos+1]
    ld [hl+], a
    ld a, [w_platform_xpos+1]
    sub a, d
    ld d, a
    ld [hl+], a
    ld a, [w_platform_height]
    ld [hl+], a
    ld a, c ;saved from earlier
    ld [hl+], a

    ;Background variables
    ld a, [w_background_ypos+1]
    ld [hl+], a
    ld a, [w_camera_xpos+1]
    ld e, a
    ld a, $87
    sub a, e
    ld [hl+], a

    ;Do platform sprites
    sub a, 7
    ld e, a
    ld a, d
    sub a, e
    ret z
    jr nc, :+
        ld a, d
    :

    ;Get number of required sprites
    dec a
    rra
    rra
    rra
    and a, %00011111
    inc a
    add a, a
    add a, a
    ld b, a

    ;Allocate sprites
    ld a, [h_oam_active]
    ld h, a
    call sprite_get
    srl b
    srl b

    ;Prepare sprite data
    ld a, [w_platform_ypos+1]
    add a, 16
    ld c, a ;sprite Y-position
    ld a, d ;sprite X-position
    ld e, $9E ;sprite tile

    ;Write data
    .loop
        ld [hl], c
        inc l
        ld [hl+], a
        sub a, 8
        ld [hl], e
        dec e
        dec e
        inc l
        ld [hl], OAMF_PAL0
        inc l
        dec b
        jr nz, .loop
    ;

    ;Return
    ret
;



; VRAM values are only properly mapped when in the tower gameloop.
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
tower_draw_byte::
    ;Upper nybble
    ld [hl], c
    inc l
    ld [hl], b
    inc l
    ld d, a
    swap a
    and a, %00001111
    rla
    add a, VTI_TOWER_PLATFORM
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
    add a, VTI_TOWER_PLATFORM
    ld [hl+], a
    ld [hl], OAMF_PAL0
    inc l

    ;Return
    ret 
;



; Subroutine for the tower gameloop.  
; Draws a couple sprites on the HUD.  
; Lives in ROM0.
;
; Saves: none
draw_hud:
    /*
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
    ld a, [w_tower_ypos]
    ld bc, $42_10
    call draw_byte
    ld a, [w_tower_height]
    ld bc, $53_10
    call draw_byte

    ;Draw background positions
    ld a, [w_background_xpos]
    ld bc, $73_10
    call draw_byte
    ld a, [w_background_ypos]
    ld bc, $84_10
    call draw_byte
    */

    ;Cover up window layer on HUD
    ld h, high(w_oam_hud)
    ld b, 4
    call sprite_get
    ld [hl], $10
    inc l
    ld [hl], $A0
    inc l
    ld [hl], VTI_TOWER_HUD
    inc l
    ld [hl], $00

    ;That's it, we are done drawing the HUD
    call sprite_finish
    ret
;
