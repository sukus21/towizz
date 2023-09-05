INCLUDE "struct/vqueue.inc"
INCLUDE "struct/vram/tower.inc"

SECTION "TOWER ASSETS", ROMX

; Platform tileset.
tower_asset_platform::
    INCBIN "graphics/platform_test.tls"
.end::

; Tower tileset.
tower_asset_tower::
    INCBIN "graphics/tower_test.tls"
.end::

; HUD tileset.
tower_asset_hud::
    INCBIN "graphics/hud.tls"
.end::

; Tileset of tower made of bricks.
tower_asset_bricks::
    INCBIN "graphics/tower_bricks.tls"
.end::

; Grassy platform tileset.
tower_asset_platform_grassy::
    INCBIN "graphics/platform_grass.tls"
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

; Repeated tower tilemap.
; It is easier to generate it this way.
tower_tilemap_tower::
    DEF TOWER_TILE = VTI_TOWER_TOWER+0
    REPT 16
        db TOWER_TILE
        DEF TOWER_TILE += 2
    ENDR
    DEF TOWER_TILE = VTI_TOWER_TOWER+1
    REPT 16
        db TOWER_TILE
        DEF TOWER_TILE += 2
    ENDR
.end::

; Platform tilemap.
; It is easier to generate it this way.
tower_tilemap_platform::
    DEF TOWER_TILE = VTI_TOWER_PLATFORM-6
    REPT 16
        db TOWER_TILE
        DEF TOWER_TILE += 2
    ENDR
    DEF TOWER_TILE = VTI_TOWER_PLATFORM-5
    REPT 16
        db TOWER_TILE
        DEF TOWER_TILE += 2
    ENDR
.end::


tower_vprep::

tower_vprep_tower: 
    vqueue_prepare_copy \
        VQUEUE_TYPE_DIRECT, \
        VT_TOWER_TOWER, \
        tower_asset_tower
    ;

    vqueue_prepare_copy \
        VQUEUE_TYPE_HALFROW, \
        VM_TOWER_TOWER0, \
        tower_tilemap_tower
    ;
;

tower_vprep_platform: 
    vqueue_prepare_copy \
        VQUEUE_TYPE_DIRECT, \
        VT_TOWER_PLATFORM, \
        tower_asset_platform
    ;

    vqueue_prepare_copy \
        VQUEUE_TYPE_HALFROW, \
        VM_TOWER_PLATFORM, \
        tower_tilemap_platform
    ;
;

tower_vprep_hud:
    vqueue_prepare_copy \
        VQUEUE_TYPE_DIRECT, \
        VT_TOWER_HUD, \
        tower_asset_hud
    ;

    vqueue_prepare_copy \
        VQUEUE_TYPE_SCREENROW, \
        VM_TOWER_HUD, \
        tower_tlm_hud, \
        0, \
        20
    ;
;
