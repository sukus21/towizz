    IF !DEF(STRUCT_VRAM_TOWER_INC)
    DEF STRUCT_VRAM_TOWER_INC EQU 1

INCLUDE "hardware.inc"
INCLUDE "macros/tilemap.inc"

;Block 0 (sprites only)
RSSET $00

    ; Player tileset.
    DEF VT_TOWER_PLAYER EQU $8000 + $10 * _RS
    DEF VTI_TOWER_PLAYER RB $30
ASSERT _RS <= $80

;Block 1 (sprites + backgrounds)
RSSET $80

    ; Location of platform tileset.
    DEF VT_TOWER_PLATFORM EQU $8000 + $10 * _RS
    DEF VTI_TOWER_PLATFORM RB $20

    ; Test tiles location.
    DEF VT_TOWER_TESTTILES EQU $8000 + $10 * _RS
    DEF VTI_TOWER_TESTTILES RB 8

    ; HUD tiles.
    DEF _RS += _RS & 1
    DEF VT_TOWER_HUD EQU $8000 + $10 * _RS
    DEF VTI_TOWER_HUD RB $10
ASSERT _RS <= $100

;Block 2 (backgrounds only)
RSSET $00

    ;Location of tower tileset.
    DEF VT_TOWER_TOWER EQU $9000 + $10 * _RS
    DEF VTI_TOWER_TOWER RB $20
ASSERT _RS <= $80


;SCRN 0
    tilemap_alloc _SCRN0, "VM_TOWER_BACKGROUND0", 0, 0, 16, 18
    ; Location of background tilemap, used by the window layer.  
    ; Spans 16x18 tiles.  
    ; Located on `SCRN0`.
    DEF VM_TOWER_BACKGROUND0 EQU tlmv_addr

    tilemap_alloc _SCRN0, "VM_TOWER_TOWER0", 16, 0, 16, 32
    ; Location of tower tilemap.  
    ; Spans 16x32 tiles.  
    ; Located on `SCRN0`.
    DEF VM_TOWER_TOWER0 EQU tlmv_addr

    tilemap_alloc_finish
;

;SCRN 1
    tilemap_alloc _SCRN1, "VM_TOWER_BACKGROUND1", 0, 0, 16, 18
    ; Location of background tilemap, used by the window layer.
    ; Spans 16x18 tiles.  
    ; Located on `SCRN1`.
    DEF VM_TOWER_BACKGROUND1 EQU tlmv_addr

    tilemap_alloc _SCRN1, "VM_TOWER_TOWER1", 16, 0, 16, 26
    ; Location of tower tilemap.  
    ; Spans 16x26 tiles.  
    ; Located on `SCRN1`.
    DEF VM_TOWER_TOWER1 EQU tlmv_addr
    
    tilemap_alloc _SCRN1, "VM_TOWER_HUD", 0, 26, 32, 3
    ; Location of HUD tilemap.
    ; HUD elements go here.
    ; 32 * 3 tiles.
    DEF VM_TOWER_HUD EQU tlmv_addr

    tilemap_alloc _SCRN1, "VM_TOWER_PLATFORM", 0, 29, 32, 3
    ; Location of platform tilemap.
    ; I have not yet decided if I'll need the full 3-tile height.
    ; Still reserving it, just in case.
    ; 32 * 3 tiles.
    DEF VM_TOWER_PLATFORM EQU tlmv_addr

    tilemap_alloc_finish
;

    ENDC
