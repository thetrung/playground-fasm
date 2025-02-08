format ELF64 executable
segment readable executable
sys_exit EQU 60
sys_write EQU 1
stdout EQU 1
macro printf msg, msg_length
{
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, msg
    mov rdx, msg_length
    syscall
}
entry main
main:
    mov rdi, 93     ; N = 93 => 12200160415121876738
    mov rsi, 0      ; A = 0
    mov rdx, 1      ; B = 1
    mov eax, 0      ; loop_count = 0

    ; Backup:
    push rdi
    push rsi
    push rdx
    
    ; print :
    push rdi    ; copy N -> rcx
    printf msg_n, 4 ; N = 

    pop rax    ; print N :
    call print_num
    
    ; Restore:
    pop rdx
    pop rsi
    pop rdi

next_fib:
    ; call print_nab
    inc eax         ; loop_count++

    cmp rdi, 0      ; n == 0 ?
    je return_a     ; return A

    cmp rdi, 1      ; n == 1 ?
    je return_b     ; return B

    dec rdi         ; N = N - 1
    mov rcx, rsi    ; rcx = old_A
    mov rsi, rdx    ; new_A = old_B
    add rdx, rcx    ; new_B = old_A + old_B
    
    jmp next_fib

return_a:
    ; result already in rsi
    jmp exit

return_b:
    mov rsi, rdx    ; Return B >> rax
    jmp exit
    
exit:
    ; copy result rsi -> rax
    mov rax, rsi
    ; save stack ;)
    push rax
    ; Exit with Result :
    printf msg_exit, 4
    ; Restore!
    pop rax
    call print_num
    call newline

    mov rax, sys_exit
    xor rdi, rdi
    syscall

print_num: ;(rax)
    ; save stack of current values :
    push rdi
    push rdx
    push rsi
    ;
    ; start converting (rax): 
    ;
    ; Set pointer -> end of buffer :
    mov rdi, buffer+19
    mov byte [rdi], 10
    dec rdi

print_digit:
    xor rdx, rdx    ; clear rdx for division reminder.
    mov rcx, 10     ; divisor = 10
    div rcx         ; rax / 10 => rax = quotient | rdx = reminder
    add dl, '0'     ; convert reminder => ASCII
    dec rdi         ; move back one position.
    mov [rdi], dl   ; store digit character.
    test rax, rax   ; if quotient = zero, we are done.
    jnz print_digit

    ; compute length of string to print :
    mov rdx, buffer+20
    sub rdx, rdi
    mov rsi, rdi    ; length
    
    ; Write number > stdout :
    mov rax, sys_write
    mov rdi, stdout
    syscall

    ; Restore values to registers :
    pop rsi
    pop rdx
    pop rdi
    ; clear rax value
    xor rax,rax 
    ret

newline:
    printf newline_str, 1
    ret

print_nab:          ; Print N-A-B :
    mov rax, rdi    ; N
    call print_num
    mov rax, rsi    ; A
    call print_num
    mov rax, rdx    ; B
    call print_num
    ; call newline    ; Next!
    ret             ; Done.

segment readable writable
buffer rb 20
newline_str db 10
msg_n: db "N = ", 0
msg_exit: db "F = ", 0
