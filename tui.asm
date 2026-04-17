format ELF64 executable 3
include 'linux64a.inc'
entry start
start:
                        ; INIT
    call clear_screen
    call get_term_size  ; CONFIG ROWS x COLS
    call print_term_size
    invoke sys_sleep,2,0;secs
    call clear_screen   ; clear terminal
    call color_red      ; RED
    invoke print_string, msg.hello, len.hello
    call color_end      ; /RED
    invoke sys_sleep,1,0;secs
                        ; CONFIG
    call rendering      ; READY to RENDERV  
    jmp _exit           ; EXIT

rendering:
    ; TODO: implement RENDERING  
.loop:
    call clear_screen
    call set_background
    ; Test 'x' at [10 x 10]
    call set_cursor
    ; Wait
    call sys_sleep
    jmp .loop;
    ret

get_term_size:           ; get [winsize]
  mov rax, SYS_IOCTL
  mov rdi, STDOUT
  mov rsi, TIOCGWINSZ
  lea rdx, [winsize]
  syscall
  ret

print_term_size:
  invoke print_string, msg.term_size, len.term_size
  xor rax, rax
  movzx rax, [winsize.row]; movzx = move with Zero-Extender 
  call print_num
  invoke print_string, msg.between, len.between
  movzx rax, [winsize.col]; to avoid "garbage" data from corrupting number.
  call print_num
  ret

set_cursor:
    invoke print_string, txt.set_cursor, len.set_cursor
    ret

set_background:
    invoke print_string, txt.background, len.background
    ret

clear_screen:
    invoke print_string, txt.clear_screen,  len.clear_screen
    ret

cursor_left:
    invoke print_string, txt.cursor_left,   len.cursor_left 
    ret

cursor_pos:
    invoke print_string, txt.cursor_pos,    len.cursor_pos
    ret

cursor_save:
    invoke print_string, txt.cursor_save,   len.cursor_save
    ret

color_red:
    invoke print_string, txt.red_start,     len.red_start
    ret

color_end:
    invoke print_string, txt.red_end,       len.red_end
    ret


termios_get:
    lea rdx, [term.origin]
    m_syscall SYS_IOCTL, STDIN, TCGETS
    cmp rax, 0
    jl error_get
    ret

termios_restore:
    lea rdx, [term.origin]; reload config ~> [term.origin]
    m_syscall SYS_IOCTL, STDIN, TCSETS
    cmp rax, 0; error check:
    jl error_set
    ret

termios_config:
    ; get termios :
    call termios_get

    ; disable ICANON | ECHO (raw mode)
    memcpy term.origin, term.raw, 60; bytes
    lea rdi, [term.raw]
    mov rax, [rdi+12]; offset(c_lflag) = 12 in termios.
    ; mov [c_lflag], rax
    add rax, not (0x0002 or 0x0008); ~(ICANON | ECHO)
    mov [rdi+12], rax; c_lflag = rax

    ; ioctl(STDIN, TCSETS, &termios_raw)
    lea rdx, [term.raw]
    m_syscall SYS_IOCTL, STDIN, TCSETS
    cmp rax, 0
    jl error_set
    ret 

error_get:
    invoke print_string, msg.error_get
    ret
error_set:
    invoke print_string, msg.error_get
    ret

;; SYS_READ:
sys_readline:
    mov rax, SYS_READ;= 0
    mov rdi, STDIN;=0
    mov rsi, buffer
    mov rdx, 16; bytes
    syscall
    ret
;; SYS_EXIT
_exit:
    call sys_exit

segment readable writable
buffer          rb 12; bytes = 3 delimits + 1234:1234
term:
  .rows         dq 0
  .cols         dq 0
  .origin       rb 44
  .raw          rb 44
winsize:
  .row          dw ?; ROWS (height)
  .col          dw ?; COLS (width)
  .width        dw ?; Unused (pixel width)
  .height       dw ?; Unused (pixel height)

txt:
  text .clear_screen, 27, '[H', 27, '[2J'
  text .cursor_left,  27, "[H"
  text .cursor_save,  27, "[s"
  text .cursor_pos,   27, "[6n"
  text .red_start,    27, "[31m"
  text .red_end,      27, "[0m"
  text .background,   27, "[48;2;255;0;0m"
  text .set_cursor,   27, "[10;10H x"
msg:
  .error_get    db "error: get ioctl",0xA,0
  .error_set    db "error: set ioctl",0xA,0

  text .hello,       0xA,"Hello, World", 0xA, 0
  text .term_size,   0xA," [rows x cols] = ",0
  text .between,         " x "
  text .reset_check, 0xA,"reset_check c_lflag: ",0xA,0
