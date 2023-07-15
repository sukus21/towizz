INCLUDE "hardware.inc"
INCLUDE "struct/vqueue.inc"

SECTION "VRAM QUEUE", ROM0

; Get a vqueue slot pointer.
; When adding multiple transfers, completion order is not guaranteed.  
; \- Lives in ROM0.
;
; Returns:
; - `hl`: `VQUEUE` pointer
;
; Saves: `bc`, `de`
vqueue_get::
    ld hl, w_vqueue_first
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push de
    push hl

    ;Increment this pointer a wee bit
    ld a, l
    add a, VQUEUE
    ld e, a
    ld a, h
    adc a, 0
    ld d, a

    ;Out of bounds check
    cp a, high(w_vqueue.end)
    jr nz, :+
        ld a, e
        cp a, low(w_vqueue.end)
        jr nz, :+

        ;Uh oh, overflow alert
        ld hl, error_vqueueoverflow
        rst v_error
    :

    ;Store this back as the new first slot
    ld hl, w_vqueue_first
    ld a, e
    ld [hl+], a
    ld [hl], d

    ;Yes, good, return
    pop hl
    pop de
    ret
;



; Execute transfers from the VRAM queue.  
; \- Assumes VRAM access.  
; \- Switches banks.  
; \- Lives in ROM0.  
;
; Destroys: all
vqueue_execute::
    ;Get type of transfer
    ld hl, w_vqueue
    ld a, [hl+]
    cp a, VQUEUE_TYPE_NONE
    ret z

    cp a, VQUEUE_TYPE_BULK
    jr nz, :+
        call vqueue_execute_bulk
        ret z
        jr .finish
    :

    ;Finish a transfer
    .finish
        ;Set type to none
        ld hl, w_vqueue + VQUEUE_TYPE
        ld [hl], VQUEUE_TYPE_NONE

        ;Perform writeback
        ld l, low(w_vqueue) + VQUEUE_WRITEBACK
        ld a, [hl+]
        ld h, [hl]
        ld l, a
        inc [hl]

        ;Move to last queued transfer
        ld hl, w_vqueue_first
        ld a, [hl+]
        sub a, VQUEUE
        jr nc, :+
            dec [hl]
        :
        ld c, a
        ld a, [hl-]
        ld [hl], c
        ld h, a
        ld l, c

        ;Transfer exists?
        ld a, [hl]
        cp a, VQUEUE_TYPE_NONE
        ret z

        ;Copy transfer to first slot
        ld bc, w_vqueue
        ld [bc], a
        inc bc
        ld a, VQUEUE_TYPE_NONE
        ld [hl+], a
        REPT VQUEUE-1
            ld a, [hl+]
            ld [bc], a
            inc bc
        ENDR

        ;Do we have time to start this transfer?
        ldh a, [rLY]
        cp a, $97
        jr nc, vqueue_execute
    ;

    ;Return
    ret 
;



; Subroutine for `vqueue_execute`.  
; \- Same notes as `vqueue_execute`.
;
; Input:
; - `hl`: `VQUEUE` pointer, at `VQUEUE_LENGTH`
;
; Returns:
; - `fZ`: Transfer ended early
vqueue_execute_bulk:
    ;Get length remaining
    ld a, [hl+]
    ld d, a ;length total -> D
    ld a, [hl+]
    ld e, a ;progress -> E

    ;Get destination -> BC
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a

    ;Get source -> HL
    ld a, [hl+]
    ld [rROMB0], a
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    .loop
        ;Do the copying
        REPT 16
            ld a, [hl+]
            ld [bc], a
            inc bc
        ENDR

        ;Is it over?
        inc e
        ld a, e
        sub a, d
        jr nz, :+
            inc a ;reset Z-flag
            ret
        :

        ;Time for another iteration?
        ldh a, [rLY]
        cp a, $98
        jr c, .loop
    ;

    ;Time is up
    ;Save transfer completion count
    ld a, e
    ld d, h
    ld e, l
    ld hl, w_vqueue + VQUEUE_PROGRESS
    ld [hl+], a

    ;Save destination
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl+], a

    ;Save source
    inc hl
    ld a, e
    ld [hl+], a
    ld [hl], d

    ;Return
    xor a ;sets Z-flag
    ret
;
