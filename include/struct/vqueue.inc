RSRESET

; Vqueue element not currently used.
DEF VQUEUE_TYPE_NONE RB 1

; Copies data directly from source to destination.
; One transfer operation = 16 bytes.
DEF VQUEUE_TYPE_BULK RB 1

; Sets data at the destination to a given byte.
; One transfer operation = 16 bytes.
DEF VQUEUE_TYPE_SET RB 1

; Copies data from source to destination.
; Every 16 copied bytes, the destination pointer is moved 16 bytes forward.
; One transfer operation = 16 bytes.
DEF VQUEUE_TYPE_HALFMAP RB 1

RSRESET

; Type of this vqueue element.
; Check `VQUEUE_TYPE_*` to see available types.
DEF VQUEUE_TYPE RB 1

; Number of transfer operations to perform.
; Does not have to mean bytes.
DEF VQUEUE_LENGTH RB 1

; Number of transfer operations completed.
; When this number matches the length, the transfer is considered complete.
DEF VQUEUE_PROGRESS RB 1

; Pointer to destination data.
DEF VQUEUE_DESTINATION RB 2

; Source data ROM bank.
DEF VQUEUE_SOURCE_BANK RB 1

; Pointer to source data.
DEF VQUEUE_SOURCE RB 2

; Increments the value at this address when transfer is complete.
DEF VQUEUE_WRITEBACK RB 2

; A VRAM transfer queue object.
DEF VQUEUE RB 0



; Macro that adds an element to the VRAM transfer queue.
; Does not set writeback pointer.
;
; Input:
; - `1`: Transfer type (`VQUEUE_TYPE_*`)
; - `2`: Transfer operation count
; - `3`: Destination (address/label)
; - `4`: Source (label)
;
; Returns:
; - `hl`: `VQUEUE` pointer, at `VQUEUE_WRITEBACK`
;
; Destroys: `af`  
; Saves: `bc`, `de`
MACRO vqueue_add
    call vqueue_get

    ;Write type and length
    ld a, \1
    ld [hl+], a ;type
    ld a, \2
    ld [hl+], a ;length
    xor a
    ld [hl+], a ;progress

    ;Write destination
    ld a, low(\3)
    ld [hl+], a ;destination (low)
    ld a, high(\3)
    ld [hl+], a ;destination (high)
    
    ;Write source
    ld a, bank(\4)
    ld [hl+], a
    ld a, low(\4)
    ld [hl+], a
    ld a, high(\4)
    ld [hl+], a
ENDM
