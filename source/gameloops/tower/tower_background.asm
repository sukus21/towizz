INCLUDE "hardware.inc"
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
    ld hl, w_tower_flags
    res TOWERMODEB_WINDOW_TILEMAP, [hl]
    
    ;Cannot full-queue the lowest sections.
    ld a, b
    cp a, 3
    jr nc, :+
        ld b, 3
    :
    ld d, b

    ;Load tilemap
    push de
    ld e, high(VM_TOWER_BACKGROUND0)
    call tower_background_mapqueue
    pop de
    ld e, high(VM_TOWER_BACKGROUND1)
    call tower_background_mapqueue

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

    ;Transfer tiles needed
    call tower_background_tilequeue

    ;Return
    ret
;



; Queue up background tiles for transfer.  
; Assumes the correct bank is switched in.  
; Lives in ROM0.
;
; Input:
; - `b`: Highest tile ID
; - `c`: Lowest tile ID
tower_background_tilequeue:
    
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
    push af
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

    ;Should transfer be split in 2?
    pop af
    ld c, a
    add a, b
    sub a, $60
    jr nc, .split

    ;Start tha transfer!
    ld a, b
    ld b, h
    ld c, l
    call background_transfer_add

    ;Return
    ret

    ; Split transfer.
    ;
    ; Input:
    ; - `a`: Overshoot amount
    ; - `de`: Destination
    ; - `hl`: Source
    ; - `b`: Unmodified operation count
    .split
        push af
        ld c, a
        ld a, b
        sub a, c
        push af

        ;Do intended transfer, but truncated
        ld b, h
        ld c, l
        call background_transfer_add

        ;Do the trail end of truncated transfer
        ld de, VT_TOWER_BACKGROUND
        pop af
        swap a
        ld h, a
        and a, %00001111
        add a, b
        ld b, a
        ld a, h
        and a, %11110000
        add a, c
        ld c, a
        jr nc, :+
            inc b
        :
        pop af
        call background_transfer_add

        ;Return
        ret
    ;
;



; Creates a vqueue transfer that loads the specified background tiles.  
; Assumes the correct bank is switched in.  
; Lives in ROM0.
;
; Input:
; - `d`: Section number
; - `e`: Target tilemap (high)
tower_background_mapqueue::

    ;Get pointer to tilemap data -> BC
    ld bc, tower_background_tlm
    ld a, TOWER_BACKGROUND_SECTIONCOUNT-1
    sub a, d
    add a, a
    add a, a
    swap a
    ld l, a
    and a, %00001111
    add a, b
    ld b, a
    ld a, l
    and a, %11110000
    add a, c
    ld c, a
    jr nc, :+
        inc b
    :

    ;Modify tilemap pointer a bit
    ld a, e
    cp a, high(VM_TOWER_BACKGROUND0)
    jr nz, :+
        ld a, c
        sub a, $20
        ld c, a
        jr nc, :+
        dec b
    :

    ;Copy tilemap data
    call vqueue_get

    ;Write type and length
    ld a, VQUEUE_TYPE_HALFROW
    ld [hl+], a ;type
    ld a, 18
    ld [hl+], a ;length
    xor a
    ld [hl+], a ;progress

    ;Write destination
    ld [hl+], a ;destination (low)
    ld a, e
    ld [hl+], a ;destination (high)
    
    ;Write source
    ld a, bank(tower_background_tlm)
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a

    ;Set writeback pointer
    ld a, low(w_background_writeback)
    ld [hl+], a
    ld a, high(w_background_writeback)
    ld [hl+], a

    ;Increment writeback target
    ld hl, w_background_writeback_target
    inc [hl]

    ;Return
    ret
;



; Adds a background transfer to the vqueue.  
; Lives in ROM0.
;
; Input:
; - `a`: Operation count
; - `de`: Destination
; - `bc`: Source
;
; Saves: `bc`, `de`  
; Destroys: `af`, `hl`
background_transfer_add:
    
    ;Start transferin'
    push af
    call vqueue_get
    ld a, VQUEUE_TYPE_DIRECT
    ld [hl+], a ;transfer type
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

    ;Set writeback pointer
    ld a, low(w_background_writeback)
    ld [hl+], a
    ld a, high(w_background_writeback)
    ld [hl+], a

    ;Increment writeback target
    ld hl, w_background_writeback_target
    inc [hl]

    ;Return
    ret
;



; 
; Switches banks.  
; Lives in ROM0.
;
; Input:
; - `b`: Section number
tower_background_nextqueue::
    ld a, bank(tower_background_newtiles)
    ld [rROMB0], a
    push bc
    inc b
    xor a
    ld hl, tower_background_newtiles-1
    :   inc hl
        add a, [hl]
        dec b
        jr nz, :-
    ;

    ;Load the funny tiles
    ld b, a
    sub a, [hl]
    ld c, a
    call tower_background_tilequeue

    ;Load the funny map
    pop de
    ld e, high(VM_TOWER_BACKGROUND1)
    call tower_background_mapqueue

    ;Return
    ret
;



; Moves the platform animation along.  
; Switches banks.  
; Lives in ROM0.
tower_background_step::
    xor a
    ld [w_background_writeback], a
    ld a, [w_tower_flags]
    bit TOWERMODEB_WINDOW_TILEMAP, a
    ld hl, w_background_section
    ld a, [hl]
    jr z, .small
    
        ;Reset entirely?
        cp a, 15
        jr nz, :+
            ld a, 3
            ld [hl], a
            ld b, a
            jp tower_background_fullqueue
        :

        ;Just go to next section
        inc a
        ld [hl], a
        ld b, a
        jp tower_background_nextqueue
    ;

    ;Copy tilemap to background 1
    .small
    ld a, bank(tower_background_newtiles)
    ld [rROMB0], a
    ld d, [hl]
    ld e, high(VM_TOWER_BACKGROUND0)
    jp tower_background_mapqueue
;



; Listens.
tower_background_handler::
    ld hl, w_background_writeback_target
    ld a, [hl-]
    or a, a ;xp a, 0
    ret z

    ;Compare to current writeback status
    cp a, [hl]
    ret c

    ;Alright, loading is done, toggle window
    ld bc, w_tower_flags
    ld a, [bc]
    xor a, TOWERMODEF_WINDOW_TILEMAP
    ld [bc], a

    ;Reset writeback registers as well
    xor a
    ld [hl+], a
    ld [hl], a

    ;That's it I think
    ret
;
