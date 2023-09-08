INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/color.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/player.inc"
INCLUDE "struct/entity/shopdoor.inc"

SECTION "ENTITY SHOPDOOR", ROMX

; Loads the assets required for the shopdoor entity.  
; Enqueues VQUEUE transfer.
;
; Input:
; - `de`: Transfer destination (address/label)
;
; Destroys: all
entity_shopdoor_load::
    vqueue_add_copy VQUEUE_TYPE_DIRECT, de, shopdoor_tiles
    ret
;



; Creates a new shopdoor entity.
;
; Input:
; - `b`: Tile index
;
; Returns:
; - `hl`: Entity pointer
;
; Destroys: all
entity_shopdoor_create::
    push bc
    call entsys_new16
    ld h, b
    ld l, c
    ld d, c
    relpointer_init l

    ;Set bank and execution pointer
    relpointer_move ENTVAR_BANK
    ld [hl], bank(@)
    relpointer_move ENTVAR_STEP
    ld a, low(entity_shopdoor)
    ld [hl+], a
    ld a, high(entity_shopdoor)
    ld [hl-], a

    ;Clear variables
    relpointer_move ENTVAR_SHOPDOOR_VAR
    ld e, l
    ld bc, ENTVAR_SHOPDOOR_COUNT
    call memset_short
    ld l, e

    ;Set sprite tile
    relpointer_move ENTVAR_SHOPDOOR_TILE
    pop af
    ld [hl], a

    ;Yup, that's all
    relpointer_destroy
    ld l, d
    ret
;



; Step function for shopdoor entity.
;
; Input:
; - `de`: Entity pointer
;
; 
entity_shopdoor:

    ;Check state
    relpointer_init e
    relpointer_move ENTVAR_SHOPDOOR_ENTERED
    ld a, [de]
    cp a, 0
    jr nz, shopdoor_wait
    
    ;Get my own X-position -> C
    relpointer_move ENTVAR_SHOPDOOR_XPOS
    ld a, [de]
    ld c, a
    push bc
    relpointer_destroy

    ;Get player entity -> HL
    ld c, ENTSYS_FLAGF_PLAYER
    call entsys_find_all
    pop bc
    ret z
    relpointer_init l

    ;Check player Y-position.
    ;player must be standing on platform to enter door.
    relpointer_move ENTVAR_YPOS+1
    ld a, [w_platform_ypos+1]
    dec a
    cp a, [hl]
    ret nz

    ;Get player X-position -> B
    relpointer_move ENTVAR_XPOS+1
    ld a, [hl]
    add a, PLAYER_WIDTH / 2
    ld b, a

    ;Check positioning
    cp a, c
    ret c
    ld a, c
    add a, 16
    cp a, b
    ret c

    ;Yes, we should display a thing!
    relpointer_destroy
    relpointer_init e, ENTVAR_SHOPDOOR_XPOS

    ;Get sprites
    ldh a, [h_oam_active]
    ld h, a
    ld b, 8
    call sprite_get

    ;Get Y-position -> B
    relpointer_move ENTVAR_SHOPDOOR_YPOS
    ld a, [de]
    ld b, a

    ;Update X-position -> C
    ld a, c
    add a, 8
    ld c, a

    ;Get sprite tile -> DE
    relpointer_push ENTVAR_SHOPDOOR_TILE
    ld a, [de]
    ld h, a
    relpointer_move ENTVAR_SHOPDOOR_TIMER
    ld a, [de]
    inc a
    ld [de], a
    swap a
    and a, 1
    add a, a
    ld e, h
    add a, h
    ld d, a
    ldh a, [h_oam_active]
    ld h, a

    ;Write sprite data
    ld [hl], b
    inc l
    ld [hl], c
    inc l
    ld [hl], e
    inc l
    xor a
    ld [hl+], a
    ld [hl], b
    inc l
    ld a, c
    add a, 8
    ld [hl+], a
    ld [hl], d
    inc l
    ld [hl], 0

    ;Check for input
    relpointer_pop
    ldh a, [h_input_pressed]
    bit PADB_START, a
    ret z

    ;Ok, we are clear to move
    relpointer_move ENTVAR_SHOPDOOR_ENTERED
    ld a, 1
    ld [de], a
    ld a, COLOR_FADESTATE_OUT
    call transition_fade_init

    ;Return
    relpointer_destroy
    ret
;



; Wait for transition to complete.
; Then, call the desired function.  
; Does not return.
;
; Input:
; - `de`: Shopdoor entity pointer (`ENTVAR_SHOPDOOR_ENTERED`)
shopdoor_wait:
    relpointer_init e, ENTVAR_SHOPDOOR_ENTERED
    
    ;Get transition state
    ld a, [w_fade_state]
    and a, COLOR_FADEM_STATE
    cp a, COLOR_FADESTATE_DONE
    ret nz

    ;Here we go
    relpointer_move ENTVAR_SHOPDOOR_ADDR
    relpointer_destroy
    ld h, d
    ld l, e
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp hl
;



; Graphics tiles used for the shopdoor.
shopdoor_tiles: INCBIN "graphics/shop/shopdoor.tls"
.end
