format ELF64
include 'linux64a.inc'
public _start
section '.data' writable
dsplay    dq 0
screen    dq 0
window    dq 0
visual    dq 0
root      dq 0
width     dq 800
height    dq 600 
context   dq 0

angle     dd 0.0
aspect    dd 0.0

left      dd 1
right     dd -1
bottom    dd -1
top       dd 1
near_val  dd 1
far_val   dd 100

rot_speed dd 1.0

one        dd 1.0
zero       dd 0.0
half       dd 0.5
minus_half dd -0.5
minus_one  dd -1.0
minus_five dd -5.0

title db "FASM GLX Cube",0

Xevent rb 192

GL_MODELVIEW        equ 1700h
GL_PROJECTION       equ 1701h

GL_COLOR_BUFFER_BIT equ 00004000h
GL_DEPTH_BUFFER_BIT equ 00000100h
GL_DEPTH_TEST       equ 0B71h

GL_QUADS            equ 0007h
GL_TRIANGLES        equ 0004h

GL_RGBA             equ 4
GL_DEPTH_SIZE       equ 12
GL_DOUBLEBUFFER     equ 5
NULL                equ 0
GL_TRUE             equ 1

attribs dd GL_RGBA, GL_DEPTH_SIZE, 24, GL_DOUBLEBUFFER, NULL

extrn XOpenDisplay
extrn XDefaultScreen
extrn XRootWindow
extrn XCreateSimpleWindow
extrn XMapWindow
extrn XNextEvent
extrn XPending
extrn XStoreName
extrn XSelectInput

extrn glXChooseVisual
extrn glXCreateContext
extrn glXMakeCurrent
extrn glXSwapBuffers

extrn glClear
extrn glClearColor
extrn glEnable
extrn glRotatef
extrn glBegin
extrn glEnd
extrn glVertex3f
extrn glColor3f
extrn glLoadIdentity
extrn glTranslatef
extrn glMatrixMode
extrn glFrustum

extrn usleep

section '.text' executable
_start:

invoke XOpenDisplay, 0
mov [dsplay],rax

invoke XDefaultScreen, [dsplay]
mov [screen],rax

invoke glXChooseVisual, [dsplay], [screen], attribs
mov [visual],rax

invoke XRootWindow, [dsplay], [screen]
mov [root], rax

invoke XCreateSimpleWindow, [dsplay], [root], 0, 0, [width], [height], 32, 0
mov [window],rax

invoke XMapWindow, [dsplay], [window]
invoke XStoreName, [dsplay], [window], title

; create GLX context
invoke glXCreateContext, [dsplay], [visual], NULL, GL_TRUE
mov [context], rax
invoke glXMakeCurrent,   [dsplay], [window], [context]
invoke glEnable,         GL_DEPTH_TEST
invoke glMatrixMode,     GL_PROJECTION

; float aspect
mov rax, [width]
cvtsi2ss xmm0, rax
mov rax, [height]
cvtsi2ss xmm1, rax
divss xmm0, xmm1        ; width / height
movss [left], xmm0
mulss xmm0, [minus_one]
movss [right], xmm0

; frustum 
simvoke glFrustum, [left], [right], [bottom], [top], [near_val], [far_val]
invoke glMatrixMode,     GL_MODELVIEW

main_loop:

invoke glClear, GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT
call glLoadIdentity
; simvoke glTranslatef, [zero], [zero], [minus_five]
simvoke glRotatef, [angle], [one], [one], [zero]

; invoke glBegin, GL_TRIANGLES
;
; simvoke glColor3f, [one], [zero], [zero] ;1,0,0)
; simvoke glVertex3f, [minus_half], [minus_half], [minus_one] ;-0.5,-0.5,-1)
;
; simvoke glColor3f, [zero], [one], [zero] ;0,1,0)
; simvoke glVertex3f, [half], [minus_half], [minus_one] ;0.5,-0.5,-1)
;
; simvoke glColor3f, [zero], [zero], [one] ;0,0,1)
; simvoke glVertex3f, [zero], [half], [minus_one] ;0,0.5,-1)
;
; call glEnd

; draw cube
invoke glBegin, GL_QUADS

; front
simvoke glColor3f,  [one],            [zero], [zero]
simvoke glVertex3f, [minus_one], [minus_one], [one]
simvoke glVertex3f, [one],       [minus_one], [one]
simvoke glVertex3f, [one],             [one], [one]
simvoke glVertex3f, [minus_one],       [one], [one]

; back
simvoke glColor3f,  [zero],            [one], [zero]
simvoke glVertex3f, [minus_one], [minus_one], [minus_one]
simvoke glVertex3f, [minus_one],       [one], [minus_one]
simvoke glVertex3f, [one],             [one], [minus_one]
simvoke glVertex3f, [one],       [minus_one], [minus_one]

; top
simvoke glColor3f,  [zero],     [zero], [one]
simvoke glVertex3f, [minus_one], [one], [minus_one]
simvoke glVertex3f, [minus_one], [one], [one]
simvoke glVertex3f, [one],       [one], [one]
simvoke glVertex3f, [one],       [one], [minus_one]

; bottom
simvoke glColor3f,  [one],             [one], [zero]
simvoke glVertex3f, [minus_one], [minus_one], [minus_one]
simvoke glVertex3f, [one],       [minus_one], [minus_one]
simvoke glVertex3f, [one],       [minus_one], [one]
simvoke glVertex3f, [minus_one], [minus_one], [one]

; right
simvoke glColor3f,  [one],      [zero], [one]
simvoke glVertex3f, [one], [minus_one], [minus_one]
simvoke glVertex3f, [one],       [one], [minus_one]
simvoke glVertex3f, [one],       [one], [one]
simvoke glVertex3f, [one], [minus_one], [one]

; left
simvoke glColor3f,  [zero],            [one], [one]
simvoke glVertex3f, [minus_one], [minus_one], [minus_one]
simvoke glVertex3f, [minus_one], [minus_one], [one]
simvoke glVertex3f, [minus_one],       [one], [one]
simvoke glVertex3f, [minus_one],       [one], [minus_one]

call glEnd

; swap buffers
invoke glXSwapBuffers, [dsplay], [window]

; angle+= rot_speed
movss xmm0,[angle]
addss xmm0,[rot_speed]
movss [angle],xmm0

; sleep
invoke usleep, 16000

jmp main_loop

