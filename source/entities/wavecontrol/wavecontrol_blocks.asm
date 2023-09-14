INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/wavecontrol.inc"

SECTION FRAGMENT "WAVECONTROL", ROMX

; Sets wavecontrol checkpoint.
;
; Destroys: `af`, `bc`, `de`
wavecontrol_block_checkpoint::
    pop bc
    push bc
    jp wavecontrol_block_save
;



; Input:
; - `hl`: Entity pointer (anywhere)
; - `bc`: Address to save
;
; Destroys: `af`, `de`
wavecontrol_block_save::
    push hl
    ld d, h
    ld e, l

    ;Save program counter
    wavecontrol_relpointer_init ENTVAR_WAVECONTROL_PC
    ld a, c
    ld [hl+], a
    ld a, b
    ld [hl-], a

    ;Save entity pointer
    relpointer_move ENTVAR_WAVECONTROL_HL
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl-], a

    ;Return
    relpointer_destroy
    pop hl
    ret
;



; A condition failed.
; Return to before wave execution.  
; Smashes stack pointer, does not return.
;
; Input:
; - `hl`: Entity pointer (anywhere)
wavecontrol_block_return::
    
    ;Read old stack pointer -> SP
    wavecontrol_relpointer_init ENTVAR_WAVECONTROL_SP
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld sp, hl

    ;"Return"
    relpointer_destroy
    ret
;



; Wait for VQUEUE writebacks.  
; Exits if transfers are not met.
; Sets writeback to 0 when condition is met.
;
; Input:
; - `hl`: Entity pointer (anywhere)
; - `b`: Expected writeback value
;
; Destroys: `af`
wavecontrol_block_vqueue::
    push hl

    ;Check transfer status
    wavecontrol_relpointer_init ENTVAR_WAVECONTROL_WRITEBACK
    ld a, [hl]
    cp a, b
    jp c, wavecontrol_block_return

    ;Oh hey, we are done
    ld [hl], 0
    relpointer_destroy
    pop hl
    ret
;



; Ignores writeback values, just waits for VQUEUE to be empty.
; Try not to use if possible.
; Exits if VQUEUE is not empty.
;
; Destroys: `af`
wavecontrol_block_vqueue_empty::
    call vqueue_empty
    jp nz, wavecontrol_block_return
    ret
;



; Wait for wave to begin.  
; Exits if wave has not begun.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Destroys: `af`
wavecontrol_block_begun::
    push hl
    wavecontrol_relpointer_init ENTVAR_WAVECONTROL_BEGUN
    ld a, [hl]
    or a, a
    jp z, wavecontrol_block_return

    ;Return
    relpointer_destroy
    pop hl
    ret
;



; Increases tower speed until a certain speed is reached.
;
; Input:
; - `bc`: Target speed
; - `de`: Change
;
; Saves: `hl`
wavecontrol_block_vspeed_add::
    push hl
    ld hl, w_tower_yspeed
    ld a, [hl]
    add a, e
    ld [hl+], a
    ld a, [hl]
    adc a, d
    ld [hl+], a

    ;Also do background speed
    ld hl, w_background_yspeed
    sra d
    rr e
    sra d
    rr e
    sra d
    rr e
    ld a, [hl]
    add a, e
    ld [hl+], a
    ld a, [hl]
    adc a, d
    ld [hl+], a

    ;Did we go over the Speed Limit?
    ld hl, w_tower_yspeed+1
    ld a, [hl-]
    cp a, b
    jr c, .exit
    ld a, [hl]
    cp a, c
    jr c, .exit

        ;Yes we did, limit speeds
        ld a, c
        ld [hl+], a
        ld [hl], b
        ld hl, w_background_yspeed
        sra b
        rr c
        sra b
        rr c
        sra b
        rr c
        ld a, c
        ld [hl+], a
        ld [hl], b
    ;

    ;Return
    pop hl
    ret

    .exit
        pop hl
        jp wavecontrol_block_return
    ;
;



; Decreases tower speed until a certain speed is reached.
;
; Input:
; - `bc`: Target speed
; - `de`: Change
;
; Saves: `hl`
wavecontrol_block_vspeed_sub::
    push hl
    ld hl, w_tower_yspeed
    ld a, [hl]
    sub a, e
    ld [hl+], a
    ld a, [hl]
    sbc a, d
    jr c, .limit
    ld [hl+], a

    ;Also do background speed
    ld hl, w_background_yspeed
    sra d
    rr e
    sra d
    rr e
    sra d
    rr e
    ld a, [hl]
    sub a, e
    ld [hl+], a
    ld a, [hl]
    sbc a, d
    ld [hl+], a

    ;Did we go over the Speed Limit?
    ld hl, w_tower_yspeed+1
    ld a, [hl-]
    cp a, b
    jr z, :+
    jr nc, .exit
    :
    ld a, [hl]
    cp a, c
    jr z, .limit
    jr nc, .exit

        ;Yes we did, limit speeds
        .limit
        ld a, c
        ld [hl+], a
        ld [hl], b
        ld hl, w_background_yspeed
        sra b
        rr c
        sra b
        rr c
        sra b
        rr c
        ld a, c
        ld [hl+], a
        ld [hl], b
    ;

    ;Return
    pop hl
    ret

    .exit
        pop hl
        jp wavecontrol_block_return
    ;
;
