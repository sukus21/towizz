; Sets the bytes at `h_LYC` to the given label.
; Removes the value that was previously there.
;
; Input:
; - `1`: Address/label
;
; Destroys: `a`
MACRO LYC_set_jumppoint
    ld a, low(\1)
    ldh [h_LYC+1], a
    ld a, high(\1)
    ldh [h_LYC+2], a
ENDM



; Wait for H-blank by polling rSTAT.
; Assumes LCD is turned on.
; Assumes non-vblank.
;
; Destroys: `af`
MACRO LYC_wait_hblank
    ldh a, [rSTAT]
    bit 1, a
    jr nz, @-4
ENDM
