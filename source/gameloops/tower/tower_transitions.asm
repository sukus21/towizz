INCLUDE "tower.inc"

SECTION "TOWER TRANSITIONS", ROM0

; Transition to the tower gameloop from the shop gameloop.  
; Does not return, resets stack pointer.  
; Lives in ROM0.
tower_transition_shop::
    di
    ld sp, w_stack

    ;Set camera position
    ld hl, w_camera_xspeed
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], TOWER_CAMERA_XPOS_SHOP

    ;Set platform position
    ld hl, w_platform_yspeed
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], TOWER_PLATFORM_YPOS_SHOP
    ld hl, w_platform_xspeed
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], TOWER_PLATFORM_XPOS_SHOP

    ;Background should be at 0? I guess?
    ld hl, w_background_yspeed
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a

    ;Go to gameloop 
    jp gameloop_tower
;
