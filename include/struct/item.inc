DEF ITEM_NAME_LENGTH EQU 10

RSRESET

; ID of this item.
DEF ITEM_ID RB 1

; Name length, 10 long, space-padded.
DEF ITEM_NAME RB ITEM_NAME_LENGTH

; Base price stored in binary.
DEF ITEM_PRICE RB 1

; Pointer to preview init function.
DEF ITEM_PREVIEW_INIT RB 2

; Pointer to preview step function.
DEF ITEM_PREVIEW_STEP RB 2

; Item struct.
; Contains name, pointers to preview functions, and base price.  
; This constant can be used as the size of an item entity.
DEF ITEM RB 0

RSRESET
DEF ITEM_ID_BALL RB 1



; Define an item.
; Expands to 16 bytes of data.
;
; Input:
; - `1`: Item ID (n8)
; - `2`: Item name (string)
; - `3`: Item base price (n8)
; - `4`: Preview init (address/label)
; - `5`: Preview step (address/label)
MACRO item_define
    STATIC_ASSERT STRLEN(\2) <= 10, "item name must be <= 10 characters"
    db \1
    db \2
    IF STRLEN(\2) < 10
        ds 10 - STRLEN(\2), " "
    ENDC
    db \3
    dw \4
    dw \5
ENDM
