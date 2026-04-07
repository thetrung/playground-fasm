format ELF64 executable 3
include 'linux64a.inc'
entry start
start:
    call termios_config ; disable ECHO + ICANON
                        ;
    call clear_screen   ; clear terminal
    call cursor_left    ; set cursor-> left
    call color_red      ; Test color set = RED
    invoke print_string, txt.hello, 13
    call color_end      ; Done color test.
    
    call get_term_size  ; READY to RENDER 
    call rendering
    
    ; call sys_sleep      ; 1s
    call termios_restore; restore TERMIO config to avoid freezed.
    jmp _exit           ; EXIT

rendering:
    ;
    ; TODO: implement RENDERING  
    ;
    ret

get_term_size:           ; get [rows x cols]
    call cursor_save     ; save current cursor.
    call cursor_far      ; scroll to bottom(9999:9999)
    call cursor_pos      ; get current cursor position.
    call read_cursor_pos ; read response > parse > [term.rows/cols]
    call print_term_size ; demo how to concat temp.strings together.
    ret 

clear_screen:
    invoke print_string, txt.clear_screen,4
    ret

cursor_left:
    invoke print_string, txt.cursor_left, 3
    ret

cursor_far:
    invoke print_string, txt.cursor_far, 12
    ret

cursor_pos:
    invoke print_string, txt.cursor_pos, 4
    ret

cursor_save:
    invoke print_string, txt.cursor_save, 3
    ret

color_red:
    invoke print_string, txt.red_start,   5
    ret

color_end:
    invoke print_string, txt.red_end,     4
    ret

read_cursor_pos:
    call sys_readline;
    call parse_cursor_pos     ;=> [term.rows/cols]
    ret

print_term_size:
    invoke print_string, msg.term_size, len_term_size
    xor r8, r8                ; clear buffer length counter
                              ; Now we convert rows -> string
    mov rax, [term.rows]      ; rax = rows
    call integer_to_string    ; rax = buffer | rbx = length
    memcpy rax, buffer, rbx   ; copy len1-byte from [rax] -> (buffer)
    mov r8, rbx               ; counter += str1_len

    mov r9, buffer
    add r9, len_between
    memcpy msg.between, r9, len_between
    add r8, len_between
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

termios_restore:
    lea rdx, [term.origin]; reload config ~> [term.origin]
    m_syscall SYS_IOCTL, STDIN, TCSETS
    cmp rax, 0; error check:
    jl error_set
    ret

termios_config:
    ; get termios :
    lea rdx, [term.origin]
    m_syscall SYS_IOCTL, STDIN, TCGETS
    cmp rax, 0
    jl error_get

    ; disable ICANON | ECHO (raw mode)
    memcpy term.origin, term.raw, 60; bytes
    lea rdi, [term.raw]
    mov rax, [rdi+12]; offset(c_lflag) = 12 in termios.
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
    call sys_exit

segment readable writable
buffer          rb 12; bytes = 3 delimits + 1234:1234
term:
  .rows         dq 0
  .cols         dq 0
  .origin       rb 44
  .raw          rb 44
txt:
  .hello        db "Hello, World", 0xA, 0
  .clear_screen db 27, "[2J"
  .cursor_left  db 27, "[H"
  .cursor_save  db 27, "[s"
  .cursor_far   db 27, "[9999;9999H"
  .cursor_pos   db 27, "[6n"
  .red_start    db 27, "[31m"
  .red_end      db 27, "[0m"
msg:
  .error_get    db "error: get ioctl",0xA,0
  .error_set    db "error: set ioctl",0xA,0
  .term_size    db " [rows x cols] = ",0x0
  len_term_size = $ - .term_size
  .between      db " x "
  len_between   = $ - .between
req: 
.tv_sec  dq 1; 64-bit
.tv_nsec dq 0 ; 64-bit
