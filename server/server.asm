;; arguments order :
;; x86-64 : rdi rsi rdx r10 r8 r9
;;

format ELF64
public _start
; 
;===========================
; CONSTANTS ::
; parsed from constant.c :
;===========================
socket = 41
bind = 49
listen = 50
accept = 43
read = 0
write = 1
open = 2
close = 3
exit = 60
shutdown = 48
shut_rd = 0 
af_inet = 2
sock_stream = 1
o_rdonly = 0
;===========================

section '.text' executable
_start:
;================================================
; HOW THIS WORK :
;
; Start Server :
; socket () -> bind () -> listen () 
;
; Access [localhost:8080] :
; accept () -> read (accepted_fd) 
; -> [backup client_fd > r13] 
;
; Open 'index.html' & read its content :
; -> open ('index.html') 
; -> read (opened_fd)
; Write content back to client_fd in r13 :
; -> write (r13) -> close (r13)
;================================================
;
; int socket(int domain, int type, int protocol);
;
mov rdi, af_inet      ; com-domain : IPv4 protocol
mov rsi, sock_stream  ; socket-type : SOCK_STREAM
                      ; provide sequenced, 2-way connection
                      ; based byte streams.
mov rdx, 0            ; protocol : 0 = default.
mov rax, socket
; long syscall(long number, ...);
syscall

                      ; Function preserve registers :
                      ; rbx, rsp, rbp, r12,r13,r14,r15
                      ;
                      ; So here we use r12 :
; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
mov r12, rax          ; sockfd   > r12
mov rdi, r12          ; sockfd   > rdi
mov rsi, address      ; sockaddr > rsi
mov rdx, 16           ; addrlen  > rdx
mov rax, bind     ; bind     > rax
syscall

_listen:
; int listen(int sockfd, int backlog);
mov rdi, r12          ; sockfd  > rdi
mov rsi, 10           ; backlog > rsi
mov rax, listen   ; listen  > rax
syscall

accept_loop:
; int accept(int sockfd, struct sockaddr *_Nullable restrict addr, socklen_t *_Nullable restrict addrlen);
mov rdi, r12          ; sockfd   > rdi
mov rsi, 0            ; sockaddr > rsi
mov rdx, 0            ; restrict > rdx
mov rax, accept       ; SYS_accept
syscall

mov r13, rax          ; backup client fd -> r13

; int open(const char *pathname, int flags );
mov rdi, path         ; path 
mov rsi, o_rdonly     ; flags
mov rax, open
syscall

mov r14, rax          ; backup index_fd

; ssize_t read(int fd, void buf[.count], size_t count);
mov rdi, rax          ; file-description from open():
mov rsi, buffer; buffer 
mov rdx, 256          ; count  
mov rax, read         ; SYS_read
syscall

mov r15, rax          ; save content length

; ssize_t write(int fd, const void buf[.count], size_t count);
mov rdi, r13      ; fd from bind():
mov rsi, buffer   ; buffer
mov rdx, r15      ; count = read content length
mov rax, write    ; write() 
syscall

; int close(int fd);
mov rdi, r13       ; client_fd
mov rax, close     ; SYS_close
syscall

; int close(int fd);
mov rdi, r14       ; index_fd
mov rax, close     ; SYS_close
syscall

jmp accept_loop    ; back to _accept

;
; To avoid SIGSEGV, we need to :
; void exit(int status);
_exit: 
mov rdi, 0         ; status = 0
mov rax, exit      ; SYS_exit
syscall

section '.data' writeable
;| bytes | type |
;| 2     | dw   |
;| 4     | dd   |
;| 8     | dq   |
address:        ; struct sockaddr_in :
dw af_inet      ; family: AF_INET
dw 0x901f       ; port  : hex(8080) = '0x1f90'
dd 0            ; struct in_addr : 4 bytes
dq 0            ; padding :        8 bytes

buffer: db 256 dup 0

path: db 'index.html', 0
