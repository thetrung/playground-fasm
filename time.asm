format ELF64
public _start

extrn time
extrn sleep
extrn printf

section '.data' writeable
sprint db "The elapsed time is %d seconds", 0xA, 0x0
time_begin dq ?

section '.text' executable
_start:
    ; Get init time
    xor rdi, rdi            ; erase rdi 
    call time               ; time () -> rax
    mov [time_begin], rax   ; save rax[time] -> [time_begin]

    ; Sleep for 2 secs
    mov rdi, 2
    call sleep              ; sleep (2)

    ; Get the finish time
    xor rdi, rdi
    call time

    ; Calculate the difference
    sub rax, [time_begin]   ; rax = [time_begin] - rax

    ; Print the difference
    mov rdi, sprint         ; string
    mov rsi, rax            ; args
    xor eax, eax            ; 0
    call printf             ; printf (..)

    ; Exit 
    mov rdi, 0 ; error_code
    mov rax, 60; syscall_exit
    syscall