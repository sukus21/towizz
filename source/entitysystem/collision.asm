INCLUDE "entsys.inc"
INCLUDE "macros/relpointer.inc"

SECTION "ENTSYS COLLISION", ROM0

; Checks for collision between two rectangles.  
; Always assumes x2 >= x1 and y2 >= y1 for both boxes.  
; Expects 2-bit alignment on `bc` and `de`.  
; Lives in ROM0.
;
; Input:
; - `bc`: rect 1 ptr [XxYy]
; - `de`: rect 2 ptr [XxYy]
;
; Returns:
; - `a`: collision or not (true/false)
entsys_collision_rr8::
    ld h, d
    ld l, e

    ;if(rect1.X < rect2.X)
    ld a, [bc]
    cp a, [hl]

    jr nc, .higherX

        ;if(rect1.x < rect2.X)
        inc c
        ld a, [bc]
        inc c
        ld d, [hl]
        inc l
        inc l
        cp a, d
        
        jr nc, .ycheck
        xor a
        ret 

    .higherX

        ;if(rect1.X > rect2.x)
        ld d, a
        inc c
        inc c
        inc l
        ld a, [hl+]
        cp a, d

        jr nc, .ycheck
        xor a
        ret 
    ;

    .ycheck

    ;if(rect1.Y < rect2.Y)
    ld a, [bc]
    cp a, [hl]

    jr nc, .higherY

        ;if(rect1.y < rect2.Y)
        inc c
        ld a, [bc]
        ld d, [hl]
        cp a, d

        ld a, 0 ;does not change flags
        adc a, a
        ret 

    .higherY

        ;if(rect1.Y > rect2.y)
        ld a, [bc]
        ld d, a
        inc l
        ld a, [hl+]
        cp a, d

        ccf
        ld a, 0 ;does not change flags
        adc a, a
        ret 
    ;
;



; Checks for collision between two rectangles.  
; Always assumes x2 >= x1 and y2 >= y1 for both boxes.  
; Expects 3-bit alignment on `bc` and `de`.  
; Lives in ROM0.
;
; Input:
; - `bc`: rect 1 ptr [XXxxYYyy]
; - `de`: rect 2 ptr [XXxxYYyy]
;
; Returns:
; - `a`: collision or not (true/false)
entsys_collision_rr16::
    ld h, d
    ld l, e

    ;if(rect1.X < rect2.X)
    ld a, [bc]
    inc c
    cp a, [hl]
    inc hl ;does not change flags

    ;High bytes were the same, compare low bytes
    jr nz, :+
        ld a, [bc]
        cp a, [hl]
    :
    jr nc, .higherX

        ;if(rect1.x < rect2.X)
        ld d, [hl]
        dec l
        inc c
        ld a, [bc]
        cp a, [hl]

        ;High bytes were the same, compare low bytes
        jr nz, :+
            inc c
            ld a, [bc]
            cp a, d
        :
        
        jr nc, .ycheck
        xor a
        ret 

    .higherX

        ;if(rect1.X > rect2.x)
        inc l
        dec c
        ld a, [bc]
        ld d, a
        ld a, [hl+]
        cp a, d

        ;High bytes were the same, compare low bytes
        jr nz, :+
            inc c
            ld a, [bc]
            ld d, a
            ld a, [hl]
            cp a, d
        :

        jr nc, .ycheck
        xor a
        ret 
    ;

    .ycheck

    ;Align to Y-values
    ld a, l
    or a, %00000011
    inc a
    ld l, a
    ld a, c
    or a, %00000011
    inc a
    ld c, a

    ;if(rect1.Y < rect2.Y)
    ld a, [bc]
    inc c
    cp a, [hl]
    inc hl ;does not change flags

    ;High bytes were the same, compare low bytes
    jr nz, :+
        ld a, [bc]
        cp a, [hl]
    :
    jr nc, .higherY

        ;if(rect1.y < rect2.Y)
        ld d, [hl]
        dec l
        inc c
        ld a, [bc]
        cp a, [hl]

        ;High bytes were the same, compare low bytes
        jr nz, :+
            inc c
            ld a, [bc]
            cp a, d
        :

        ld a, 0 ;does not change flags
        adc a, a
        ret 

    .higherY

        ;if(rect1.Y > rect2.y)
        inc l
        dec c
        ld a, [bc]
        ld d, a
        ld a, [hl+]
        cp a, d

        ;High bytes were the same, compare low bytes
        jr nz, :+
            inc c
            ld a, [bc]
            ld d, a
            ld a, [hl]
            cp a, d
        :

        ccf
        ld a, 0 ;does not change flags
        adc a, a
        ret 
    ;
;



; Checks for collision between a point and a rectangle.
; Always assumes x2 >= x1 and y2 >= y1 for the rectangle.
; Expects 3-bit alignment on `de`.
; Lives in ROM0.
;
; Input:
; - `bc`: point ptr [XXYY]
; - `de`: rect ptr [XXxxYYyy]
;
; Returns:
; - `a`: collision or not (true/false)
entsys_collision_pr16::
    ld h, d
    ld l, e

    ;if(point.X < rect.X)
    ld a, [bc]
    ld e, a ;save point high X in e
    inc bc
    cp a, [hl]
    inc hl ;does not change flags

    ;High bytes were the same, compare low bytes
    jr nz, :+
        ld a, [bc]
        cp a, [hl]
    :
    jr nc, .higherX
        xor a
        ret

    .higherX

        ;if(point.X > rect.x)
        inc l
        ld a, [hl+]
        cp a, e

        ;High bytes were the same, compare low bytes
        jr nz, :+
            ld a, [bc]
            ld d, a
            ld a, [hl]
            cp a, d
        :

        jr nc, .ycheck
        xor a
        ret 
    ;

    .ycheck

    ;Align to Y-values
    ld a, l
    or a, %00000011
    inc a
    ld l, a
    inc bc

    ;if(point.Y < rect.Y)
    ld a, [bc]
    ld e, a ;save point high Y in e
    inc bc
    cp a, [hl]
    inc hl ;does not change flags

    ;High bytes were the same, compare low bytes
    jr nz, :+
        ld a, [bc]
        cp a, [hl]
    :
    jr nc, .higherY
        xor a
        ret 

    .higherY

        ;if(point.Y > rect.y)
        inc l
        ld a, [hl+]
        cp a, e

        ;High bytes were the same, compare low bytes
        jr nz, :+
            ld a, [bc]
            ld d, a
            ld a, [hl]
            cp a, d
        :

        ;Final result
        ccf 
        ld a, 0 ;does not change flags
        adc a, a
        ret 
    ;
;



; Write a collision-enabled entity's collision data into buffer.
; This only writes the high-byte of the position, not the low-byte.
; This will always write to the second position in the buffer, not the first.  
; Lives in ROM0.
;
; Input:
; - `hl`: Entity pointer (anywhere)
;
; Saves: `hl`  
; Destroys: `af`, `bc`, `de`
entsys_collision_prepare_8::
    push hl
    
    ;Get top-left corner
    entsys_relpointer_init ENTVAR_YPOS+1
    ld e, [hl]
    relpointer_move ENTVAR_XPOS+1
    ld b, [hl]

    ;Get bottom-right
    relpointer_move ENTVAR_HEIGHT
    ld a, e
    sub a, [hl]
    ld c, a
    relpointer_move ENTVAR_WIDTH
    ld a, b
    add a, [hl]
    ld d, a
    relpointer_destroy

    ;Debug thing
    call entsys_boundsdraw

    ;Write data to buffer
    ld hl, w_buffer+4
    ld a, b
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ld [hl], e

    ;Return
    pop hl
    ret
;



; Draw a test rectangle.  
; Assumes rectangle tiles are loaded.  
; Lives in ROM0.
;
; Input:
; - `b`: Left X-pos
; - `c`: Top Y-pos
; - `d`: Right X-pos
; - `e`: Bottom Y-pos
;
; Saves: `bc`, `de`
;
entsys_boundsdraw::
    push bc
    push de

    ;Adjust X-coordinates
    ld a, [w_camera_xpos+1]
    ld h, a
    ld a, b
    sub a, h
    ld b, a
    ld a, d
    sub a, h
    ld d, a

    ;Draw thing
    call rectangle_points_draw

    ;Return
    pop de
    pop bc
    ret
;
