format ELF64
section '.text' executable
public _start
extrn printf
include "linux64a.inc"
; test: 
_start:
invoke printf, fmt, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
; exit
mov eax, 60
xor edi, edi
syscall

section '.data' writable
fmt: db "printf(fmt, %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d)",0xA,0
