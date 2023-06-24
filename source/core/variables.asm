INCLUDE "hardware.inc"
INCLUDE "entsys.inc"

;Allocate 256 bytes for the stack, just to be safe
stack_size equ $100
SECTION "STACK", WRAM0[$D000 - stack_size]
    ; Top of stack.
    w_stack_begin:: ds stack_size

    ; Base of stack.
    w_stack:: ds $00

    ;Make sure things work out
    ASSERT w_stack_begin + stack_size == $D000
;



SECTION "VARIABLE INITIALIZATION", ROMX

; Initializes ALL variables.
variables_init::

    ;Copy WRAM0 variables
    ld hl, w_variables ;Start of variable space
    ld bc, var_w0 ;Initial variable data
    ld de, var_w0_end - var_w0 ;Data length
    call memcpy

    ;Copy WRAMX variables
    ld hl, w_entsys ;Start of variable space
    ld bc, var_wx ;Initial variable data
    ld de, var_wx_end - var_wx ;Data length
    call memcpy

    ;Copy HRAM variables
    .dma_hram::
    ld hl, h_variables ;Start of variable space
    ld bc, var_h ;Initial variable data
    ld d, var_h_end - var_h ;Data length
    call memcpy_short

    ;Return
    ret
;



; Contains the initial values of all variables in WRAM0.
var_w0:
    LOAD "WRAM0 VARIABLES", WRAM0, ALIGN[8]
        w_variables:

        ; 256 bytes of memory that can be used for anything.
        w_buffer:: ds 256

        ; OAM mirror, used for the DMA.
        w_oam_mirror:: ds $A4, $00
        ASSERT low(w_oam_mirror) == 0

        ; Intro state.
        ; Only used in `source/intro.asm`.
        w_intro_state:: db $00

        ; Intro timer.
        ; Only used in `source/intro.asm`.
        w_intro_timer:: db $00

        ; First known 1-chunk entity slot.
        w_entsys_first16:: dw $0000

        ; First known 2-chunk entity slot.
        w_entsys_first32:: dw $0000

        ; First known 4-chunk entity slot.
        w_entsys_first64:: dw w_entsys
    ENDL
    var_w0_end:
;

; Contains the initial values of all variables in WRAMX.
var_wx:
    LOAD "WRAMX VARIABLES", WRAMX, ALIGN[8]
        ; Enitity system.\
        ; Check out `source/entitysystem/entsys.md` for documentation.
        w_entsys::
            REPT entsys_entity_count
                w_entsys_bank_\@: db $00
                w_entsys_next_\@: db $40
                w_entsys_step_\@: dw $0000
                ds 12
            ENDR
            w_entsys_end::
        ;
    ENDL
    var_wx_end:
;

; Contains the initial values for all HRAM variables.
var_h:
    LOAD "HRAM VARIABLES", HRAM
        h_variables::

        ; OAM DMA routine in HRAM.\
        ; Interrupts should be disabled while this runs.\
        ; Assumes OAM access.
        ;
        ; Destroys: `af`
        h_dma_routine::

            ;Initialize OAM DMA
            ld a, HIGH(w_oam_mirror)

            ; Run OAM DMA with a pre-specified input.\
            ; Interrupts should be disabled while this runs.\
            ; Assumes OAM access.
            ;
            ; Input:
            ; - `a`: High byte of OAM table
            ;
            ; Destroys: `af`
            h_dma_sourced::
            ldh [rDMA], a

            ;Wait until transfer is complete
            ld a, 40
            .wait
            dec a
            jr nz, .wait

            ;Return
            ret
        ;

        ; LYC interrupt jump-to routine.
        ; Contains a single `jp n16` instruction.
        ; The pointer can be overwritten to whatever you want to jump to.
        h_LYC::
            jp v_error
        ;


        ; Bitfield of buttons held.
        ; Use with `PADB_*` or `PADF_*` from `hardware.inc`.
        h_input:: db $FF

        ; Bitfield of buttons held.
        ; Use with `PADB_*` or `PADF_*` from `hardware.inc`.
        h_input_pressed:: db $00

        ; Is set to non-zero when setup is complete.
        h_setup:: db $FF

        ; Non-zero if CGB-mode is enabled.
        h_is_color:: db $FF

        ; Which ROM-bank is currently switched in.
        h_bank_number:: db $01

        ; Low-byte of pointer to first empty OAM slot.
        h_sprite_slot:: db $00

        ; RNG variables.
        h_rng::

        ; Seed for the next RNG value.
        h_rng_seed:: db $7E, $B2

        ; Last RNG output.
        h_rng_out:: db $00, $00
    ENDL
    var_h_end:
;
