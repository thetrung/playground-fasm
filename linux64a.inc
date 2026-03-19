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
          mov dword [rsp + (count - 7)*8], arg
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
; NOTE: ====================================
; copy macro ::
; copy amount of bytes from src -> dest.  
; movsb/sw/ss/sq = 1/2/4/8-byte
;    
; More modes depends on size :
; rep movsw   ; 2 bytes
; rep movsd   ; 4 bytes
; rep movsq   ; 8 bytes
;   
; Usage: 
; > copy movsb, camera, rax, 48 
; ==========================================
macro copy size, src, dest, amount {
  cld             ; ensure forward
  mov rsi, src    ; addr/src 
  mov rdi, dest   ; addr/dest
  mov rcx, amount ; bytes
  rep size        ; mov-size 
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
