RSRESET

; Mirror of `w_tower_flags`.
DEF TOWER_BUFFER_FLAGS RB 1

; Tower interrupt last position.
DEF TOWER_BUFFER_LYC RB 1

; Mirror of high byte of `w_tower_ypos`.
DEF TOWER_BUFFER_TYPOS RB 1

; Tower-layer SCX position.
DEF TOWER_BUFFER_TXPOS RB 1

; Mirror of `w_tower_height`.
DEF TOWER_BUFFER_THEIGHT RB 1

; LCDC value to use when drawing tower.
DEF TOWER_BUFFER_TLCDC RB 1

; Mirror of high byte of `w_platform_ypos`.
DEF TOWER_BUFFER_PYPOS RB 1

; Mirror of high byte of `w_platform_xpos`.
DEF TOWER_BUFFER_PXPOS RB 1

; Mirror of `w_platform_height`.
DEF TOWER_BUFFER_PHEIGHT RB 1

; LCDC value to use when drawing platform.
DEF TOWER_BUFFER_PLCDC RB 1

; Mirror of high byte of `w_background_ypos`.
DEF TOWER_BUFFER_BYPOS RB 1

; Mirror of high byte of `w_background_xpos`.
DEF TOWER_BUFFER_BXPOS RB 1

; Number of bytes in a tower buffer stuct.
DEF TOWER_BUFFER RB 0
