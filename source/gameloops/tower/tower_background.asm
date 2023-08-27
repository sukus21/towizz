INCLUDE "tower.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/tower.inc"

SECTION "TOWER BACKGROUND", ROM0

; Queues up a full section.  
; Switches banks.  
; Lives in ROM0.
;
; Input:
; - `b`: Section number
;
; Destroys: all
tower_background_fullqueue::
    ld a, bank(tower_background_tls)
    ld [rROMB0], a
    
    ;Cannot full-queue the lowest sections.
    ld a, b
    cp a, 3
    jr nc, :+
        ld b, 3
    :
    ld d, b

    ;Get pointer to tilemap data -> BC
    ld bc, tower_background_tlm
    ld a, TOWER_BACKGROUND_SECTIONCOUNT-1
    sub a, d
    add a, a
    add a, a
    swap a
    ld e, a
    and a, %00001111
    add a, b
    ld b, a
    ld a, e
    and a, %11110000
    add a, c
    ld c, a
    jr nc, :+
        inc b
    :

    ;Copy tilemap data
    call vqueue_get

    ;Write type and length
    ld a, VQUEUE_TYPE_HALFROW
    ld [hl+], a ;type
    ld a, 16
    ld [hl+], a ;length
    xor a
    ld [hl+], a ;progress

    ;Write destination
    ld a, low(VM_TOWER_BACKGROUND0)
    ld [hl+], a ;destination (low)
    ld a, high(VM_TOWER_BACKGROUND0)
    ld [hl+], a ;destination (high)
    
    ;Write source
    ld a, bank(tower_background_tlm)
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a

    ;Reset writeback
    xor a
    ld [hl+], a
    ld [hl+], a

    ;Figure out oldest tile to load -> C
    ld a, d
    add a, low(tower_background_oldtile)
    ld l, a
    ld h, high(tower_background_oldtile)
    jr nc, :+
        inc h
    :
    ld c, [hl]

    ;Find newest tile to load -> B
    ld hl, tower_background_newtiles
    ld e, d
    inc e
    xor a
    :   add a, [hl]
        inc hl
        dec e
        jr nz, :-
    ld b, a

    ;Pointer to oldest tile -> HL
    ld hl, tower_background_tls
    swap c
    ld a, c
    and a, %00001111
    add a, h
    ld h, a
    ld a, c
    and a, %11110000
    add a, l
    ld l, a
    jr nc, :+
        inc h
    :

    ;Get tile count -> B
    swap c
    ld a, b
    sub a, c
    ld b, a
    inc b
    inc b

    ;Get destination -> DE
    ld a, c
    ld e, $60
    :   sub a, e
        jr nc, :-
        add a, e
    ld de, VT_TOWER_BACKGROUND
    swap a
    ld c, a
    and a, %00001111
    add a, d
    ld d, a
    ld a, c
    and a, %11110000
    add a, e
    ld e, a
    jr nc, :+
        inc d
    :

    ;A bit of register shuffling to free HL
    ld a, b
    push af
    ld b, h
    ld c, l

    ;Start transferin'
    call vqueue_get
    ld [hl], VQUEUE_TYPE_DIRECT ;transfer type
    inc hl
    pop af
    ld [hl+], a ;transfer length
    xor a
    ld [hl+], a ;progress

    ;Transfer destination
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a

    ;Transfer source
    ld a, bank(tower_background_tls)
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a

    ;Reset writeback
    xor a
    ld [hl+], a
    ld [hl+], a

    ;Return
    ret
;
