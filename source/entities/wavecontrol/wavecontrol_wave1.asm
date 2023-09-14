INCLUDE "entsys.inc"
INCLUDE "tower.inc"
INCLUDE "macros/color.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "macros/farcall.inc"
INCLUDE "struct/vqueue.inc"
INCLUDE "struct/entity/wavecontrol.inc"
INCLUDE "struct/vram/tower.inc"

SECTION FRAGMENT "WAVECONTROL", ROMX

; Initialize data for wave 1.
; Queues up a ton of VQUEUE transfers.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: unknown
wavecontrol_wave1::
    push hl

    ;Set tower flags
    ld a, [w_tower_flags]
    and a, TOWERMODEF_WINDOW_TILEMAP
    or a, TOWERMODEF_TOWER_TILEMAP | TOWERMODEF_TOWER_REPEAT
    ld [w_tower_flags], a

    ;Load background
    ld b, 3
    farcall_x tower_background_fullqueue
    pop hl
    call wavecontrol_block_checkpoint
    call wavecontrol_block_vqueue_empty

    ;Load enemies
    wavecontrol_relpointer_init ENTVAR_WAVECONTROL_WRITEBACK
    push hl
    ld d, h
    ld e, l
    farcall_x entity_knightling_load
    farcall_x entity_pajamaman_load
    farcall_x entity_citizen_load

    ;Load background tilesets
    farcall_x tower_bricks_load

    ;Transfer tower tilemaps
    vqueue_addw VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER1 + $000, tower_tlm_segment_8, de
    vqueue_addw VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $000, tower_tlm_segment_8, de
    vqueue_addw VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $100, tower_tlm_segment_8, de
    vqueue_addw VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $200, tower_tlm_segment_8, de
    vqueue_addw VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $300, tower_tlm_segment_8, de

    ;Wait for transfers to complete
    pop hl
    call wavecontrol_block_checkpoint
    ld b, 9
    call wavecontrol_block_vqueue
    
    ;Fade screen in
    push hl
    ld a, PALETTE_DEFAULT
    ld [w_bgp+1], a
    ld [w_obp0+1], a
    ld a, COLOR_FADESTATE_IN
    call transition_fade_init
    pop hl

    ;Alrighty, wait for gameloop to begin
    call wavecontrol_block_checkpoint
    ldh a, [h_input_pressed]
    bit PADB_START, a
    jp z, wavecontrol_block_return
    call wavecontrol_block_checkpoint
    ld bc, $0280
    ld de, $0008
    call wavecontrol_block_vspeed_add
    
    ;Round 1 (single knightling)
    wavecontrol_writeback_reset
    vqueue_addw VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $340, tower_tlm_gate_middle, de
    call wavecontrol_block_checkpoint
    ld b, 1
    call wavecontrol_block_vqueue
    wavecontrol_set16 w_tower_ypos, $0000
    ld a, [w_tower_flags]
    and a, TOWERMODEF_WINDOW_TILEMAP
    ld [w_tower_flags], a
    wavecontrol_create_dragdown entity_knightling_create, $4C, $FC, 0
    wavecontrol_set16 w_platform_xspeed, $0050
    call wavecontrol_block_checkpoint
    wavecontrol_moveto w_platform_ypos, $5F00, $0080
    wavecontrol_moveto w_camera_xpos, $3000, $0080
    ld bc, 0
    ld de, $0008
    call wavecontrol_block_vspeed_sub
    call wavecontrol_block_checkpoint
    call wavecontrol_dragdown_release
    wavecontrol_set16 w_platform_xspeed, $0000

    ;Round 2 (dual knightlings)
    wavecontrol_writeback_reset
    vqueue_addw VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $140, tower_tlm_gate_double, de
    call wavecontrol_block_checkpoint
    wavecontrol_waitval w_knightling_count, 0
    ld b, 1
    call wavecontrol_block_vqueue
    wavecontrol_create_dragdown entity_knightling_create, $26, $DE, 0
    wavecontrol_create_dragdown entity_knightling_create, $55, $DE, 1
    call wavecontrol_block_checkpoint
    wavecontrol_moveto w_camera_xpos, $1000, $0060
    wavecontrol_set16 w_platform_xspeed, -$00D0
    ld bc, $0300
    ld de, $0010
    call wavecontrol_block_vspeed_add
    call wavecontrol_block_checkpoint
    wavecontrol_moveto w_camera_xpos, $1000, $0060
    wavecontrol_moveto w_platform_ypos, $6C00, $0080
    wavecontrol_set16 w_platform_xspeed, 0
    ld bc, $0000
    ld de, $0010
    call wavecontrol_block_vspeed_sub
    call wavecontrol_dragdown_release
    wavecontrol_waitval w_knightling_count, 0

    ;Round 3 (single pajamaman)
    wavecontrol_writeback_reset
    vqueue_addw VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $300, tower_tlm_segment_8, de
    call wavecontrol_block_checkpoint
    ld b, 1
    call wavecontrol_block_vqueue
    wavecontrol_set16 w_platform_xspeed, $0080
    call wavecontrol_block_checkpoint
    wavecontrol_moveto w_camera_xpos, $5000, $0100
    ld bc, $0380
    ld de, $0010
    call wavecontrol_block_vspeed_add
    wavecontrol_set16 w_platform_xspeed, 0
    wavecontrol_create_dragdown entity_pajamaman_create, $00, $00
    ld a, [w_tower_flags]
    and a, TOWERMODEF_WINDOW_TILEMAP
    or a, TOWERMODEF_TOWER_REPEAT | TOWERMODEF_TOWER_TILEMAP
    ld [w_tower_flags], a
    wavecontrol_set16 w_tower_ypos, 0
    call wavecontrol_block_checkpoint
    ld bc, $0060
    ld de, $0008
    call wavecontrol_block_vspeed_sub
    call wavecontrol_block_checkpoint
    wavecontrol_waitval w_pajamaman_count, 0

    ;Round 4 (knightlings + pajamaman)
    wavecontrol_create_dragdown entity_pajamaman_create, 0, 0
    wavecontrol_writeback_reset
    vqueue_addw VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $340, tower_tlm_gate_double, de
    vqueue_addw VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $100, tower_tlm_segment_8, de
    call wavecontrol_block_checkpoint
    ld bc, $0280
    ld de, $0008
    call wavecontrol_block_vspeed_add
    ld b, 2
    call wavecontrol_block_vqueue
    wavecontrol_set16 w_tower_ypos, $0000
    ld a, [w_tower_flags]
    and a, TOWERMODEF_WINDOW_TILEMAP
    ld [w_tower_flags], a
    wavecontrol_create_dragdown entity_knightling_create, $26, $FC, 0
    wavecontrol_create_dragdown entity_knightling_create, $55, $FC, 1
    wavecontrol_set16 w_platform_xspeed, -$001C
    call wavecontrol_block_checkpoint
    wavecontrol_moveto w_platform_ypos, $5F00, $0080
    wavecontrol_moveto w_camera_xpos, $0F00, $0080
    ld bc, 0
    ld de, $0008
    call wavecontrol_block_vspeed_sub
    call wavecontrol_block_checkpoint
    call wavecontrol_dragdown_release
    wavecontrol_set16 w_platform_xspeed, $0000
    call wavecontrol_block_checkpoint
    wavecontrol_waitval w_pajamaman_count, 0
    wavecontrol_waitval w_knightling_count, 0

    ;End of wave. Go to shop
    relpointer_move ENTVAR_WAVECONTROL_TIMER
    ld [hl], 50
    call wavecontrol_block_checkpoint
    dec [hl]
    jp nz, wavecontrol_block_return
    ld a, COLOR_FADESTATE_OUT
    push hl
    call transition_fade_init
    pop hl
    relpointer_move ENTVAR_WAVECONTROL_TIMER
    ld [hl], 50
    call wavecontrol_block_checkpoint
    dec [hl]
    jp nz, wavecontrol_block_return

    ;Alright, we are officially done here.
    relpointer_destroy
    jp gameloop_shop
;
