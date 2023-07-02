INCLUDE "hardware.inc"

SECTION "ENTRY POINT", ROM0[$0100]

; Entrypoint of the program.
; Do not call manually.
; Lives in ROM0.
entrypoint:
    ;Disable interupts and jump
    di
    jp setup

    ;Space reserved for the header
    ds $4C, $00
;



SECTION "VBLANK INTERRUPT", ROM0[$0040]

; Vblank interrupt vector.
; Does nothing, as this is not how I detect Vblank.
; Does NOT set IME when returning.
; Lives in ROM0.
v_vblank::
    ret
;


SECTION "MAIN", ROM0[$0150]

; Entrypoint of game code, jumped to after setup is complete.
; Lives in ROM0.
main::
    jp gameloop_test
;
