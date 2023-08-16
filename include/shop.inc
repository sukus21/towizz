    IF !DEF(SHOP_INC)
    DEF SHOP_INC EQU 1

INCLUDE "hardware.inc"

; Window position in shop gameloop.  
; Shows the foreground.
DEF SHOP_WY_FOREGROUND EQU SCRN_Y - 5*8

; Scroll position in shop for background to be visible.
DEF SHOP_SCY_BACKGROUND EQU -20

; Scroll position for HUD to be visible.
DEF SHOP_SCY_HUD EQU -24

; HUD interrupt LYC position.
DEF SHOP_LYC_HUD EQU 19

; Shows the background.
DEF SHOP_LCDC_BACKGROUND EQU LCDCF_ON | LCDCF_BGON | LCDCF_BLK21 | LCDCF_BG9800 | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_OBJON | LCDCF_OBJ16

; Shows the HUD.
DEF SHOP_LCDC_HUD EQU LCDCF_ON | LCDCF_BGON | LCDCF_BLK21 | LCDCF_BG9C00 | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_OBJON | LCDCF_OBJ16

    ENDC
