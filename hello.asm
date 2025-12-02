format ELF64 executable 3
SYS_EXIT equ 60
SYS_WRITE equ 1
SYS_SLEEP equ 35
STDOUT equ 1

segment readable executable
entry start
start:
;; SYS_WRITE
    mov rax, STDOUT
    mov rdi, SYS_WRITE
    mov rsi, hello
    mov rdx, 13
    syscall
;; SYS_SLEEP
    mov rax, SYS_SLEEP
    lea rdi, [req]; arg0 <- req timespec
    xor rsi, rsi      ; arg1 (rem) = NULL
    syscall
;; SYS_EXIT
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
segment readable writable
hello: db "Hello, World", 0xA, 0 
; 0xA is Unix-style newline.
; 0xD, 0xA is Window-style newline.
req: dq 2,0
; tv_sec   (64-bit)
; tv_nsec  (64-bit)
