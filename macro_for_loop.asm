
; ==========================================
; for_loop.inc
; Reusable FASM macro for "for loop"
;
; Usage: for_loop reg, start, end, body
; %$ - to make unique label names
;
; Example:
;   for_loop eax, 0, 4, {
;       ; loop body here
;   }
; ==========================================

macro for_loop var, start, end, body {
mov var, start
.for_loop_start_%$:
cmp var, end
jg .for_loop_end_%$
body
inc var
jmp .for_loop_start_%$
.for_loop_end_%$:
}
