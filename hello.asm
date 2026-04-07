format ELF64 executable 3
include 'linux64a.inc'
entry start
start:
;; SYS_WRITE:
    mov rax, SYS_STDOUT
    mov rdi, SYS_WRITE
    mov rsi, hello
    mov rdx, 13
    syscall
;; SYS_SLEEP:
    mov rax, SYS_SLEEP
    lea rdi, [req]    ; arg0 <- req timespec
    syscall
;; SYS_EXIT
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
segment readable writable
hello: db "Hello, World", 0xA, 0 
; 0xA is Unix-style newline.
; 0xD, 0xA is Window-style newline.
req: 
.tv_sec  dq 10; 64-bit
.tv_nsec dq 0 ; 64-bit
