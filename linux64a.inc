; SYSCALLs 
SYS_MMAP      equ 9
SYS_READ      equ 0
SYS_WRITE     equ 1
SYS_IOCTL     equ 16
SYS_SLEEP     equ 35
SYS_EXIT      equ 60
SYS_SOCKET    equ 41
SYS_CONNECT   equ 42
SYS_SENDMSG   equ 46; (sockfd, msghdr, flags)
SYS_RECVMSG   equ 47; (sockfd, msghdr, flags)
SYS_FTRUNCATE equ 77
SYS_MEMFD_CREATE  equ 319
; I/O
STDIN         equ 0
STDOUT        equ 1
; IOCTL
TCGETS        equ 0x5401
TCSETS        equ 0x5402
TIOCGWINSZ    equ 0x5413 
; SOCKET 
AF_UNIX       equ 1
SOCK_STREAM   equ 1
; MMAP
PROT_NONE     equ 0
PROT_READ     equ 1
PROT_WRITE    equ 2
PROT_RWRITE   equ 3
PROT_EXEC     equ 4
MAP_SHARED    equ 1
MAP_PRIVATE   equ 22
MAP_ANONYMOUS equ 20
OFFSET_EMPTY  equ 0
ADDR_NULL     equ 0
PAGE_SIZE     equ 4096; bytes
NO_FILE       equ -1
;; MEMFD
MFD_CLOEXEC       equ 1
MFD_ALLOW_SEALING equ 2

; ==========================================
; import macro ::
; to [extrn] a series of stuffs.
; ==========================================
macro import [arg] {
  forward 
    extrn arg
}
; ==========================================
; m_syscall macros
; make syscall in Linux ABI calling convention.
;
; USAGE: m_syscall syscode, arg1...arg6 
; syscall order = rdi, rsi, rdx, r10, r8, r9.
;
; EXAMPLE: 
; m_syscall SYS_EXIT
; ==========================================
macro m_syscall syscode,a1,a2,a3,a4,a5,a6 {
  mov rax, syscode
  
  if ~a1 eq
    mov rdi, a1
  end if
  
  if ~a2 eq
    mov rsi, a2
  end if
  
  if ~a3 eq
    mov rdx, a3
  end if
  
  if ~a4 eq
    mov r10, a4 ; NOTE: syscall use r10 instead rcx.
  end if
  
  if ~a5 eq
    mov r8,  a5
  end if
  
  if ~a6 eq
    mov r9,  a6
  end if

  syscall  ; rax <- allocated memory address
}

; ==========================================
; m_fn macros
; function call in Linux ABI calling convention.
;
; USAGE: m_fn fname, arg1...arg6 
; function call order = rdi, rsi, rdx, rcx, r8, r9.
;
; EXAMPLE: 
; m_fn printf, fmt, arg1
; ==========================================
macro m_fn fname,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10 {
  if ~a1 eq
    mov rdi, a1
  end if
  
  if ~a2 eq
    mov rsi, a2
  end if
  
  if ~a3 eq
    mov rdx, a3
  end if
  
  if ~a4 eq
    mov rcx, a4
  end if
  
  if ~a5 eq
    mov r8,  a5
  end if
  
  if ~a6 eq
    mov r9,  a6
  end if

  if ~a10 eq
    push a10
  end if

  if ~a9 eq
    push a9
  end if

  if ~a8 eq
    push a8
  end if

  if ~a7 eq
    push a7
  end if

  if ~fn eq
    call fname
  end if
}

; ==========================================
; invoke macros for linux AMD64 
; calling convention by Linux ABI AMD64.
;
; USAGE: invoke function, arg1...argN 
; order = rdi, rsi, rdx, r10, r8, r9.
;
; EXAMPLE: 
; invoke printf, fmt, 1, 2, 3, 4
; ==========================================
macro invoke function, [arg] 
{
  common
    local n
    n = 0 
  
  forward 
    if ~arg eq
      n = n + 1
    end if

    if n = 1
      mov rdi, arg
    end if 

    if n = 2
      mov rsi, arg
    end if 

    if n = 3
      mov rdx, arg
    end if 
    
    if n = 4
      mov rcx, arg
    end if 

    if n = 5
      mov r8, arg
    end if 
    
    if n = 6
      mov r9, arg
    end if 
; move the rest to stack:
  common
    if n > 6
      stack_space = (n - 6) * 8
      ; if (stack_space & 0xF )
      ;   display `function # " -> alignment  % 16 != 0 => rsp-8",13,10
      ; end if
      sub rsp, stack_space
      count = n
      reverse
        if count > 6
          mov qword [rsp + (count - 7)*8], arg
          count = count - 1
        end if
      common
    end if
    ; execute :
    call function
    ; align stack :
    if n > 6
      add rsp, stack_space
    end if
}

macro simd move, function, [arg] {
  common
    local n
    n = 0 
  
  forward
    n = n + 1

    if n = 1 
      move xmm0, arg
    end if 
    
    if n = 2 
      move xmm1, arg
    end if 

    if n = 3 
      move xmm2, arg
    end if 

    if n = 4 
      move xmm3, arg
    end if

    if n = 5 
      move xmm4, arg
    end if 
    
    if n = 6 
      move xmm5, arg
    end if 
    
    if n = 7 
      move xmm6, arg
    end if 

    if n = 8 
      move xmm7, arg
    end if

  common
    call function
}

macro simvoke function, [arg] {
  common simd movss, function, arg
}
; ==========================================
; memcpy macro ::
; copy amount of bytes from src -> dest.  
; movsb/sw/ss/sq = 1/2/4/8-byte
;    
; More modes depends on size :
; rep movsw   ; 2 bytes
; rep movsd   ; 4 bytes
; rep movsq   ; 8 bytes
;   
; Usage: 
; > copy camera, rax, 48 
; ==========================================
macro memcpy src, dest, amount {
  cld             ; ensure forward
  mov rsi, src    ; addr/src 
  mov rdi, dest   ; addr/dest
  mov rcx, amount ; bytes
  rep movsb       ; movsb = 1-byte but fastest. 
}

; ==========================================
; pass struct macro ::
; copy a struct with size -> stack. 
; short-hand for memcpy with struct passing.   
;   
; Usage: 
; > pass camera, 48
; > call Begin_Mode_3D
; > end_pass
; ==========================================
macro pass _struct, _size {
  sub rsp, _size
  memcpy _struct, rsp, _size
}

macro if_not_zero reg, _label {
  test reg, reg
  jnz _label
}
; BASES
; ==========================================
; text auto-length macro ::
; auto-adding length as len.name to a string. 
;
; Usage:
; text hello, 0xA,"Hello World",0xA,0
;
; > access length: 
; invoke print_string. hello, len.hello
; ==========================================
macro text name, [content] {
  common
  name db content
  len#name = $ - name
}
; ==========================================
; print_string(rsi:msg_fmt, rdx:msg_len)
; ==========================================
print_string:
    mov rdx, rsi
    mov rsi, rdi
    mov rax, STDOUT
    mov rdi, SYS_WRITE
    ; mov rsi, msg_fmt
    ; mov rdx, msg_len
    syscall
    ret
;==============================
; Concat 2 string -> &buffer
; rdi - buffer
; rsi - string_1
; rdx - string_2
;==============================
concat_string:      ; copy bytes [esi] -> [edi]
	lodsb             ; load-byte  mov al, [esi] 
	stosb             ; store-byte mov [edi], al
	test al, al       ; any byte left ?
	jnz concat_string ; cont. copy 1st string -> buffer
	test r12,r12      ; did we append yet ? 
  jnz .done         ; exit if appended 2nd.
  mov r12, 1        ; else is_appending = true
  mov rsi, rdx      ; append 2nd string
	jmp concat_string ; start appending..
.done:
  ret 
; ==========================================
; print_num (rax) - 32 bytes buffer 
; print a string of number, require buffer.
; ==========================================
BUF_NUM equ 32
print_num: ;(rax)
    call integer_to_string
    invoke print_string, rax, rbx 
    ret
; ==========================================
; integer_to_string (rax)->(rax/rbx) 
; input: 
; rax - number to convert 
;
; output: 
; rax/rbx - buffer/length 
;
; usage: 
; convert integer in rax -> rax/rbx 
; as string/length in result.
; ** we are using 32 bytes buffer only.
; ==========================================
integer_to_string:
    ; save stack of current values :
    push rdi rdx rsi
    ;
    ; start converting (rax): 
    ;
    ; we use 32 bytes buffer reserved bytes : 
    sub rsp, BUF_NUM
    mov rdi, rsp        ; Hold BUFFER on [RSP]        
    add rdi, BUF_NUM-1  ; move pointer  -> end of buffer :
    mov byte [rdi],  0  ; Set value 10 -> buffer[19]
    dec rdi             ; Set pointer  -> buffer[18] 
    mov rcx, 10     ; divisor = 10
.convert_digit:      ; Convert Digit -> ASCII :
    xor rdx, rdx    ; clear rdx for division reminder.
    div rcx         ; rax / 10 => rax = quotient | rdx = reminder
    add dl, '0'     ; convert reminder => ASCII
    dec rdi         ; buffer[i--]
    mov [rdi], dl   ; copy converted digit >> buffer[i]
    test rax, rax   ; if quotient = zero, we are done.
    jnz .convert_digit
.compute_length:      ; compute length of string to print :
    mov rdx, rsp      ; rdx =  buffer Address
    add rdx, BUF_NUM-1; rdx += end of buffer
    sub rdx, rdi      ; rdx -= used_bytes
    mov rbx, rdx      ; rbx return -> length
    mov rax, rdi      ; rax return -> buffer
                      ; Cleanup...
    add rsp, BUF_NUM  ; return RSP.
    pop rsi rdx rdi   ; restore values to registers.
    ret               ; string/length >> rax/rbx
; ==========================================
; sys_sleep (rdi,rsi)
; sleep for rdi-seconds + rsi-nano-seconds.
;
; ==========================================
sys_sleep:
    sub rsp,           16
    mov qword [rsp],   rdi; tv_sec = 1,000,000,000 ns
    mov qword [rsp+8], rsi; tv_nsec <= 999,999,999 ns
    mov rax,           SYS_SLEEP
    lea rdi,           [rsp]; timespecs
    syscall
    add rsp,           16
    ret
; ==========================================
; sys_exit ()
; just exit bro.
; ==========================================
sys_exit:
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
    ret
; ==========================================
; m_for loop
; Reusable FASM macro for "for loop"
;
; Usage: m_for reg, start, end, body
; %$ - to make unique label names
;
; Example:
;   m_for eax, 0, 4, {
;       ; loop body here
;   }
; ==========================================
macro m_for index, _begin, _end, body {
  mov index, _begin
  .for_loop_start_%$:
    cmp index, _end
    jg .for_loop_end_%$
      body
    inc index
    jmp .for_loop_start_%$
  .for_loop_end_%$:
}
