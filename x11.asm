format ELF64
include 'macros.asm'
section '.data' writeable
; ============================================================
; DATA
; ============================================================
wm_delete_str db "WM_DELETE_WINDOW",0
COLOR_BLACK equ 0x000000
COLOR_WHITE equ 0xFFFFFF

; Reserve space for X11 structs and pointers
display_ptr dq 0
window      dq 0
screen      dd 0
gc          dq 0
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

; drawing functions
extrn XCreateGC
extrn XSetForeground
extrn XSetBackground
extrn XDrawLine
extrn XDrawRectangle
extrn XFillRectangle
extrn XDrawArc
extrn XFlush

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
    m_fn XRootWindow, qword [display_ptr], qword [screen]
    mov [window], rax          ; temporarily store root here

    ; Create simple window
    push COLOR_BLACK              ; defaut: background
    push COLOR_WHITE              ;         foreground
    push 0                    ; border width 0
    mov r10, rsp              ; &args
;   XCreateSimpleWindow(Display*, RootWindow, x, y, width, height)
    m_fn XCreateSimpleWindow, [display_ptr], [window], 100, 100, 400, 300
    add rsp, 24               ; clean args
    mov [window], rax         ; store window ID

    ; Select key + close events
    mov rdx, (1 shl 17) or (1 shl 15)   ; KeyPress + StructureNotify
    m_fn XSelectInput, [display_ptr], rax

    ; Setup WM_DELETE_WINDOW
    xor rdx, rdx
    m_fn XInternAtom, [display_ptr], wm_delete_str
    mov [atom_delete], rax

    m_fn XSetWMProtocols, [display_ptr], [window], atom_delete, 1

    ; Map the window (show it)
    m_fn XMapWindow, [display_ptr], [window]

    ; Create graphics context
    xor rdx, rdx
    m_fn XCreateGC, [display_ptr], [window]
    mov [gc], rax

    ; Set foreground color (white)
    m_fn XSetForeground, [display_ptr], [gc], 0xFF0000

; ============================================================
; EVENT LOOP
; ============================================================

event_loop:
    mov rdi, [display_ptr]
    lea rsi, [event]
    call XNextEvent

    cmp dword [event], 12      ; Wait for Expose Event....
    jne event_loop             ; Else it show nothing.
; ===============================
; Draw shapes
; ===============================

    mov rdi, [display_ptr]
    mov rsi, [window]
    mov rdx, [gc]

    ; Line from (50,50) -> (350,50)
    mov rcx, 50
    mov r8, 50
    mov r9, 300
    push 50
    call XDrawLine

    mov rdi, [display_ptr]
    mov rsi, [window]
    mov rdx, [gc]
    ; Rectangle outline at (50,70) size 100x50
    mov rcx, 50
    mov r8, 70
    mov r9, 100
    push 50
    call XDrawRectangle

    mov rdi, [display_ptr]
    mov rsi, [window]
    mov rdx, [gc]
    ; Filled rectangle at (200,70) size 100x50
    mov rcx, 200
    mov r8, 70
    mov r9, 100
    push 50
    call XFillRectangle

    mov rdi, [display_ptr]
    mov rsi, [window]
    mov rdx, [gc]
    ; Arc at (150,150) width=100 height=100 start=0, span=360*64 (X11 uses 1/64 deg)
    mov rcx, 150  ; x 
    mov r8, 150   ; y
    mov r9, 100   ; width
    push 360*64   ; angle1 - stack need to be reversed order :
    push 0        ; angle0
    push 100      ; height 
    call XDrawArc ; 
.flush:
    ; Flush drawing
    mov rdi, [display_ptr]
    call XFlush
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


