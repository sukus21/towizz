INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"

SECTION "BACKGROUND TEST", ROMX

; Creates a new background test entity.
;
; Returns:
; - `hl`: Entity pointer
;
; Destroys: all
entity_background_test_create::
    push bc
    call entsys_new16
    ld h, b
    ld l, c
    relpointer_init l

    ;Set bank and execution pointer
    relpointer_move ENTVAR_BANK
    ld [hl], bank(@)
    relpointer_move ENTVAR_STEP
    ld a, low(entity_background_test)
    ld [hl+], a
    ld a, high(entity_background_test)
    ld [hl-], a

    ;Return
    pop hl
    ret
;



; Entity used exclusively for testing background behaviour.
;
; Input:
; - `de`: Entity pointer
;
; Destroys: all
entity_background_test:
    
    ;This awful thing (for testing)
    ldh a, [h_input]
    ld b, a
    ldh a, [h_input_pressed]
    bit PADB_SELECT, a
    ret z

    ld a, [w_background_section]
    bit PADB_A, b
    jr z, :+
        dec a
        cp a, 3
        jr nc, .shifting
        ld a, 15
        jr .shifting
    :
        inc a
        cp a, 16
        jr c, .shifting
        ld a, 3
    ;

    .shifting
    ld [w_background_section], a
    ld b, a
    jp tower_background_fullqueue
    ;I had to jump there, as the bank this code is in would be switched out.
;
