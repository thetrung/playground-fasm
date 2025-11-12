
; fb_simple.asm — pure FASM Linux example (framebuffer)
format ELF64 executable
entry start

segment readable writeable
    fbname db '/dev/fb0',0
    fbfd   dq 0
    fb_ptr dq 0
    len    dq 1024*768*4       ; assume 1024x768x32bpp

segment executable
start:
    ; open /dev/fb0
    mov rax,2                  ; sys_open
    lea rdi,[fbname]
    mov rsi,2                  ; O_RDWR
    syscall
    mov [fbfd],rax

    ; mmap framebuffer
    mov rdi,0
    mov rsi,[len]
    mov rdx,3                  ; PROT_READ|PROT_WRITE
    mov r10,1                  ; MAP_SHARED
    mov r8,[fbfd]
    mov r9,0
    mov rax,9                  ; sys_mmap
    syscall
    mov [fb_ptr],rax

    ; draw gradient
    mov rcx,1024*768
    mov rdi,[fb_ptr]
.loop:
    mov eax,ecx
    shl eax,8
    or  eax,0x00FF00           ; greenish
    stosd
    loop .loop

    ; sleep a few seconds
    mov rax,35
    lea rdi,[timespec]
    xor rsi,rsi
    syscall

    ; exit
    mov rax,60
    xor rdi,rdi
    syscall

segment readable writeable
timespec dq 2,0
