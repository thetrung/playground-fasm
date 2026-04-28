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
msg_position      db "  [ %d : %d ]",0xA,0
msg_event         db "event: %d",0xA,0
msg_keycode       db "[ keycode : %d ]",0xA, 0

COLOR_BLACK equ 0x000000
COLOR_WHITE equ 0xFFFFFF
COLOR_RED   equ 0xFFF000

PARENT_WIDTH  equ 800
PARENT_HEIGHT equ 600
CHILD_WIDTH   equ 400
CHILD_HEIGHT  equ 400
OFFSET_TITLE  equ 100
TOP_THICK     equ 50

MASK_NO_EVENT            equ 0

MASK_KEY_PRESS           equ (1 shl 0)
MASK_KEY_RELEASE         equ (1 shl 1)
MASK_BUTTON_PRESS        equ (1 shl 2)
MASK_BUTTON_RELEASE      equ (1 shl 3)
MASK_ENTER_WINDOW        equ (1 shl 4)
MASK_LEAVE_WINDOW        equ (1 shl 5)

MASK_POINTER_MOTION      equ (1 shl 6)
MASK_POINTER_MOTION_HINT equ (1 shl 7)

MASK_BUTTON_MOTION_1     equ (1 shl 8)
MASK_BUTTON_MOTION_2     equ (1 shl 9)
MASK_BUTTON_MOTION_3     equ (1 shl 10)
MASK_BUTTON_MOTION_4     equ (1 shl 11)
MASK_BUTTON_MOTION_5     equ (1 shl 12)
MASK_BUTTON_MOTION       equ (1 shl 8)

MASK_EXPOSURE            equ (1 shl 15)
MASK_FOCUS_CHANGE        equ (1 shl 21)

; MASK_NOTIFY_STRUCTURE    equ (1 shl 17)
; MASK_NOTIFY_SUBSTRUCTURE equ (1 shl 19)

EVENT_KEY_PRESS          equ 2
EVENT_KEY_RELEASE        equ 3
EVENT_BUTTON_PRESS       equ 4
EVENT_BUTTON_RELEASE     equ 5

EVENT_NOTIFY             equ 6
EVENT_EXPOSE             equ 12
; Nested Struct Offest 
xbutton_x                equ 64
xbutton_y                equ 68
xkey_keycode             equ 84
xconfigure_width         equ 56
xconfigure_height        equ 60
; Reserve space for X11 structs and pointers
display_ptr dq 0
window      dq 0
w_width     dq 0
w_height    dq 0
root        dq 0
child       dq 0
screen      dd 0
gc          dq 0
event       rb 64 ; XEvent is big, but we only need 64 bytes
atom_delete dq 0; WM_DELETE_WINDOW atom

keycode     dq 0
msg_buffer rb 64

mouse:
.x dq 0
.y dq 0
mouse_offset:
.x dq 50
.y dq 25


section '.text' executable
public _start
; public debug
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
extrn XClearWindow
extrn XDisplayWidth
extrn XDisplayHeight
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
extrn snprintf
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
    
    ; Select key + close events
    mov rdx, MASK_EXPOSURE \
          or MASK_BUTTON_PRESS    or MASK_BUTTON_RELEASE \
          or MASK_KEY_PRESS       or MASK_KEY_RELEASE    \
          or MASK_POINTER_MOTION  or MASK_FOCUS_CHANGE
    invoke XSelectInput, [display_ptr], [window], rdx

    ; Setup WM_DELETE_WINDOW
    xor rdx, rdx
    invoke XInternAtom, [display_ptr], WM_DELETE_WINDOW
    mov [atom_delete], rax

    invoke XSetWMProtocols, [display_ptr], [window], atom_delete, 1

    ; Map the window (show it)
    invoke XMapWindow, [display_ptr], [window]
    ; invoke XMapWindow, [display_ptr], [child]

    ; Create graphics context
    xor rdx, rdx
    invoke XCreateGC, [display_ptr], [window]
    mov [gc], rax

    ; Set foreground color (white)
    invoke XSetForeground, [display_ptr], [gc], 0xFF0000
    
    jmp event_loop
; ============================================================
; EVENT LOOP
; ============================================================
event_key_press:
    mov rax, qword [event + xkey_keycode]
    mov [keycode], rax
    invoke printf, msg_keycode, [keycode]
    mov rax, [keycode]
    cmp rax, 0
    jg cleanup     ; quit 
    jmp rendering

event_mouse_press:
    ; invoke printf, msg_position, [mouse.x], [mouse.y]
    jmp rendering

event_mouse_move:
    mov rax, qword [event + xbutton_x]
    mov [mouse.x], rax
    mov rax, qword [event + xbutton_y]
    mov [mouse.y], rax
    invoke snprintf, msg_buffer, 64, msg_position, [mouse.x], [mouse.y]
    invoke printf, msg_position, [mouse.x], [mouse.y]
    jmp rendering

event_loop:
    mov rdi, [display_ptr]
    lea esi, [event]
    call XNextEvent
    ; invoke printf, msg_event, qword [event]
input:
; KeyPress
    cmp dword [event], EVENT_KEY_PRESS
    je event_key_press
; MousePress
    cmp dword [event], EVENT_BUTTON_PRESS
    je event_mouse_press
; Mouse Move
    cmp dword [event], EVENT_NOTIFY
    je event_mouse_move
; Resize
    ; cmp dword [event], EVENT_RESIZE
; Expose
    cmp dword [event], EVENT_EXPOSE
    je rendering
    jmp event_loop
; ===============================
; Draw shapes
; ===============================
rendering:
    ; Forced Clear Screen 
    invoke XClearWindow, [display_ptr], [window]
    ; get width/height 
    invoke XDisplayWidth, [display_ptr], 0
    ; mov rax             , qword [event + xconfigure_width]
    mov qword [w_width] , rax
    invoke XDisplayHeight, [display_ptr], 0
    mov qword [w_height], rax
    ; invoke printf, msg_position, [w_width], [w_height] 

    sub [mouse.x], 50
    mov r10, [mouse.y]
    invoke XDrawLine, [display_ptr], [window], [gc], 0,                r10, [mouse.x], r10
    
    add [mouse.x], 100
    mov r10, [mouse.y]
    invoke XDrawLine, [display_ptr], [window], [gc], [w_width],        r10, [mouse.x], r10

    sub [mouse.y], 50
    sub [mouse.x], 50
    
    mov r10, [mouse.y]
    invoke XDrawLine, [display_ptr], [window], [gc], [mouse.x],          0, [mouse.x], r10
   
    mov r10, [mouse.y]
    add r10, 100
    invoke XDrawLine, [display_ptr], [window], [gc], [mouse.x], [w_height], [mouse.x], r10

    ; Text at (128,40) + string_ptr, string_length
    mov rax, [mouse_offset]
    sub [mouse.x], 50
    add [mouse.y], 50
    invoke XDrawString, [display_ptr], [window], [gc], [mouse.x], [mouse.y]     , msg_buffer, 17;str_len2
    invoke XDrawString, [display_ptr], [window], [gc], OFFSET_TITLE, TOP_THICK/2, msg_buffer, 17;str_len2

    ; Arc at (150,150) width=100 height=100 start=0, span=360*64 (X11 uses 1/64 deg)
    sub [mouse.x], 0
    sub [mouse.y], 50
    invoke XDrawArc, [display_ptr], [window], [gc], [mouse.x], [mouse.y], 100, 100, 0, 360*64 ; 

    ; Rectangle outline at (50,70) size 100x50
    ; invoke XDrawRectangle, [display_ptr], [window], [gc], 50, 140, 100, 50
    ; Filled rectangle at (200,70) size 100x50
    ; invoke XFillRectangle, [display_ptr], [window], [gc], 200, 70, 100, 50

    .flush:
    ; Flush drawing
    invoke XFlush, [display_ptr]
    jmp event_loop
    ; Check event.type == ClientMessage?
    ; cmp dword [event], 33      ; ClientMessage
    ; jne event_loop

    ; Check if client message is WM_DELETE_WINDOW
    ; mov rax, [atom_delete]
    ; cmp qword [event+16], rax
    ; jne event_loop

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
