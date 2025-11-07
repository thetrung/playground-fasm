format ELF64
public _start

extrn free
extrn malloc
extrn printf

section '.data' writeable
fail_msg db "Failed to allocate memory.", 0xA, 0x0
int_msg db "value: %d", 0xA, 0
eax_msg db "eax: %d", 0xA, 0
mem dd ?        ; no init 

section '.text' executable
_start:
    mov rdi, 2             ; Allocate 2 bytes
    call malloc 
    or eax, eax             ; test for error
    jz _malloc_fail         ; failed to allocate
    mov [mem], eax          ; save address > [mem]
    jmp _malloc_success

    _malloc_fail:
        mov rdi, fail_msg
        call printf         ; indicate failure.
        jmp _exit

    _malloc_success:        ; Write something > [mem]
        mov eax, [mem]
        mov ebx, 10         ; mem [0] = 10
        mov [eax], ebx       
        mov ebx, 5          ; mem [1] = 5
        mov [eax+4], ebx      
    
        mov eax, [mem]      ; Print 1st value :
        mov rdi, int_msg
        mov esi, [eax]
        call printf 
 
        mov rdi, eax_msg    ; See what's in [eax]
        call printf         ; Some random numbers => 12823192

        mov eax, [mem]      ; Print 2nd value :
        mov rdi, int_msg
        mov esi, [eax+4]
        call printf

        mov edi, [mem]      ; Free Memory
        call free

    _exit:
        mov rdi, 0          ; error_code
        mov rax, 60         ; syscall_exit
        syscall