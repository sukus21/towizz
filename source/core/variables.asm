INCLUDE "hardware.inc"
INCLUDE "entsys.inc"

;Allocate 256 bytes for the stack, just to be safe
DEF STACK_SIZE EQU $100
SECTION "STACK", WRAM0[$D000 - STACK_SIZE]
    ; Top of stack.
    w_stack_begin:: ds STACK_SIZE

    ; Base of stack.
    w_stack:: ds $00

    ;Make sure things work out
    ASSERT w_stack_begin + STACK_SIZE == $D000
;



SECTION "VARIABLE INITIALIZATION", ROMX

; Initializes ALL variables.
variables_init::

    ;Copy WRAM0 variables
    ld hl, w_variables ;Start of variable space
    ld bc, var_w0 ;Initial variable data
    ld de, var_w0_end - var_w0 ;Data length
    call memcpy

    ;Initialize entity system
    ld hl, w_entsys
    xor a
    ld b, ENTSYS_CHUNK_COUNT
    .entsys_loop
        ld [hl+], a ;entity bank
        ld [hl], $40 ;slot size
        ld [hl+], a
        ld [hl+], a ;step function pointer
        REPT 12
            ld [hl+], a ;unassigned data
        ENDR
        dec b
        jr nz, .entsys_loop
    ;

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

        w_tower_xpos:: db $00
        w_tower_ypos:: db $00
        w_tower_height:: db $10
        w_tower_lyc:: db $00
    
        w_platform_width:: db $68
        w_platform_height:: db $10
        w_platform_xpos:: db $48
        w_platform_ypos:: db $50

        w_background_xpos:: db $48
        w_background_ypos:: db $00
    ENDL
    var_w0_end:
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
        
        h_tower_xpos:: db $00
        h_tower_ypos:: db $00
        h_tower_height:: db $10
        h_tower_lyc:: db $00
    
        h_platform_width:: db $68
        h_platform_height:: db $18
        h_platform_xpos:: db $00
        h_platform_ypos:: db $50

        h_background_xpos:: db $4F
        h_background_ypos:: db $14

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

        ; How many sprites were allocated last frame.
        h_sprites_previous:: db $A0

        ; RNG variables.
        h_rng::

        ; Seed for the next RNG value.
        h_rng_seed:: db $7E, $B2

        ; Last RNG output.
        h_rng_out:: db $00, $00
    ENDL
    var_h_end:
;



SECTION "ENTITY STORAGE", WRAMX, ALIGN[8]

; Enitity system.  
; Check out `source/entitysystem/entsys.md` for documentation.
w_entsys::
    REPT ENTSYS_CHUNK_COUNT
        w_entsys_bank_\@: ds 1
        w_entsys_next_\@: ds 1
        w_entsys_step_\@: ds 2
        w_entsys_vars_\@: ds 12
    ENDR
    w_entsys_end::
;
