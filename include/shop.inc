    IF !DEF(SHOP_INC)
    DEF SHOP_INC EQU 1

INCLUDE "hardware.inc"

; Window position in shop gameloop.  
; Shows the foreground.
DEF SHOP_WY_FOREGROUND EQU SCRN_Y - 5*8

; Scroll position in shop for background to be visible.
DEF SHOP_SCY_BACKGROUND EQU -20

; Base scroll position for a closed preview pane.
DEF SHOP_SCY_PREVIEW EQU SHOP_SCY_BACKGROUND + 48

; Scroll position for HUD to be visible.
DEF SHOP_SCY_HUD EQU -24

; HUD interrupt LYC position.
DEF SHOP_LYC_HUD EQU 19

; Item preview screen LYC interrupt position.
DEF SHOP_LYC_PREVIEW EQU 48

; Shows the background.
DEF SHOP_LCDC_BACKGROUND EQU LCDCF_ON | LCDCF_BGON | LCDCF_BLK21 | LCDCF_BG9800 | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_OBJON | LCDCF_OBJ16

; Shows the HUD.
DEF SHOP_LCDC_HUD EQU LCDCF_ON | LCDCF_BGON | LCDCF_BLK21 | LCDCF_BG9C00 | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_OBJON | LCDCF_OBJ16

; Shop exit X-position
DEF SHOP_SHOPDOOR_XPOS EQU 136

; Shop exit Y-position
DEF SHOP_SHOPDOOR_YPOS EQU 100

; Max open-ness of the preview pane.
; When this value is reached, item preview movies can begin.
DEF SHOP_PREVIEW_OPEN EQU $30

    ENDC
