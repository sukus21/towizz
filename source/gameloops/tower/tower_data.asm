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
