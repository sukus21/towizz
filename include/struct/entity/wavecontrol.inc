    IF !DEF(WAVECONTROL_INC)
    DEF WAVECONTROL_INC EQU 1

INCLUDE "entsys.inc"
INCLUDE "macros/farcall.inc"
INCLUDE "struct/vqueue.inc"

RSSET ENTVAR_VAR
DEF ENTVAR_WAVECONTROL_START RB 0
DEF ENTVAR_WAVECONTROL_BEGUN RB 1
DEF ENTVAR_WAVECONTROL_SP RB 2
DEF ENTVAR_WAVECONTROL_HL RB 2
DEF ENTVAR_WAVECONTROL_PC RB 2
DEF ENTVAR_WAVECONTROL_WRITEBACK RB 1
DEF ENTVAR_WAVECONTROL_DRAGDOWN RB 8

DEF ENTVAR_WAVECONTROL_END RB 0
DEF ENTVAR_WAVECONTROL_COUNT EQU _RS - ENTVAR_WAVECONTROL_START
STATIC_ASSERT ENTVAR_WAVECONTROL_END <= 64

DEF WAVECONTROL_FLAGS EQU 0

MACRO wavecontrol_relpointer_init
    entsys_relpointer_init \1, %11000000
ENDM

; Creates an entity, and adds it to the dragdown list.
;
; Input:
; - `hl`: Entity pointer (anywhere)
; - `1`: Entity creation routine (label)
; - `2`: Entity X-position (n8)
; - `3`: Entity Y-position (n8)
; - `4`: Dragdown slot (n8, 0-3)
;
; Saves: relpointer
MACRO wavecontrol_create_dragdown
    push hl
    ld bc, (\2 << 8) + (\3)
    farcall_x \1
    ld d, h
    ld e, l
    pop hl
    relpointer_move ENTVAR_WAVECONTROL_DRAGDOWN + (\4 * 2)
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl-], a
ENDM

    ENDC
