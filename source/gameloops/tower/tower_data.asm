INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/tower.inc"

SECTION "TOWER ASSETS", ROMX

MACRO asset
    INCBIN STRCAT("graphics/tower/", \1)
    .end::
ENDM

; Platform tileset made of bricks and stuff.
tower_tls_platform_bricks:: asset "platform_bricks.tls"

; Platform tilemap.
tower_tlm_platform_bricks::
    PUSHC
    CHARMAP "[", VTI_TOWER_PLATFORM+0
    CHARMAP "]", VTI_TOWER_PLATFORM+2
    CHARMAP "M", VTI_TOWER_PLATFORM+8
    CHARMAP "m", VTI_TOWER_PLATFORM+10
    CHARMAP "F", VTI_TOWER_PLATFORM+12
    CHARMAP "C", VTI_TOWER_PLATFORM+4
    CHARMAP "c", VTI_TOWER_PLATFORM+6
    MACRO platform_define
        db \1
        FOR N, 16
            db STRSUB(\1, N+1, 1)+1
        ENDR
    ENDM
    platform_define "cCm[]McCmMc[]CmF"
    POPC
.end::

; Tower tileset made of bricks.
tower_tls_tower_bricks:: asset "bricks.tls"
tower_tlm_door_close:: asset "bricks_door_close.tlm"
tower_tlm_door_middle:: asset "bricks_door_middle.tlm"
tower_tlm_door_far:: asset "bricks_door_far.tlm"
tower_tlm_door_double:: asset "bricks_door_double.tlm"
tower_tlm_gate_close:: asset "bricks_gate_close.tlm"
tower_tlm_gate_far:: asset "bricks_gate_far.tlm"
tower_tlm_gate_double:: asset "bricks_gate_double.tlm"
tower_tlm_segment_8:: asset "bricks_segment_8.tlm"

; HUD tileset.
tower_tls_hud:: INCBIN "graphics/hud.tls"
.end::

; HUD tilemap.
tower_tlm_hud:
    ds 6, VTI_TOWER_HUD
    db VTI_TOWER_HUD+4, VTI_TOWER_HUD+6
    ds 3, VTI_TOWER_HUD
    db VTI_TOWER_HUD+8, VTI_TOWER_HUD+10
    ds 7, VTI_TOWER_HUD

    ds 6, VTI_TOWER_HUD
    db VTI_TOWER_HUD+5, VTI_TOWER_HUD+7
    ds 3, VTI_TOWER_HUD
    db VTI_TOWER_HUD+9, VTI_TOWER_HUD+11
    ds 7, VTI_TOWER_HUD

    ds 20, VTI_TOWER_HUD+1
.end



tower_vprep::

    ;Tower transfers
    vqueue_prepare_copy VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $0C0, tower_tlm_gate_close
    vqueue_prepare_copy VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER1 + $000, tower_tlm_segment_8
    vqueue_prepare_copy VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $000, tower_tlm_segment_8
    vqueue_prepare_copy VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $100, tower_tlm_segment_8
    vqueue_prepare_copy VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $200, tower_tlm_segment_8
    vqueue_prepare_copy VQUEUE_TYPE_HALFROW, VM_TOWER_TOWER0 + $300, tower_tlm_segment_8

    ;Platform transfers
    vqueue_prepare_copy VQUEUE_TYPE_DIRECT, VT_TOWER_PLATFORM, tower_tls_platform_bricks
    vqueue_prepare_copy VQUEUE_TYPE_HALFROW, VM_TOWER_PLATFORM, tower_tlm_platform_bricks
    
    ;HUD transfers
    vqueue_prepare_copy VQUEUE_TYPE_DIRECT, VT_TOWER_HUD, tower_tls_hud
    vqueue_prepare_copy VQUEUE_TYPE_SCREENROW, VM_TOWER_HUD, tower_tlm_hud, 0, 20
;



; Queues up brick tower tileset.
;
; Input:
; - `de`: Writeback pointer
;
; Saves: `de`
tower_bricks_load::
    vqueue_add_copy VQUEUE_TYPE_DIRECT, VT_TOWER_TOWER, tower_tls_tower_bricks
    ld a, e
    ld [hl+], a
    ld [hl], d
    ret
;
