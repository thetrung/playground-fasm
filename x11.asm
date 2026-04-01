format ELF64
include 'linux64a.inc'
section '.data' writeable
; ============================================================
; DATA
; ============================================================
WM_DELETE_WINDOW db "WM_DELETE_WINDOW",0x0
str_len = $ - WM_DELETE_WINDOW

TITLE_MAIN db "MAIN WINDOW",0x0
str_len2 = $ - TITLE_MAIN

TITLE_CHILD db "CHILD WINDOW",0x0
str_len3 = $ - TITLE_CHILD

msg_resize_window db "resize ~> %d x %d",0xA,0
msg_event         db "event: %d",0xA,0

COLOR_BLACK equ 0x000000
COLOR_WHITE equ 0xFFFFFF
COLOR_RED   equ 0xFFF000

PARENT_WIDTH  equ 800
PARENT_HEIGHT equ 600
CHILD_WIDTH   equ 400
CHILD_HEIGHT  equ 400
OFFSET_TITLE  equ 100
TOP_THICK     equ 50


; Reserve space for X11 structs and pointers
display_ptr dq 0
window      dq 0
w_width     dq 0
w_height    dq 0
root        dq 0
child       dq 0
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

extrn printf 
; ============================================================
; CODE
; ============================================================

_start:
    ; Open display
    xor rdi, rdi               ; NULL = use DISPLAY env
    invoke XOpenDisplay
    mov [display_ptr], rax

    ; Get default screen
    invoke XDefaultScreen, [display_ptr]
    mov [screen], eax

    ; Root window
    invoke XRootWindow, [display_ptr], qword [screen]
    mov [root], rax         ; temporarily store root here
    
    ; Create simple window 
    ; XCreateSimpleWindow(Display*, RootWindow, x, y, width, height, border, foreground, background)
    invoke XCreateSimpleWindow, [display_ptr], [root], \
           0, 0, PARENT_WIDTH, PARENT_HEIGHT, 0,       \
           COLOR_WHITE, COLOR_BLACK
    mov [window], rax ; store window ID
    
    invoke XCreateSimpleWindow, [display_ptr], [window],\
           50, 400, CHILD_WIDTH, CHILD_HEIGHT, 10,      \
           COLOR_RED, COLOR_BLACK
    mov [child], rax ; store window ID -> child 

    ; Select key + close events
    mov rdx, (1 shl 17) or (1 shl 15)   ; KeyPress + StructureNotify
    invoke XSelectInput, [display_ptr], rax

    ; Setup WM_DELETE_WINDOW
    xor rdx, rdx
    invoke XInternAtom, [display_ptr], WM_DELETE_WINDOW
    mov [atom_delete], rax

    invoke XSetWMProtocols, [display_ptr], [window], atom_delete, 1

    ; Map the window (show it)
    invoke XMapWindow, [display_ptr], [window]
    invoke XMapWindow, [display_ptr], [child]

    ; Create graphics context
    xor rdx, rdx
    invoke XCreateGC, [display_ptr], [window]
    mov [gc], rax

    ; Set foreground color (white)
    invoke XSetForeground, [display_ptr], [gc], 0xFF0000

; ============================================================
; EVENT LOOP
; ============================================================

event_loop:
    mov rdi, [display_ptr]
    lea esi, [event]
    call XNextEvent
    invoke printf, msg_event, qword [event]

    cmp dword [event], 12
    jne  after_resize
    ; cmp dword [event], 12      ; Wait for Expose Event....
    ; jne event_loop             ; Else it show nothing.
; Resize Window :
; This is where I don't want to cont. with X11.
; And I should make my own DE for FASM.
    xor rax, rax
    mov rax, qword [event+48] ; width
    mov rax, qword [event+52] ; height
    mov [w_width],  r8
    mov [w_height], r9
    invoke printf, msg_resize_window, r8, r9
; ===============================
; Draw shapes
; ===============================
after_resize:
    ; Line from (50,50) -> (350,50)
    invoke XDrawLine, [display_ptr], [window], [gc], 0, TOP_THICK, [w_width], TOP_THICK
    invoke XDrawLine, [display_ptr], [child],  [gc], 0, TOP_THICK, CHILD_WIDTH,  TOP_THICK

    ; Text at (128,40) + string_ptr, string_length 
    invoke XDrawString, [display_ptr], [window], [gc], OFFSET_TITLE, TOP_THICK/2, TITLE_MAIN, str_len2
    invoke XDrawString, [display_ptr], [child],  [gc], OFFSET_TITLE, TOP_THICK/2, TITLE_CHILD, str_len3

    ; Rectangle outline at (50,70) size 100x50
    invoke XDrawRectangle, [display_ptr], [window], [gc], 50, 70, 100, 50
    invoke XDrawRectangle, [display_ptr], [window], [gc], 50, 140, 100, 50

    ; Filled rectangle at (200,70) size 100x50
    invoke XFillRectangle, [display_ptr], [window], [gc], 200, 70, 100, 50
    invoke XFillRectangle, [display_ptr], [window], [gc], 200, 140, 100, 50

    ; Arc at (150,150) width=100 height=100 start=0, span=360*64 (X11 uses 1/64 deg)
    invoke XDrawArc, [display_ptr], [window], [gc], 125, 210, 100, 100, 0, 360*64 ; 

    .flush:
    ; Flush drawing
    invoke XFlush, [display_ptr]
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
    invoke XDestroyWindow, [display_ptr], [window]
    invoke XCloseDisplay, [display_ptr]

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
