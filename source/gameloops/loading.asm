INCLUDE "hardware.inc"

SECTION "GAMELOOP LOADING", ROM0

; This gameloop keeps the screen on, while doing vqueue transfers in V-blank.  
; Exits once the vqueue is empty.  
; Assumes LCD is turned on.  
; Disables interrupts.  
; Lives in ROM0.
gameloop_loading::
    di

    ;Enable only V-blank
    ld a, IEF_VBLANK
    ldh [rIE], a
    
    .loop
        xor a
        ldh [rIF], a
        halt

        ;Now in V-blank
        call vqueue_execute
        call vqueue_empty
        jr nz, .loop
    ;

    ;Return
    ret
;
