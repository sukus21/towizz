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
