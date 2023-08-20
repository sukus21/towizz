INCLUDE "entsys.inc"

DEF ENTVAR_SHOPITEM_START EQU ENTVAR_VAR
RSSET ENTVAR_SHOPITEM_START

; X-position on the screen, in pixels.
; There is only an X-position, the Y-position is hardcoded.
; This is used as an ID in some cases.
; For that reason, shopitem entities should ever overlap.
DEF ENTVAR_SHOPITEM_XPOS RB 1

; What sprite tile to draw.
DEF ENTVAR_SHOPITEM_SPRITE RB 1

; Pointer to `ITEM` struct.
DEF ENTVAR_SHOPITEM_PTR RB 2

; Price of this item.
DEF ENTVAR_SHOPITEM_PRICE RB 1

; Preview loading writeback location.
DEF ENTVAR_SHOPITEM_WRITEBACK RB 1

DEF ENTVAR_SHOPITEM_END RB 0
DEF ENTVAR_SHOPITEM_COUNT EQU ENTVAR_SHOPITEM_END - ENTVAR_SHOPITEM_START
ASSERT ENTVAR_SHOPITEM_END <= 16
