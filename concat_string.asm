format ELF64 executable
stdout EQU 1
sys_write EQU 1
sys_exit EQU 60
segment readable executable
entry _start
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
	jnz print_string

	;Copy new_text -> buffer :
	mov esi, new_text
	mov r12, 1			; indicate append
	jmp copy_loop

print_string:
	mov rax, sys_write	; sys_write = 1
	mov rdi, stdout   	; file description = 1 
	mov rsi, buffer 	; 256 bytes buffer
	mov rdx, 13			; total text length
	syscall

exit:
	mov rax, sys_exit	; sys_exit = 60
	xor rdi, rdi		; return 0
	syscall

segment readable writeable
buffer: rb 256
msg: db "Hello", 0
new_text: db " World!", 0
