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
    ld b, 1
    call tower_sprite_alloc
    farcall rectangle_points_load
    farcall entity_player_load
    farcall entity_knightling_load
    ld de, VT_TOWER_PARTICLE
    farcall entity_particle_load
    ld de, VT_TOWER_COIN
    farcall entity_coin_load
    call gameloop_loading

    ld a, bank(tower_vprep)
    ld [rROMB0], a
    ld de, tower_vprep
    ld b, 6
    call vqueue_enqueue_multi
    call gameloop_loading

    ;More loading
    call painter_item_slots
    call gameloop_loading

    ;Initialize entity system
    call entsys_clear
    farcall entity_player_create
    ;ld bc, $8050
    ;farcall entity_knightling_create
    ;farcall entity_towerdemo_create

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
    bit PADB_SELECT, c
    ld bc, $8028
    farcall nz, entity_coin_create
    call entsys_step
    call draw_hud
    call tower_background_handler
    call tower_buffer_prepare
    call tower_update

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
    cp a, 16
    jr c, :+
        xor a
        ld [hl], a
        call tower_background_step
    :

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
    ld e, VTI_TOWER_PLATFORM_END - 2 ;sprite tile

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
    ;Update coin animation
    ld hl, w_coin_animate
    inc [hl]

    ;Cover up window layer on HUD
    ld h, high(w_oam_hud)
    ld b, 8
    call sprite_get
    ld a, $10
    ld [hl+], a
    ld a, $A0
    ld [hl+], a
    ld a, VTI_TOWER_HUD
    ld [hl+], a
    xor a
    ld [hl+], a
    ld a, $18
    ld [hl+], a
    ld a, $A0
    ld [hl+], a
    ld a, VTI_TOWER_HUD
    ld [hl+], a
    xor a
    ld [hl+], a

    ;Draw equipment durability
    ld a, [w_durability_equipment]
    ld c, a
    ld b, 6*4
    call sprite_get
    ld b, 9*8
    ld e, 3
    call .durability

    ;Draw weapon durability
    ld a, [w_durability_weapon]
    ld c, a
    ld b, 6*4
    call sprite_get
    ld b, 14*8
    ld e, 3
    call .durability

    ;Draw coin
    ld de, $0408
    call coin_draw

    ;Draw amount of monee
    ld a, [w_money]
    call bin2bcd
    ld c, a
    ld e, $14
    ld d, $11
    call .number

    ;Draw health
    ld b, 4
    call sprite_get
    ld a, $18
    ld [hl+], a
    ld a, $0C
    ld [hl+], a
    ld a, VTI_TOWER_HUD+12
    ld [hl+], a
    ld [hl], 0
    ld a, [w_player_health]
    call bin2bcd
    ld c, a
    ld e, $14
    ld d, $19
    call .number

    ;That's it, we are done drawing the HUD
    call sprite_finish
    ret

    .durability
        ld a, $0E
        ld [hl+], a
        ld a, b
        ld [hl+], a
        dec c
        bit 7, c
        ld a, VTI_TOWER_HUD+3
        jr z, :+
            dec a
        :
        ld d, a
        ld [hl+], a
        xor a
        ld [hl+], a

        ld a, $16
        ld [hl+], a
        ld a, b
        ld [hl+], a
        add a, 5
        ld b, a
        ld a, d
        ld [hl+], a
        ld a, OAMF_YFLIP
        ld [hl+], a

        dec e
        jr nz, .durability
        ret
    ;

    .number

        ;Draw highest digit maybe
        ld a, c
        and a, %11110000
        jr z, :+
            ld b, 4
            call sprite_get
            ld a, d
            ld [hl+], a
            ld a, e
            ld [hl+], a
            add a, 6
            ld e, a
            ld a, c
            swap a
            and a, %00001111
            add a, VTI_TOWER_FONT
            ld [hl+], a
            ld [hl], 0
        :

        ;Draw lowest digit
        ld b, 4
        call sprite_get
        ld a, d
        ld [hl+], a
        ld a, e
        ld [hl+], a
        ld a, c
        and a, %00001111
        add a, VTI_TOWER_FONT
        ld [hl+], a
        ld [hl], 0

        ;Return
        ret
    ;
;



; Allocates a block of VRAM for some enemy tiles.  
; Lives in ROM0.
;
; Input:
; - `b`: Number of blocks needed (1-8).
;
; Returns:
; - `b`: Tile index
; - `de`: Tile address
tower_sprite_alloc::
    
    ;Construct bitmask -> B
    xor a
    :   add a, a
        inc a
        dec b
        jr nz, :-
    ld b, a

    ;Find free space
    ld d, 8
    ld a, [w_tower_spriteslots]
    ld c, a
    .try
    and a, b
    jr z, .return

        ;Nope, shift a bit and try again
        rrc c
        dec d
        ld a, c
        jr nz, .try

        ;Uh oh
        ld hl, error_not_enogh_vram
        rst v_error
    ;

    .return
    ;Mark as occupied
    ld a, c
    or a, b
    ld b, a
    ld a, 8
    sub a, d
    ld c, a
    jr z, :++
    :   rlc b
        dec a
        jr nz, :-
    :
    ld a, b
    ld [w_tower_spriteslots], a

    ;Get tile slot -> B
    ld a, c
    swap a
    add a, VTI_TOWER_ENEMIES
    ld b, a

    ;Get tile address -> HL
    ld de, VT_TOWER_ENEMIES
    ld a, d
    add a, c
    ld d, a

    ;Return
    ret
;



; Frees an allocated sprite.  
; Lives in ROM0.
;
; Input:
; - `b`: Number of blocks (1-8)
; - `c`: Tile index
tower_sprite_free::
    
    ;Construct bitmask -> B
    xor a
    :   add a, a
        inc a
        dec b
        jr nz, :-
    cpl
    ld b, a

    ;Get block number
    ld a, c
    sub a, VTI_TOWER_ENEMIES
    swap a
    ld c, a

    ;Shift bitmask
    jr z, .save
    :   rlc b
        dec a
        jr nz, :-
    ;

    ;Save spriteslots
    .save
    ld a, [w_tower_spriteslots]
    and a, b
    ld [w_tower_spriteslots], a

    ;Return
    ret
;
