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
  ;; 8. sendmsg (wl_display.get_registry)
   mov rax, SYS_SENDMSG
   mov rdi, [sock]  ;sockfd
   lea rsi, [msghdr];msghdr
   xor rdx, rdx     ;flags = 0
   syscall
   cmp rax, 0
   jl .error_get_registry
   mov rax, SYS_RECVMSG
   mov rdi, [sock]
   lea rsi, [msghdr_recv]
   xor rdx, rdx; flags = 0
   syscall
   cmp rax, 0
   jl .error_get_registry
   call print_num
   invoke print_string, msg.get_registry_done, len_get_registry_done
  ;; 9. wl_buffer
  

  ;; 10. wl_surface

  ;; WAIT
  invoke sys_sleep,1,0
  jmp exit

  .error_memfd:
  invoke print_string, msg.error_memfd, len_error_memfd
  jmp exit

  .error_socket:
  invoke print_string, msg.error_socket, len_error_socket
  jmp exit

.error_connect:
  invoke print_string, msg.error_connect, len_error_connect
  jmp exit

.error_ftruncate:
  invoke print_string, msg.error_ftruncate, len_error_ftruncate
  jmp exit

.error_mmap:
  invoke print_string, msg.error_mmap, len_error_mmap
  jmp exit

.error_get_registry: 
  invoke print_string, msg.error_get_registry, len_error_get_registry
  jmp exit

exit:
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

wl_registry:
.object_id    dd 1; wl_display
.opcode       dw 1; get_registry
.args         dd 2; registry_id
len_wl_registry = $ - wl_registry

iov:
.msg_text     dq wl_registry
.msg_len      dq len_wl_registry
len_iov       = $ - iov

msghdr:
.msg_name       dq 0
.msg_namelen    dd 0
.msg_iov        dq iov
.msg_iovlen     dq len_iov
.msg_control    dq 0
.msg_controllen dq 0
.msg_flags      dd 0
.padding        dd 0

;; SYS_RECVMSG
wl_buffer       rb 1024
iov_recv:
.msg_text       dq wl_buffer
.msg_len        dq 1024
len_iov_recv    = $ - iov_recv

msghdr_recv:
.msg_name       dq 0
.msg_namelen    dd 0
.msg_iov        dq iov_recv
.msg_iovlen     dq len_iov_recv
.msg_control    dq 0
.msg_controllen dq 0
.msg_flags      dd 0
.padding        dd 0

shm_pool:
.object_id     dw ?
.opcode        dw 0
.pool_id       dd ?
.fd            dd ?
.size          dd ?
len_shm_pool = $ - shm_pool

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

.error_get_registry db 0xA, " >> error: get_registry",0
len_error_get_registry = $ - .error_get_registry

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

.get_registry_done db 0xA,"sent get_registry request.",0
len_get_registry_done = $ - .get_registry_done
