format ELF64
section '.text' executable
public _start
extrn printf

_start:
  mov edi, fmt                 ; string format 
  cvtss2sd xmm0, [simd_data]   ; 1st element
  cvtss2sd xmm1, [simd_data+4] ; 1st element
  call printf
;; exit 
  mov eax, 60
  syscall

section '.data' writable  
fmt: db "value:",0xA,\ 
        "x=%.2f",0xA,\ 
        "y=%.2f",0xA,0   ; 0xA - Unix newline
align 8
simd_data: 
dd 100.00
dd 50.00

