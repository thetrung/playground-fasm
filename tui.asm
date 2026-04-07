format ELF64 executable 3
include 'linux64a.inc'
entry start
start:
    call clear_screen
    call cursor_left
    call color_red
    invoke print_string, txt.hello,       13
    call color_end

    call sys_exit
    jmp _exit

clear_screen:
    invoke print_string, txt.clear_screen,4
    ret

cursor_left:
    invoke print_string, txt.cursor_left, 3
    ret

color_red:
    invoke print_string, txt.red_start,   5
    ret

color_end:
    invoke print_string, txt.red_end,     4
    ret

;; SYS_SLEEP:
sys_sleep:
    mov rax, SYS_SLEEP
    lea rdi, [req]    ; arg0 <- req timespec
    syscall
    ret
;; SYS_EXIT
sys_exit:
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
    ret
_exit:

segment readable writable
txt:
  .hello        db "Hello, World", 0xA, 0
  .clear_screen db 27, "[2J"
  .cursor_left  db 27, "[H"
  .red_start    db 27, "[31m"
  .red_end      db 27, "[0m"
; 0xA is Unix-style newline.
; 0xD, 0xA is Window-style newline.
req: 
.tv_sec  dq 1; 64-bit
.tv_nsec dq 0 ; 64-bit
