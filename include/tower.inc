; Height of the HUD.
DEF HUD_HEIGHT EQU $14

; Coordinate for SCX when displaying HUD.
DEF HUD_SCX EQU $00

; Coordniate for SCY when displaying HUD.
DEF HUD_SCY EQU -$30

; Height of the platform.
DEF PLATFORM_HEIGHT EQU $18

; Resting position of platform when not in use
DEF PLATFORM_DISABLE EQU SCRN_Y + 1

; Platform scroll position
DEF PLATFORM_SCY EQU -$18

; Background SCX when offscreen
DEF BACKGROUND_OFFSCREEN_SCX EQU SCRN_X + 5

RSRESET

; Dictates what tilemap the window layer should use.  
; 0 = SCRN0.  
; 1 = SCRN1.
DEF TOWERMODEF_WINDOW_TILEMAP EQU 1 << _RS
DEF TOWERMODEB_WINDOW_TILEMAP RB 1

; Dictates what tilemap the tower "layer" should use.  
; 0 = SCRN0.  
; 1 = SCRN1.
DEF TOWERMODEF_TOWER_TILEMAP EQU 1 << _RS
DEF TOWERMODEB_TOWER_TILEMAP RB 1

; Toggles repeat mode.
; When switched off, works best with tower on SCRN1.
DEF TOWERMODEF_TOWER_REPEAT EQU 1 << _RS
DEF TOWERMODEB_TOWER_REPEAT RB 1
