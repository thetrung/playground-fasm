format ELF64
include 'macros.asm'
section '.data' writable
SYS_MMAP equ 0x09
SYS_QUIT equ 60
PROT_RWRITE equ 0x03
MAP_PRIVATE equ 0x22
MAP_ANONYMOUS equ 0x20
OFFSET_EMPTY equ 0x00
ADDR_NULL equ 0x00
PAGE_SIZE equ 4096; bytes
NO_FILE equ -1
msg_fmt: db "allocated %d bytes @ address: %p",0xA,0x0

section '.text' executable
public _start
extrn printf
_start:

_mmap:;(NULL, 4096, PROT_READ|WRITE, MAP_PRIVATE|ANON, -1, 0)
  m_syscall SYS_MMAP,\
            ADDR_NULL, PAGE_SIZE, PROT_RWRITE,\
            MAP_PRIVATE, NO_FILE, OFFSET_EMPTY
; rax <- allocated memory address.

_printf:;("..",    PAGE_SIZE, Addr)
  m_fn printf, msg_fmt, PAGE_SIZE, rax

 _exit:
  m_syscall SYS_QUIT
