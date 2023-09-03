INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"

SECTION "ENTSYS FIND", ROM0

; Find an entity with the given flags.
; All flags must match for entity to be valid.
; Returns a pointer to the first entity found.  
; Lives in ROM0.
;
; Input:
; - `c`: Flags that must match
;
; Returns:
; - `fZ`: Found entity (z = no, nz = yes)
; - `hl`: Entity pointer (`$0000` when none found)
;
; Saves: `bc`, `de`
entsys_find::
    push bc
    ld hl, w_entsys

    .check
        ;Is this entity allocated?
        ld a, [hl+]
        or a, a
        ld a, [hl-]
        jr z, .next
        ld b, a

        ;Match all flags
        set 2, l
        ld a, [hl]
        res 2, l
        and a, c
        xor a, c
        ld a, b
        jr nz, .next

        ;Ok, we have outselves a match!
        pop bc
        or a, h ;reset Z flag
        ret
    ;

    ; Input:
    ; - `a`: Entity size
    ; - `hl`: Entity pointer (`ENTVAR_BANK`)
    .next
        add a, l
        ld l, a
        jr nc, .check
        inc h
        ld a, h
        cp a, high(w_entsys_end)
        jr c, .check

        ;Nope, we are done here
        pop bc
        xor a ;set Z flag
        ret
    ;
;



; Continue a previous search.
; Documentation from `entsys_find` applies.
; Input entity is not checked.  
; Lives in ROM0.
;
; Input:
; - `c`: Flags that must match
; - `hl`: Entity pointer (`ENTVAR_BANK`)
;
; Returns:
; - `hl`: Entity pointer (`$0000` when none found)
;
; Saves: `bc`, `de`
entsys_find_continue::
    push bc
    inc l
    ld a, [hl-]
    jp entsys_find.next
;



; Low-precision collision check.
; Only tests using high-bytes of positions.  
; Lives in ROM0.
;
; Input:
; - `c`: Flags to test for (`ENTSYS_FLAGF_*`)
; - `hl`: Source entity (`ENTVAR_XPOS+1`)
;
; Returns:
; - `fZ`: Found anything (z = no, nz = yes)
; - `hl`: Collided entity
;
; Saves: `c`  
; Destroys: `af`, `b`, `de`
entsys_find_collision::
    relpointer_init l, ENTVAR_XPOS+1
    ld d, [hl]
    relpointer_move ENTVAR_YPOS+1
    ld e, [hl]
    relpointer_move ENTVAR_HEIGHT
    ld a, [hl-]
    sub a, e
    ld b, a
    ld a, [hl+]
    sub a, d

    ;Write this data to collision buffer
    relpointer_destroy
    ld hl, w_buffer
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld [hl], e

    ;Find entity with these flags
    call entsys_find
    ret z

    ;Ok, grab rectangle params
    .collide
    push bc
    push hl
    relpointer_init l
    relpointer_move ENTVAR_XPOS+1
    ld d, [hl]
    relpointer_move ENTVAR_YPOS+1
    ld e, [hl]
    relpointer_move ENTVAR_WIDTH
    ld a, [hl-]
    sub a, d
    ld b, a
    ld a, [hl+]
    sub a, e
    relpointer_destroy

    ;Write to buffer
    ld hl, w_buffer+7
    ld [hl-], a
    ld a, b
    ld [hl-], a
    ld a, e
    ld [hl-], a
    ld [hl], d

    ;Perform collision call
    ld b, h
    ld c, l
    ld d, h
    ld e, low(w_buffer)
    call entsys_collision_rr8

    ;Did we find anything?
    pop hl
    pop bc
    ret nz

    ; Low-precision collision check.
    ; Only tests using high-bytes of positions.
    ; Check more entities of needed.  
    ; Assumes `w_buffer` is unchanged.  
    ; Lives in ROM0.
    ;
    ; Input:
    ; - `c`: Flags to test for (`ENTSYS_FLAGF_*`)
    ; - `hl`: Last found entity pointer (`ENTVAR_BANK`)
    ;
    ; Returns:
    ; - `fZ`: Found anything (z = no, nz = yes)
    ; - `hl`: Collided entity
    ;
    ; Saves: `c`  
    ; Destroys: `af`, `b`, `de`
    entsys_find_collision_continue::
    call entsys_find_continue
    jr nz, entsys_find_collision.collide
    ret
;
