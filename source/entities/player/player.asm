INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/memcpy.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/player.inc"
INCLUDE "struct/vram/tower.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Create a new player entity.  
; Allocates new entity.
;
; Output:
; - `hl`: Player entity pointer
;
; Saves: none
entity_player_create::
    call entsys_new32
    ld h, b
    ld l, c

    ;Set bank
    ld a, bank(@)
    ld [hl+], a
    inc l

    ;Set step function
    ld a, low(entity_player)
    ld [hl+], a
    ld a, high(entity_player)
    ld [hl+], a

    ;Reset variables
    ld a, l
    and a, %11100000
    add a, ENTVAR_VAR
    ld l, a
    xor a
    REPT ENTVAR_PLAYER_COUNT
        ld [hl+], a
    ENDR

    ;Load sprites
    push bc
    memcpy_label entity_player_sprite_base, VT_TOWER_PLAYER

    ;Return
    pop bc
    ret
;



; Player entity step function.
;
; Input:
; - `de`: Entity pointer
entity_player::
    ld h, d
    ld l, e

    ;Process and draw
    call entity_player_update
    call entity_player_draw

    ;Return
    ret 
;



; Does player movement and logic.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
entity_player_update:
    push hl

    ;Handle invincibility
    player_relpointer_init ENTVAR_PLAYER_INVINCIBLE
    ld a, [hl]
    or a, a
    jr z, :+
        dec [hl]
        jr nz, :+
        relpointer_move ENTVAR_PLAYER_FLAGS
        res PLAYER_FLAGB_INVINCIBLE, [hl]
        relpointer_move ENTVAR_PLAYER_INVINCIBLE
    :

    ;Read state -> E
    relpointer_move ENTVAR_PLAYER_STATE
    ld a, [hl]

    ;State switch
    ld bc, .return
    push bc
    cp a, PLAYER_STATE_GROUNDED
    jp z, player_state_grounded
    cp a, PLAYER_STATE_AIRBORNE
    jp z, player_state_airborne

    ;Unknown state, oops
    ld hl, error_invplayerstate
    rst v_error

    ;Return
    .return
    relpointer_destroy
    pop hl
    ret
;



; Draw player entity.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
entity_player_draw:
    push hl

    ;Check invincibility
    player_relpointer_init ENTVAR_PLAYER_INVINCIBLE
    ld a, [hl]
    or a, a
    jr z, :+
        and a, %00000111
        cp a, 8
        jr c, :+

        ;Alrighty, ignore
        pop hl
        ret
    :

    ;Get X and Y position -> DE
    relpointer_move ENTVAR_PLAYER_XPOS+1
    ld a, [w_camera_xpos+1]
    cpl
    add a, [hl]
    add a, 9
    ld d, a
    relpointer_move ENTVAR_PLAYER_YPOS+1
    ld e, [hl]
    inc e

    ;Get flags -> C
    relpointer_move ENTVAR_PLAYER_FLAGS
    ld b, [hl]
    ld c, OAMF_PAL0
    bit PLAYER_FLAGB_FACING, b
    jr z, :+
        set OAMB_XFLIP, c

        ;Scooch X-position over
        ld a, d
        add a, 8
        ld d, a
    :

    ;Get sprite address -> HL
    ldh a, [h_oam_active]
    ld h, a
    ld b, 4*2
    call sprite_get

    ;Get tile ID -> B
    ld b, VTI_TOWER_PLAYER

    ;Write sprite 0
    ld [hl], e
    inc l
    ld [hl], d
    inc l
    ld [hl], b
    inc l
    ld [hl], c
    inc l

    ;Move to sprite 1
    inc b
    inc b
    ld a, d
    add a, 8
    bit OAMB_XFLIP, c
    jr z, :+
        sub a, 16
    :
    ld d, a

    ;Write sprite 1
    ld [hl], e
    inc l
    ld [hl], d
    inc l
    ld [hl], b
    inc l
    ld [hl], c

    ;Return
    relpointer_destroy
    pop hl
    ret
;



; Speed subroutine.
;
; Input:
; - `bc`: Current speed
; - `de`:  Change
;
; Returns:
; - `bc`: new speed
;
; Saves: `de`, `hl`
player_speed_add::
    bit 7, b
    jr nz, .valid
    
    ld a, b
    cp a, high(PLAYER_XSPEED_MAX)
    jr c, .valid
    ret nz

    ;Do more testing
    ld a, c
    cp a, low(PLAYER_XSPEED_MAX)
    ret nc

    ;Speed is below cap, Add onto it
    .valid
    ld a, c
    add a, e
    ld c, a
    ld a, b
    adc a, d
    ld b, a

    ;Check high bounds
    bit 7, b
    ret nz
    cp a, high(PLAYER_XSPEED_MAX)
    ret c
    jr nz, .adjust

    ;Check low bounds
    ld a, c
    cp a, low(PLAYER_XSPEED_MAX)
    ret c
    ret z

    ;Set bounds and return
    .adjust
    ld bc, PLAYER_XSPEED_MAX
    ret
;



; Speed subroutine.
;
; Input:
; - `bc`: Current speed
; - `de`: Change
;
; Returns:
; - `bc`: new speed
;
; Saves: `de`, `hl`
player_speed_sub::
    bit 7, b
    jr z, .valid
    
    ld a, b
    cp a, high(-PLAYER_XSPEED_MAX)
    jr nc, .valid
    ret nz

    ;Do more testing
    ld a, c
    cp a, low(-PLAYER_XSPEED_MAX)
    ret c

    ;Speed is below cap, Add onto it
    .valid
    ld a, c
    sub a, e
    ld c, a
    ld a, b
    sbc a, d
    ld b, a

    ;Check high bounds
    bit 7, b
    ret z
    cp a, high(-PLAYER_XSPEED_MAX)
    jr c, .adjust
    ret nz

    ;Check low bounds
    ld a, c
    cp a, low(-PLAYER_XSPEED_MAX)
    ret nc

    ;Set bounds and return
    .adjust
    ld bc, -PLAYER_XSPEED_MAX
    ret
;



; Speed subroutine.
; Moves speed towards 0.
; If 0 is passed, it is set to 0.
;
; Input:
; - `bc`: `ENTVAR_PLAYER_XSPEED` | `ENTVAR_PLAYER_YSPEED`
; - `de`: Change
;
; Returns:
; - `bc`: new speed
;
; Saves: `de`, `hl`
player_speed_slow::
    bit 7, b
    jr nz, .increase
        ;Decrease speed, lower byte
        ld a, c
        sub a, e
        ld c, a

        ;Higher byte
        ld a, b
        sbc a, d
        ld b, a
        ret nc

        ;Set to 0
        ld bc, $0000
        ret
    
    .increase
        ;Increase speed, lower byte
        ld a, c
        add a, e
        ld c, a

        ;Higher byte
        ld a, b
        adc a, d
        ld b, a
        ret nc

        ;Set to 0
        ld bc, $0000
        ret
    ;
;



; Makes sure the player stays within the screen bounds.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Returns:
; - `de`: New X-position
;
; Saves: `bc`, `hl`
player_boundscheck::
    push hl

    ;Get X-position -> DE
    player_relpointer_init ENTVAR_PLAYER_XPOS+1
    ld a, [hl-]
    ld d, a
    ld a, [hl+]
    ld e, a

    ;Get lowest possible screen position
    ld a, [w_camera_xpos+1]
    cp a, [hl]
    jr z, .above_min
    jr c, .above_min
        ld e, $00
        jr .bounds
    ;

    .above_min
    add a, SCRN_X - PLAYER_WIDTH
    cp a, [hl]
    jr nc, .return
        ld e, $FF

        ;Stay inside screen bounds
        .bounds
        ld [hl-], a
        ld d, a
        ld a, e
        ld [hl+], a
        relpointer_move ENTVAR_PLAYER_XSPEED
        xor a
        ld [hl+], a
        ld [hl-], a
    ;

    ;Return
    .return
    relpointer_destroy
    pop hl
    ret
;



; Respawns player at the start.
;
; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`  
; Destroys: `af`, `bc`, `de`
player_respawn::
    push hl

    ;Reset speeds
    player_relpointer_init ENTVAR_PLAYER_XSPEED
    xor a
    ld [hl+], a
    ld [hl-], a
    relpointer_move ENTVAR_PLAYER_YSPEED
    xor a
    ld [hl+], a
    ld [hl-], a

    ;Reset X-position
    relpointer_move ENTVAR_PLAYER_XPOS+1
    ld a, [w_platform_xpos+1]
    ld b, a
    res 0, b
    ld a, [w_camera_xpos+1]
    res 0, a
    add a, b
    adc a, 0
    rrca
    ld [hl], a

    ;Reset Y-position
    relpointer_move ENTVAR_PLAYER_YPOS+1
    ld a, [w_platform_ypos+1]
    sub a, $17
    ld [hl], a

    ;Reset state
    relpointer_move ENTVAR_PLAYER_STATE
    ld [hl], PLAYER_STATE_AIRBORNE ;TODO: respawn state

    ;Return
    relpointer_destroy
    pop hl
    ret
;



; Deal damage to player.
;
; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Destroys: `af`, `b`
player_hurt::
    ld b, l
    player_relpointer_init ENTVAR_PLAYER_FLAGS
    set PLAYER_FLAGB_INVINCIBLE, [hl]
    relpointer_move ENTVAR_PLAYER_INVINCIBLE
    ld [hl], PLAYER_INVINCIBLE_TIME
    
    ;TODO: health

    ;Return
    ld l, b
    ret
;
