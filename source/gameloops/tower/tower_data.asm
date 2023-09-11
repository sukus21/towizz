INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/tower.inc"

SECTION "TOWER ASSETS", ROMX

; Platform tileset made of bricks and stuff.
tower_tls_platform_bricks::
    INCBIN "graphics/tower/platform_bricks.tls"
.end::

; Tower tileset made of bricks.
tower_tls_tower_bricks::
    INCBIN "graphics/tower/bricks.tls"
.end::

; HUD tileset.
tower_tls_hud::
    INCBIN "graphics/hud.tls"
.end::

PUSHC

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

CHARMAP "[", VTI_TOWER_TOWER+0
CHARMAP "]", VTI_TOWER_TOWER+1
CHARMAP "F", VTI_TOWER_TOWER+2
CHARMAP "f", VTI_TOWER_TOWER+3
CHARMAP "L", VTI_TOWER_TOWER+4
CHARMAP "l", VTI_TOWER_TOWER+10
CHARMAP "R", VTI_TOWER_TOWER+5
CHARMAP "r", VTI_TOWER_TOWER+9
CHARMAP " ", VTI_TOWER_TOWER+11
CHARMAP "V", VTI_TOWER_TOWER+13
CHARMAP "w", VTI_TOWER_TOWER+14
CHARMAP "v", VTI_TOWER_TOWER+15
CHARMAP "T", VTI_TOWER_TOWER+6
CHARMAP "_", VTI_TOWER_TOWER+8
CHARMAP "t", VTI_TOWER_TOWER+7
CHARMAP ")", VTI_TOWER_TOWER+12

; Repeated tower tilemap.
; It is easier to generate it this way.
tower_tlm_bricks_segment::
    db "[][][][][][][][F"
    db "][][][][][][][]f"
.end::

; Full tower tilemap.
; Used in non-repeat mode.
tower_tlm_bricks_full::
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][][][][][][]f"
    db "[][][][][][][][F"
    db "][][]T___t)[][]f"
    db "[][][LVwvR[][][F"
    db "][][]Ll rR][][]f"
    db "[][][Ll rR[][][F"
    db "][][]Ll rR][][]f"
.end::

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

; Platform tilemap.
tower_tlm_platform_bricks::
    platform_define "cCm[]McCmMc[]CmF"
.end::


tower_vprep::

tower_vprep_tower: 
    vqueue_prepare_copy \
        VQUEUE_TYPE_DIRECT, \
        VT_TOWER_TOWER, \
        tower_tls_tower_bricks
    ;

    vqueue_prepare_copy \
        VQUEUE_TYPE_HALFROW, \
        VM_TOWER_TOWER1, \
        tower_tlm_bricks_segment
    ;

    vqueue_prepare_copy \
        VQUEUE_TYPE_HALFROW, \
        VM_TOWER_TOWER0, \
        tower_tlm_bricks_full
    ;
;

tower_vprep_platform: 
    vqueue_prepare_copy \
        VQUEUE_TYPE_DIRECT, \
        VT_TOWER_PLATFORM, \
        tower_tls_platform_bricks
    ;

    vqueue_prepare_copy \
        VQUEUE_TYPE_HALFROW, \
        VM_TOWER_PLATFORM, \
        tower_tlm_platform_bricks
    ;
;

tower_vprep_hud:
    vqueue_prepare_copy \
        VQUEUE_TYPE_DIRECT, \
        VT_TOWER_HUD, \
        tower_tls_hud
    ;

    vqueue_prepare_copy \
        VQUEUE_TYPE_SCREENROW, \
        VM_TOWER_HUD, \
        tower_tlm_hud, \
        0, \
        20
    ;
;

POPC
