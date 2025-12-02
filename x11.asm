format ELF64
include 'macros.asm'
section '.data' writeable
; ============================================================
; DATA
; ============================================================
wm_delete_str db "WM_DELETE_WINDOW",0
str_len = $ - wm_delete_str
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
extrn XDrawString
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
    mov [window], rax         ; temporarily store root here

    ; Create simple window
    mov r10, rsp              ; &args
;   XCreateSimpleWindow(Display*, RootWindow, x, y, width, height, border, foreground, background)
    m_fn XCreateSimpleWindow, [display_ptr], [window], 100, 100, 400, 300, 0, COLOR_WHITE, COLOR_BLACK
    add rsp, 24               ; 8-bytes x 3-args
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

    ; Line from (50,50) -> (350,50)
    m_fn XDrawLine, [display_ptr], [window], [gc], 50, 50, 300, 50

    ; Text at (250,200) + string_ptr, string_length
    sub rsp, 8                ; need to align after string/float
    m_fn XDrawString, [display_ptr], [window], [gc], 120, 40, wm_delete_str, str_len
    add rsp, 16               ; realign stack -> 16 bytes

    ; Rectangle outline at (50,70) size 100x50
    m_fn XDrawRectangle, [display_ptr], [window], [gc], 50, 70, 100, 50

    ; Filled rectangle at (200,70) size 100x50
    m_fn XFillRectangle, [display_ptr], [window], [gc], 200, 70, 100, 50

    ; Arc at (150,150) width=100 height=100 start=0, span=360*64 (X11 uses 1/64 deg)
    m_fn XDrawArc, [display_ptr], [window], [gc], 150, 150, 100, 100, 0, 350*64 ; 

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


