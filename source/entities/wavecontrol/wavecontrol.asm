INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/wavecontrol.inc"

SECTION FRAGMENT "WAVECONTROL", ROMX

entity_wavecontrol_create::
    entsys_new 64, wavecontrol_step, WAVECONTROL_FLAGS

    ;Reset begun flag
    relpointer_move ENTVAR_WAVECONTROL_BEGUN
    ld [hl], 0

    ;Store current entity pointer (yes, really)
    relpointer_move ENTVAR_WAVECONTROL_HL
    ;Here we are witnessing the first ever recorded usage of `ld [hl], h` and `ld [hl], l`
    ld [hl], l
    inc l
    ld [hl], h
    dec l

    ;Get routine pointer -> BC
    ld a, [w_waves_passed]
    add a, a
    add a, low(wavecontrol_routinetable)
    ld c, a
    ld a, high(wavecontrol_routinetable)
    adc a, 0
    ld b, a
    ld a, [bc]
    inc bc
    ld e, a
    ld a, [bc]
    ld b, a
    ld c, e

    ;Save routine pointer
    relpointer_move ENTVAR_WAVECONTROL_PC
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl-], a

    ;Reset writeback
    relpointer_move ENTVAR_WAVECONTROL_WRITEBACK
    ld [hl], 0

    ;Reset dragdown pointers
    relpointer_move ENTVAR_WAVECONTROL_DRAGDOWN
    ld e, l
    xor a
    REPT 8
        ld [hl+], a
    ENDR
    ld l, e

    ;Return
    relpointer_destroy
    ret
;



; Wave routine table.
wavecontrol_routinetable:
    dw wavecontrol_wave1
;



wavecontrol_step:
    call wavecontrol_update
    ret
;



; Input:
; - `de`: Entity pointer (anywhere)
;
; Saves: all
wavecontrol_update::
    push af
    push bc
    push de
    push hl
    push de

    ;Push early return pointer to stack
    ld bc, .return_forced
    push bc

    ;Save early return pointer
    ld hl, sp+0
    ld b, h
    ld c, l
    ld h, d
    ld l, e
    wavecontrol_relpointer_init ENTVAR_WAVECONTROL_SP
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl-], a
    
    ;Read program counter -> BC
    relpointer_move ENTVAR_WAVECONTROL_PC
    ld a, [hl+]
    ld c, a
    ld a, [hl-]
    ld b, a

    ;Read entity pointer -> HL
    relpointer_move ENTVAR_WAVECONTROL_HL
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    relpointer_destroy

    ;Call wave routine
    call _bc_

    ;Here we are
    pop bc
    .return_forced

    pop hl
    call wavecontrol_dragdown

    ;Return
    pop hl
    pop de
    pop bc
    pop af
    ret
;



; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
wavecontrol_dragdown:
    push hl
    wavecontrol_relpointer_init ENTVAR_WAVECONTROL_DRAGDOWN
    relpointer_destroy

    ;Loopies
    ld d, 4
    .loop

        ;Get entity pointer -> HL
        ld a, [hl+]
        ld c, a
        ld a, [hl+]
        push hl
        ld h, a
        ld l, c
        or a, l
        jr z, .iterate
        relpointer_init l

        ;Drag this thing down
        relpointer_move ENTVAR_YPOS
        ld a, [w_tower_yspeed]
        add a, [hl]
        ld [hl+], a
        ld a, [w_tower_yspeed+1]
        adc a, [hl]
        ld [hl-], a

        ;Loop count
        .iterate
        relpointer_destroy
        pop hl
        dec d
        jr nz, .loop
    ;
    
    pop hl
    ret
;



; Release all dragdown entities.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`
wavecontrol_dragdown_release::
    push hl
    wavecontrol_relpointer_init ENTVAR_WAVECONTROL_DRAGDOWN
    relpointer_destroy
    ld d, 4
    .loop

        ;Get and clear entity pointer
        xor a
        ld c, [hl]
        ld [hl+], a
        ld b, [hl]
        ld [hl+], a
        ld a, c
        ld e, c
        add a, ENTVAR_FLAGS
        ld c, a

        ;Check flags
        ld a, [bc]
        and a, ENTSYS_FLAGF_DMGCALL
        ld a, ENTVAR_COL_VAR
        jr z, .foundvar
        ld a, ENTVAR_DMGCALL_VAR

        ;Increment state
        .foundvar
        add a, e
        ld c, a
        ld a, [bc]
        inc a
        ld [bc], a

        ;Loop count
        dec d
        jr nz, .loop
    ;

    ;Return
    pop hl
    ret
;
