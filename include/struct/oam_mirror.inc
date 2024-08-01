; Size of a OAM mirror struct.
; Should always be byte-aligned.
DEF OAMMIR EQU $100
RSRESET

; The OAM mirror itself.
DEF OAMMIR_OAM RB $A0
RSSET _RS + $50 ;filler, in case too many sprites are allocated per frame

; Low-pointer to first free sprite in this mirror.
DEF OAMMIR_COUNT RB $01

; Number of bytes in the mirror used previous frame.
; Used to speed up `sprite_finish`.
DEF OAMMIR_PREVIOUS RB $01
