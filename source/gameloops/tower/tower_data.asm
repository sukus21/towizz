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
    INCBIN "graphics/hud_test.tls"
.end::

; Tileset of tower made of bricks.
tower_asset_bricks::
    INCBIN "graphics/tower_bricks.tls"
.end::

; Grassy platform tileset.
tower_asset_platform_grassy::
    INCBIN "graphics/platform_grass.tls"
.end::

; Some test-tiles.
; TODO: make a proper tileset.
tower_asset_testtiles::
    dw `30000003
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `30000003

    dw `31111113
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `11111111
    dw `31111113

    dw `32222223
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `22222222
    dw `32222223

    dw `23333332
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `23333332

    dw `32112213
    dw `22112211
    dw `11221122
    dw `11221122
    dw `22112211
    dw `22112211
    dw `11221122
    dw `31221123

    dw `32112213
    dw `22112211
    dw `11221122
    dw `11221122
    dw `22112211
    dw `22112211
    dw `11221122
    dw `31221123
.end::



SECTION UNION "TOWER VRAM", VRAM[$8000]
    ;Reserved for future use
    ds $10 * $80

    ; Location of platform tileset.
    vt_tower_platform:: ds $10 * $20

    ; Test tiles location.
    vt_tower_testtiles:: ds $10 * $10

    ;Reserved for future use
    ds $10 * $40

    ; HUD tiles
    vt_tower_hud:: ds $10 * $10

    ;Location of tower tileset.
    vt_tower_tower:: ds $10 * $20

    ;Reserved for future use
    ds $10 * $60


    ; Location of background tilemap, used by the window layer.  
    ; Spans 16x18 tiles.  
    ; Located on `SCRN0`.
    vm_tower_background0:: ds $10

    ; Location of tower tilemap.  
    ; Spans 16x32 tiles.  
    ; Located on `SCRN0`.
    vm_tower_tower0:: ds $10 + $1F * $20

    ; Location of background tilemap, used by the window layer.
    ; Spans 16x18 tiles.  
    ; Located on `SCRN1`.
    vm_tower_background1:: ds $10

    ; Location of tower tilemap.  
    ; Spans 16x26 tiles.  
    ; Located on `SCRN1`.
    vm_tower_tower1:: ds $10
    ds $20 * 25
    
    ; Location of HUD tilemap.
    ; HUD elements go here.
    ; 32 * 3 tiles.
    vm_tower_hud:: ds $20 * 3

    ; Location of platform tilemap.
    ; I have not yet decided if I'll need the full 3-tile length.
    ; Still reserving it, just in case.
    ; 32 * 3 tiles.
    vm_tower_platform:: ds $20 * 3
;
