

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
; - `hl`: Entity pointer (`$0000` when none found)
;
; Saves: `bc`, `de`
entsys_find::
    ld hl, w_entsys

    .check
        ;Is this entity allocated?
        ld a, [hl+]
        or a, a
        ld a, [hl-]
        jr z, .next

        ;Match all flags
        set 2, l
        ld a, [hl]
        res 2, l
        and a, c
        xor a, c
        jr nz, .next

        ;Ok, we have outselves a match!
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
        ld hl, $0000
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
    inc l
    ld a, [hl-]
    jp entsys_find.next
;
