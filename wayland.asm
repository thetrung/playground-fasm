format ELF64 executable 3
include 'linux64a.inc'
BUFFER_SIZE   equ 2560 * 1440 * 4

entry _start
_start:
  ;; 1.SOCKET 
  mov rax, SYS_SOCKET
  mov rdi, AF_UNIX
  mov rsi, SOCK_STREAM
  mov rdx, 0;sockaddr_len
  syscall   ;=> RAX
  cmp rax, 0
  jl .error_socket
  mov [sock], rax
  invoke print_string, msg.created_socket, len_created_socket
  mov rax, [sock]
  invoke print_num
  ;; 2. ADDR 
  mov [sockaddr.family], AF_UNIX
  lea rsi, [wayland_path]
  lea rdi, [sockaddr.path]
  memcpy rsi, rdi, len_wayland_path
  invoke print_string, msg.created_sockaddr, len_created_sockaddr
  ; Test values of [sockaddr]
  mov ax, [sockaddr.family]
  call print_num
  invoke print_string, sockaddr.path, 108;len_wayland_path
  ;; 3.CONNECT
  mov rax, SYS_CONNECT      ;sys_connect
  mov rdi, [sock]           ;sock_fd
  lea rsi, [sockaddr]       ;sockaddr
  mov rdx, len_sockaddr     ;size
  syscall
  cmp rax, 0
  jl .error_connect
  invoke print_string, msg.connected, len_connected
  ;; 4.MEMFD_CREATE
  ;m_syscall SYS_MEMFD_CREATE, fd_name, MFD_ALLOW_SEALING;=> return RAX
  mov rax, SYS_MEMFD_CREATE
  mov rdi, fd_name
  mov rsi, 0;MFD_ALLOW_SEALING
  syscall
  cmp rax, 0
  jl .error_memfd
  mov [memfd], rax
  invoke print_string, msg.created_memfd, len_created_fd 
  ;; 5. resize 
  mov rax, SYS_FTRUNCATE;
  mov rdi, [memfd]
  mov rsi, BUFFER_SIZE; width * stride * height
  syscall
  cmp rax, 0
  jl .error_ftruncate
  invoke print_string, msg.ftruncated, len_ftruncated
  ;; 6. mmap
  mov rax, SYS_MMAP
  mov rdi, ADDR_NULL
  mov rsi, BUFFER_SIZE
  mov rdx, (PROT_READ or PROT_WRITE)
  mov r10, MAP_SHARED
  mov r8,  [memfd]
  mov r9,  OFFSET_EMPTY 
  syscall
  cmp rax, 0; << FRAMEBUFFER ADDRESS
  jl .error_mmap
  mov [framebuffer], rax
  invoke print_string, msg.mmap_done, len_mmap_done
  ;; 7. write pixels
  mov rax, [framebuffer]
  xor rbx, rbx
  .render_loop:
    mov dword [rax], 0xFF00FF00; ARGB (green)
    add rax, 4; bytes - one byte for each channel. 
    add rbx, 4
    cmp rbx, BUFFER_SIZE
    je  .render_done
    jmp .render_loop
  .render_done:
    invoke print_string, msg.render_done, len_render_done

  ;; WAIT
  invoke sys_sleep,5,0
  jmp _exit

  .error_memfd:
  invoke print_string, msg.error_memfd, len_error_memfd
  jmp _exit

  .error_socket:
  invoke print_string, msg.error_socket, len_error_socket
  jmp _exit

.error_connect:
  invoke print_string, msg.error_connect, len_error_connect
  jmp _exit

.error_ftruncate:
  invoke print_string, msg.error_ftruncate, len_error_ftruncate
  jmp _exit

.error_mmap:
  invoke print_string, msg.error_mmap, len_error_mmap
  jmp _exit

  _exit:
  call sys_exit

segment readable writable
sock              dq ?
fd_name           db 'wl_buffer'
memfd             dq ?
wayland_path      db "/run/user/1000/wayland-1",0x0
len_wayland_path  = $ - wayland_path
framebuffer       dq ?

sockaddr:
.family dw ?;sa_family_t = AF_UNIX but 2-bytes
.path   rb 108;;char [108]
len_sockaddr = $ - sockaddr
msg:
.error_memfd      db 0xA,"error: to create fd.",0
len_error_memfd      = $ - .error_memfd

.error_socket     db 0xA,"error: can't create socket.",0
len_error_socket     = $ - .error_socket

.error_connect    db 0xA," >> error: connect ?",0
len_error_connect    = $ - .error_connect

.error_ftruncate  db 0xA," >> error: ftruncate ",0
len_error_ftruncate  = $ - .error_ftruncate

.error_mmap       db 0xA," >> error: mmap",0
len_error_mmap       = $ - .error_mmap  

.created_socket   db 0xA,"created_socket = ",0
len_created_socket   = $ - .created_socket

.created_sockaddr db 0xA,"sockaddr = ",0
len_created_sockaddr = $ - .created_sockaddr

.created_memfd    db 0xA,"created_memfd.",0
len_created_fd        = $ - .created_memfd

.connected        db 0xA,"connected.",0xA,0
len_connected         = $ - .connected

.ftruncated       db 0xA,"ftruncated.",0
len_ftruncated        = $ - .ftruncated

.mmap_done        db 0xA,"mmaped.",0
len_mmap_done         = $ - .mmap_done

.render_done      db 0xA,"writing > framebuffer: done.",0
len_render_done       = $ - .render_done
