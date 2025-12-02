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
