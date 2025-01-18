format ELF64 executable 3
SYS_EXIT equ 60
SYS_WRITE equ 1
STDOUT equ 1

segment readable executable
entry start
start:
    mov rax, STDOUT
    mov rdi, SYS_WRITE
    mov rsi, hello
    mov rdx, 13
    syscall

    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
segment readable writable
hello: db "Hello, World", 10