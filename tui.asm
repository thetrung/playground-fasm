format ELF64 executable 3
include 'linux64a.inc'
entry start

start:
                        ; INIT
    call clear_screen
    call get_term_size  ; CONFIG ROWS x COLS
    call print_term_size
    invoke sys_sleep,1,0;secs
    call clear_screen   ; clear terminal
    call color_red      ; RED
    invoke print_string, msg.hello, len.hello
    call color_end      ; /RED
    invoke sys_sleep,1,0;secs
                        ; CONFIG
    call rendering      ; READY to RENDERV  
    jmp _exit           ; EXIT

rendering:
    call clear_screen
    mov eax, dword [pixel.light]
    call fill_buffer; fill with "#"
    call draw_buffer
    ;
    invoke set_cursor, 40, 45
    invoke print_string, msg.term_size, len.term_size
    call cursor_hide
.loop:
    EVENT_REDRAW    equ 1
    ; Event
    cmp [event.state], EVENT_REDRAW
    je rendering
    ; Wait
    call sys_sleep
    jmp .loop;
    ret

set_cursor:
  push rsi rdi
  ; save stuffs
  mov r9, 0; length
  mov [buffer], 27   ; 1-byte
  mov [buffer+1], '['; 1-byte 
  add r9, 2
  ; convert X -> String
  pop rdi
  mov rax, rdi; X
  call integer_to_string;(rax)=>(buffer,length)
  lea r10, [buffer+r9]
  memcpy rax, r10, rbx
  add r9, rbx
  ; delimits
  mov [buffer+r9], ';'
  inc r9
  ; convert Y -> String
  pop rsi
  mov rax, rsi; Y
  call integer_to_string
  lea r10, [buffer+r9]
  memcpy rax, r10, rbx
  add r9, rbx
  ; finalize
  mov [buffer+r9], 'H'
  inc r9
  invoke print_string, buffer, r9; draw->terminal
  ret

draw_buffer:
  mov rax, [frame_size]
  add rax, 1
  invoke print_string, framebuffer, rax
  ret

fill_buffer:
  mov rbx, [frame_size]
  mov rcx, 0
.loop:
  cmp rcx, rbx
  je .done
  mov edx, eax
  mov dword [framebuffer+rcx], edx
  add rcx, 4
  jmp .loop
.done:
  mov dl, 0x0
  mov byte [framebuffer+rcx+1], dl; end character.
  ret

get_term_size:           ; get [winsize]
  mov rax, SYS_IOCTL
  mov rdi, STDOUT
  mov rsi, TIOCGWINSZ
  lea rdx, [winsize]
  syscall
  cmp rax, 0
  jl .error_winsize
  ; 
  movzx rax, [winsize.row]
  movzx rbx, [winsize.col]
  imul rax, rbx
  imul rax, 4
  mov [frame_size], rax
  call print_num;=> check total buffer
  invoke print_string, msg.total_buffer, len.total_buffer
  ret
.error_winsize:
  invoke print_string, msg.error_winsize, len.error_winsize
  ret

print_term_size:
  invoke print_string, msg.term_size, len.term_size
  xor rax, rax
  
  mov ax, [winsize.row]; movzx = move with Zero-Extender
  ; shr ax, 1
  call print_num
  
  invoke print_string, msg.between, len.between

  mov ax, [winsize.col]; to avoid "garbage" data from corrupting number.
  call print_num
  
  ret

set_background:
    invoke print_string, ascii.background, len.background
    ret

clear_screen:
    invoke print_string, ascii.clear_screen,  len.clear_screen
    ret

cursor_hide:
    invoke print_string, ascii.hide_cursor,   len.hide_cursor
    ret

cursor_show:
    invoke print_string, ascii.show_cursor,   len.show_cursor
    ret

cursor_left:
    invoke print_string, ascii.cursor_left,   len.cursor_left 
    ret

cursor_pos:
    invoke print_string, ascii.cursor_pos,    len.cursor_pos
    ret

cursor_save:
    invoke print_string, ascii.cursor_save,   len.cursor_save
    ret

color_red:
    invoke print_string, ascii.red_start,     len.red_start
    ret

color_end:
    invoke print_string, ascii.red_end,       len.red_end
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
    invoke print_string, msg.error_get, len.error_get
    ret
error_set:
    invoke print_string, msg.error_get, len.error_set
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

event:
  .state        dd 0

ascii:
  text .clear_screen, 27, '[H', 27, '[2J'
  text .cursor_left,  27, "[H"
  text .cursor_save,  27, "[s"
  text .cursor_pos,   27, "[6n"
  text .red_start,    27, "[31m"
  text .red_end,      27, "[0m"
  text .background,   27, "[48;2;255;0;0m";= RED background.
  text .set_cursor,   27, "[40;45Hx"
  text .hide_cursor,  27, "[?25l"
  text .show_cursor,  27, "[?25h"

pixel:; 3-bytes UTF-8 + 1-byte padding
  text .light,        0E2h, 096h, 091h, 0x0
  text .medium,       0E2h, 096h, 092h, 0x0
  text .dark,         0E2h, 096h, 093h, 0x0
  .block  dd          '▓'
  .space  dd          ' '

msg:
  text .error_get,     0xA,"error: get ioctl",0xA,0
  text .error_set,     0xA,"error: set ioctl",0xA,0
  text .error_winsize, 0xA,"error: can't get winsize !",0xA,0

  text .hello,       0xA,"Hello, World", 0xA, 0
  text .term_size,       "rows x cols = ",0
  text .between,         " x ",0
  text .reset_check, 0xA,"reset_check c_lflag: ",0xA,0
  text .total_buffer,    " bytes allocated > buffer.",0xA,0

; TUI Buffer    = 4-bytes x ROW x COL
framebuffer     rb 4*512*512;bytes
frame_size      dq ?
