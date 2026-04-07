format ELF64 executable
segment readable executable
entry _start
include 'linux64a.inc'
_start:
	;Copy msg -> buffer :
	mov esi, msg
	mov edi, buffer

copy_loop:
	; copy esi -> edi
	lodsb
	stosb
	test al, al
	jnz copy_loop

	; if appending text:
	test r12,r12
	jnz print_str

	;Copy new_text -> buffer :
	mov esi, new_text
	mov r12, 1			; indicate append
	jmp copy_loop

print_str:
	mov rax, SYS_WRITE	; sys_write = 1
	mov rdi, STDOUT ; file description = 1 
	mov rsi, buffer 	  ; 256 bytes buffer
	mov rdx, 13			    ; total text length
	syscall

  sleep secs

exit:
	mov rax, SYS_EXIT	; sys_exit = 60
	xor rdi, rdi		; return 0
	syscall

segment readable writeable
secs: dq 10,0 ; timespecs 64-bit
buffer: rb 256
msg: db "Hello", 0
new_text: db " World!", 0
