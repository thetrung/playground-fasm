
format ELF64


section '.data' writeable

; ============================================================
; DATA
; ============================================================
wm_delete_str db "WM_DELETE_WINDOW",0

; Reserve space for X11 structs and pointers
display_ptr dq 0
window      dq 0
screen      dd 0
event       rb 64            ; XEvent is big, but we only need 64 bytes

atom_delete dq 0             ; WM_DELETE_WINDOW atom

section '.text' executable
public _start

; ============================================================
; EXTERNAL IMPORTS
; ============================================================

; void *XOpenDisplay(char *name)
extrn XOpenDisplay

; unsigned long XDefaultScreen(Display*)
extrn XDefaultScreen

; unsigned long XRootWindow(Display*, int)
extrn XRootWindow

; unsigned long XCreateSimpleWindow(...)
extrn XCreateSimpleWindow

; void XSelectInput(Display*, Window, long event_mask)
extrn XSelectInput

; void XMapWindow(Display*, Window)
extrn XMapWindow

; Atom XInternAtom(Display*, char*, Bool)
extrn XInternAtom

; void XSetWMProtocols(Display*, Window, Atom*, int)
extrn XSetWMProtocols

; int XNextEvent(Display*, XEvent*)
extrn XNextEvent

; void XDestroyWindow(Display*, Window)
extrn XDestroyWindow

; void XCloseDisplay(Display*)
extrn XCloseDisplay


; ============================================================
; CODE
; ============================================================

_start:

    ; Open display
    xor rdi, rdi               ; NULL = use DISPLAY env
    call XOpenDisplay
    mov [display_ptr], rax

    ; Get default screen
    mov rdi, rax
    call XDefaultScreen
    mov [screen], eax

    ; Root window
    mov rdi, [display_ptr]
    mov esi, [screen]
    call XRootWindow
    mov [window], rax          ; temporarily store root here

    ; Create simple window
    mov rdi, [display_ptr]     ; Display*
    mov rsi, rax               ; RootWindow
    mov rdx, 100               ; x
    mov rcx, 100               ; y
    mov r8,  400               ; width
    mov r9,  300               ; height

    push 0xFFFFFF              ; border color white
    push 0x000000              ; bg color black
    push 0                    ; border width 0
    mov r10, rsp              ; &args

    call XCreateSimpleWindow
    add rsp, 24               ; clean args
    mov [window], rax         ; store window ID

    ; Select key + close events
    mov rdi, [display_ptr]
    mov rsi, rax
    mov rdx, (1 shl 17) or (1 shl 15)   ; KeyPress + StructureNotify
    call XSelectInput

    ; Setup WM_DELETE_WINDOW
    mov rdi, [display_ptr]
    mov rsi, wm_delete_str
    xor rdx, rdx
    call XInternAtom
    mov [atom_delete], rax

    mov rdi, [display_ptr]
    mov rsi, [window]
    mov rdx, atom_delete
    mov rcx, 1
    call XSetWMProtocols

    ; Map the window (show it)
    mov rdi, [display_ptr]
    mov rsi, [window]
    call XMapWindow

; ============================================================
; EVENT LOOP
; ============================================================

event_loop:
    mov rdi, [display_ptr]
    lea rsi, [event]
    call XNextEvent

    ; Check event.type == ClientMessage?
    cmp dword [event], 33      ; ClientMessage
    jne event_loop

    ; Check if client message is WM_DELETE_WINDOW
    mov rax, [atom_delete]
    cmp qword [event+16], rax
    jne event_loop

    ; Exit loop
    jmp cleanup


; ============================================================
; CLEANUP
; ============================================================

cleanup:
    mov rdi, [display_ptr]
    mov rsi, [window]
    call XDestroyWindow

    mov rdi, [display_ptr]
    call XCloseDisplay

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall


