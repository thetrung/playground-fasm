format ELF64 executable
include 'linux64a.inc'
segment readable writable
msg_fmt db "allocated 4096 bytes @ address: ",0x0
msg_len db ($ - msg_fmt)
buffer rb 64; for print_string
segment readable executable
entry main
main:
_mmap:;(NULL, 4096, PROT_READ|WRITE, MAP_PRIVATE|ANON, -1, 0)
  m_syscall SYS_MMAP,\
            ADDR_NULL, PAGE_SIZE, PROT_RWRITE,\
            MAP_PRIVATE, NO_FILE, OFFSET_EMPTY
; rax <- allocated memory address.
  push rax; <- save addr

  invoke print_string, msg_fmt, qword [msg_len]

  pop rax; <- restore
  call print_num

 _exit:
  m_syscall SYS_EXIT
