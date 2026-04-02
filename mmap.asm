format ELF64 executable
include 'linux64a.inc'
segment readable writable
msg_fmt db "allocated 4096 bytes @ address: ",0
msg_len = ($ - msg_fmt); tricky: not "equ", not "db" but "="
secs dq 10,0
segment readable executable
entry main
main:
_mmap:;(NULL, 4096, PROT_READ|WRITE, MAP_PRIVATE|ANON, -1, 0)
  m_syscall SYS_MMAP,\
            ADDR_NULL, PAGE_SIZE, PROT_RWRITE,\
            MAP_PRIVATE, NO_FILE, OFFSET_EMPTY
; rax <- allocated memory address.
  push rax; <- save addr
  
  invoke print_string, msg_fmt, msg_len
  
  pop rax; <- restore
  call print_num

  sleep secs

 _exit:
  m_syscall SYS_EXIT
