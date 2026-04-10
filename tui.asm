format ELF64 executable 3
include 'linux64a.inc'
entry start
start:
                        ; INIT
    call clear_screen   ; clear terminal
    call cursor_left    ; set cursor-> left
    call color_red      ; RED
    invoke print_string, msg.hello, len.hello
    call color_end      ; /RED
    invoke sys_sleep,1,0;1s 
                        ; CONFIG
    call get_term_size  ; CONFIG ROWS x COLS
    call rendering      ; READY to RENDERV  
    jmp _exit           ; EXIT

rendering:
    ; TODO: implement RENDERING  
.loop:
    call clear_screen
    call cursor_left

    call color_red      ; RED
    invoke print_string, msg.hello, len.hello
    call color_end      ; /RED
    
    call sys_sleep
    jmp .loop;
    ret

get_term_size:           ; get [rows x cols]
    call termios_config ; disable ECHO + ICANON
    call cursor_save     ; save current cursor.
    call cursor_far      ; scroll to bottom(9999:9999)
    call cursor_pos      ; get current cursor position.
    call read_cursor_pos ; read response > parse > [term.rows/cols]
    call print_term_size ; demo how to concat temp.strings together.
    call termios_restore ; restore TERMIO config to avoid freezed.
    ret 

clear_screen:
    invoke print_string, txt.clear_screen,  len.clear_screen
    ret

cursor_left:
    invoke print_string, txt.cursor_left,   len.cursor_left 
    ret

cursor_far:
    invoke print_string, txt.cursor_far,    len.cursor_far 
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

read_cursor_pos:
    call sys_readline;
    call parse_cursor_pos     ;=> [term.rows/cols]
    ret

print_term_size:
    invoke print_string, msg.term_size, len.term_size
    xor r8, r8                ; clear buffer length counter
                              ; Now we convert rows -> string
    mov rax, [term.rows]      ; rax = rows
    call integer_to_string    ; rax = buffer | rbx = length
    memcpy rax, buffer, rbx   ; copy len1-byte from [rax] -> (buffer)
    mov r8, rbx               ; counter += str1_len

    mov r9, buffer
    add r9, len.between
    memcpy msg.between, r9, len.between
    add r8, len.between
    ; Although we could even do :
    ; lea rdi, [buffer]
    ; mov al, 'x'
    ; stosb
    ; => x85 if 85 was 1st here.

    mov rax, [term.cols]      ; rax = cols
    call integer_to_string    ;
    mov r9, buffer            ; buffer
    add r9, r8                ; = buffer + str2_length 
    memcpy rax, r9, r8        ; copy len2-byte from str2 -> buffer[len1]

    add r8,  rbx              ; total bytes
    ; lea rdi, [buffer+r8+1]
    ; mov al, 0x0               ; terminate \0
    ; stosb
    ; inc r8

    invoke print_string, buffer, r8
    ret

parse_cursor_pos:
    mov rsi, buffer
    add rsi, 2      ; skip(27,'[')
    xor rbx, rbx    ; rows
    xor rdx, rdx    ; cols
.parse_rows:
    mov al, [rsi]
    cmp al, ';'
    je .done_rows
    sub al, '0'
    imul rbx, rbx, 10
    add rbx, rax
    inc rsi; index++
    jmp .parse_rows
.done_rows:
    inc rsi         ; skip ';'
.parse_cols:
    mov al, [rsi]
    cmp al, 'R'
    je .done_parse
    sub al, '0'
    imul rdx, rdx, 10
    add rdx, rax
    inc rsi
    jmp .parse_cols
.done_parse:
    ; rbx = row; rdx = cols
    mov [term.rows], rbx
    mov [term.cols], rdx
    xor rax, rax
    xor rbx, rbx
    xor rdx, rdx
    ret; cleanup.

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
    ; ; check again :
    ; call termios_get
    ; lea rdx, [term.origin]
    ; mov rax, [rdx+12]
    ; mov [c_lflag_after], rax
    ;
    ; call clear_screen
    ;
    ; invoke print_st:wring, msg.reset_check, len_reset_check
    ; mov rax, [c_lflag_after]
    ; call print_num
    ;
    ; invoke print_string, msg.between, len_between
    ; mov rax, [c_lflag]
    ; call print_num
    ;
    ; invoke print_string, msg.between, len_between 
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
; c_lflag         dq ?
; c_lflag_after   dq ?
buffer          rb 12; bytes = 3 delimits + 1234:1234
term:
  .rows         dq 0
  .cols         dq 0
  .origin       rb 44
  .raw          rb 44
txt:
  text .clear_screen, 27, "[2J"
  text .cursor_left,  27, "[H"
  text .cursor_save,  27, "[s"
  text .cursor_far,   27, "[9999;9999H"
  text .cursor_pos,   27, "[6n"
  text .red_start,    27, "[31m"
  text .red_end,      27, "[0m"
msg:
  .error_get    db "error: get ioctl",0xA,0
  .error_set    db "error: set ioctl",0xA,0

  text .hello,       0xA,"Hello, World", 0xA, 0
  text .term_size,   0xA," [rows x cols] = ",0
  text .between,         " x "
  text .reset_check, 0xA,"reset_check c_lflag: ",0xA,0
