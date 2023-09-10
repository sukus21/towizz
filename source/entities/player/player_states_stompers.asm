INCLUDE "macros/farcall.inc"
INCLUDE "macros/relpointer.inc"
INCLUDE "struct/entity/player.inc"

SECTION FRAGMENT "PLAYER", ROMX

; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`
player_state_stompers_jump::
    ret
;



; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`
player_state_stompers_spin::
    ret
;



; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`
player_state_stompers_stomp::
    ret
;



; Input:
; - `hl`: Player entity pointer (anywhere)
;
; Saves: `hl`
player_state_stompers_land::
    ret
;
