INCLUDE "hardware.inc"
INCLUDE "entsys.inc"
INCLUDE "macros/color.inc"
INCLUDE "struct/item.inc"
INCLUDE "struct/oam_mirror.inc"
INCLUDE "struct/tower_buffer.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/player.inc"

SECTION "DMA INIT", ROM0

; Initializes DMA routine only.
; Lives in ROM0.
;
; Saves: none
dma_init::
    ld hl, h_dma
    ld bc, var_h + (h_dma - h_variables)
    ld d, h_dma.end - h_dma

    ;Return directly after copying
    jp memcpy_short
;



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
    call entsys_clear

    ;Initialize OAM mirrors
    ld hl, w_oam1
    ld bc, $00_00
    call memset_short
    ld hl, w_oam2
    call memset_short
    ld hl, w_oam_hud
    call memset_short

    ;Copy HRAM variables
    ld hl, h_variables ;Start of variable space
    ld bc, var_h ;Initial variable data
    ld d, var_h_end - var_h ;Data length
    call memcpy_short

    ;Return
    ret
;



; Contains the initial values of all variables in WRAM0.
var_w0:
    LOAD "WRAM0 INITIALIZED", WRAM0, ALIGN[8]
        w_variables:

        ; 256 bytes of memory that can be used for anything.
        w_buffer:: ds 256

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

        ; Stack-position to exit an entity's gameloop.
        w_entsys_exit:: dw $0000

        ; Tower visuals mode.
        ; Possible flags located in `tower.inc`.
        w_tower_flags:: db $00

        ; Added to tower Y-position every frame.
        w_tower_yspeed:: dw $0000

        ; Tower scroll position.
        ; Call `tower_ypos_truncate` after modifying.
        w_tower_ypos:: dw $0000

        ; Tower segment height in pixels.
        ; Call `tower_ypos_truncate` after modifying.
        w_tower_height:: db $10

        ; Platform Y-position changes by this volume every frame.
        w_platform_yspeed:: dw $0000
        w_platform_ypos:: dw $5000

        ; Platform X-position changes by this volume every frame.
        w_platform_xspeed:: dw $0000
        w_platform_xpos:: dw $9800

        ; Height of platform in pixels.
        w_platform_height:: db $10

        ; Background Y-position changes by this value every frame.
        w_background_yspeed:: dw $0000
        w_background_ypos:: dw $0000

        ; Added to camera X-position every frame.
        w_camera_xspeed:: dw $0000

        ; Camera offset in pixels.
        w_camera_xpos:: dw $4000

        ; A `TOWER_BUFFER` struct.
        ; Prepared for HRAM transfer.
        ; Do not read values from here outside of V-blank.
        w_tower_buffer:: ds TOWER_BUFFER, $00

        ; Color palette for CGB mode.
        w_cgb_palette::
            color_dmg_wht
            color_dmg_ltg
            color_dmg_dkg
            color_dmg_blk
            ASSERT high(w_cgb_palette) == high(w_cgb_palette+7)
        ;
        
        ; Fade value for scene transitions.
        w_fade_state:: db $00
        w_bgp:: dw $0000
        w_obp0:: dw $0000
        w_obp1:: dw $0000

        ; If you just need some value, this will do.
        w_vqueue_writeback:: db $00

        ; Points to the first available vqueue slot.
        w_vqueue_first:: dw w_vqueue

        ; Array of `VQUEUE`.
        ; Only first entry is all on the same page.
        w_vqueue:: ds VQUEUE * VQUEUE_QUEUE_SIZE, VQUEUE_TYPE_NONE
        .end::
        ASSERT high(w_vqueue) == high(w_vqueue + VQUEUE)

        ; Open-ness of shop preview pane.
        w_shop_preview_open:: db $00

        ; What item is currently being previewed?
        w_shop_preview_current:: db $00

        ; Where can I place an item when loading the assets in?  
        ; This value is an offset into `VTI_SHOP_ITEMS`.
        w_shop_itemsprite:: db $00

        ; 16 tiles wide buffer for item name.
        w_shop_namebuffer:: ds $10, " "

        ; Number of waves passed.
        w_waves_passed:: db $00

        ; Current background section.
        w_background_section:: db $03

        ; Writeback address for tower background thing.
        w_background_writeback:: db $00

        ; Writeback target value.
        w_background_writeback_target:: db $00

        w_money:: db $00
        w_player_health:: db $03
        w_player_equipment:: db ITEM_ID_JUMP
        w_player_weapon:: db ITEM_ID_STOMPERS
        w_durability_equipment:: db $03
        w_durability_weapon:: db $03

        ; What sprite slots have been occupied?
        ; This is a bitfield.
        w_tower_spriteslots:: db $00
        w_sprite_rectangle:: db $00

        w_knightling_count:: db $00
        w_knightling_sprite:: db $00
        w_pajamaman_count:: db $00
        w_pajamaman_sprite:: db $00
        w_citizen_count:: db $00
        w_citizen_sprite::db $00

        ; How many active coin entities are there?
        ; This is NOT how much money the player has.
        ; For that, look at `w_money`.
        w_coin_count:: db $00
        w_coin_sprite:: db $00
        w_coin_animate:: db $00

        ; Current painter position.
        w_painter_position:: dw w_paint

    ENDL
    var_w0_end:
;



SECTION "HRAM INITIALIZATION", ROM0

; Contains the initial values for all HRAM variables.
var_h:
    LOAD "HRAM VARIABLES", HRAM
        h_variables::

        ; Collision buffer for faster collision routines.
        h_colbuf::
        h_colbuf1:: ds 4
        h_colbuf2:: ds 4

        ; Run OAM DMA with a pre-specified input.  
        ; Interrupts should be disabled while this runs.  
        ; Assumes OAM access.
        ;
        ; Input:
        ; - `a`: High byte of OAM table
        ;
        ; Destroys: `af`
        h_dma::
            ldh [rDMA], a

            ;Wait until transfer is complete
            ld a, 40
            .wait
            dec a
            jr nz, .wait

            ;Return
            ret
            .end
        ;

        ; LYC interrupt jump-to routine.
        ; Contains a single `jp n16` instruction.
        ; The pointer can be overwritten to whatever you want to jump to.
        h_LYC::
            jp v_error
        ;

        ; High-pointer to OAMMIR struct.
        ; Which OAM mirror is currently in use.
        h_oam_active:: db high(w_oam1)

        ; Used during interrupts as a faster lookup.
        ; Refreshed during/right after V-blank.
        h_tower_buffer:: ds TOWER_BUFFER

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

        ; RNG variables.
        h_rng::

        ; Seed for the next RNG value.
        h_rng_seed:: db $7E, $B2

        ; Last RNG output.
        h_rng_out:: db $00, $00
    ENDL
    var_h_end:
;



SECTION "WRAMX UNINITIALIZED", WRAMX, ALIGN[8]
    ; Entity system.
    w_entsys::
        DEF entity_current = 0
        REPT ENTSYS_CHUNK_COUNT
            w_entsys_bank_{d:entity_current}: ds 1
            w_entsys_next_{d:entity_current}: ds 1
            w_entsys_step_{d:entity_current}: ds 2
            w_entsys_flags_{d:entity_current}: ds 1
            w_entsys_ypos_{d:entity_current}: ds 2
            w_entsys_xpos_{d:entity_current}: ds 2
            w_entsys_height_{d:entity_current}: ds 1
            w_entsys_width_{d:entity_current}: ds 1
            w_entsys_dmgcall_{d:entity_current}: ds 2
            w_entsys_vars_{d:entity_current}: ds 3
            DEF entity_current += 1
        ENDR
        PURGE entity_current
    w_entsys_end::

    ; Paint buffer.
    w_paint:: ds $400
;



SECTION "WRAM0 UNITITIALIZED", WRAM0, ALIGN[8]
    ; OAM mirror, used for DMA.
    ; Use this label to communicate no need for double buffering.
    ; Overlaps with `w_oam1`.
    w_oam::

    ; OAM mirror, used for DMA.
    ; I need 2 main OAM mirrors, because i do DMA midframe.
    ; That means sprites from the next frame might overwrite sprites on the current frame.
    ; So I am double-buffering OAM mirrors.
    w_oam1:: ds OAMMIR
    ASSERT low(w_oam1) == 0

    ; Check documentation for `w_oam1`.
    w_oam2:: ds OAMMIR
    ASSERT low(w_oam2) == 0

    ; HUD OAM.
    ; Most status things will probably be drawn with sprites.
    ; Since I need a sprite on the HUD layer anyway,
    ; I might as well allocate some RAM for it.
    w_oam_hud:: ds OAMMIR
    ASSERT low(w_oam_hud) == 0
;
