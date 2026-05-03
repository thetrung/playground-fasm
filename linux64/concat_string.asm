format ELF64 executable
segment readable executable
entry _start
include 'linux64a.inc'
_start:
	;Copy address:
	mov edi, buffer
	mov esi, msg.hello
  mov edx, msg.world
  call concat_string
  call print_string

exit:
	mov rax, SYS_EXIT	; sys_exit = 60
	xor rdi, rdi		; return 0
	syscall

segment readable writeable
buffer: rb 256
msg: 
.hello db "Hello", 0
.world db " World!", 0
