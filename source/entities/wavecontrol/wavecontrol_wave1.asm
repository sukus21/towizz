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
    call wavecontrol_block_begun

    ;Ok, that's all the time I've got.
    relpointer_destroy
    ret
;
