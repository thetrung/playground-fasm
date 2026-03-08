format ELF64
include 'linux64a.inc'
public _start
section '.data' writable
dsplay    dq 0
screen    dq 0
window    dq 0
visual    dq 0
root      dq 0
width     dq 1280
height    dq 800 
context   dq 0

angle     dd 0.0
aspect    dd 0.0
; 64-bit double need 2 zeroes to paste correctly in FASM.
left      dq 1.00
right     dq -1.00
bottom    dq -1.00
top       dq 1.00
near_val  dq 1.00
far_val   dq 100.00

rot_speed dd 1.0

one        dd 1.0
zero       dd 0.0
half       dd 0.5
minus_half dd -0.5
minus_one  dd -1.0

cam_x dd 0.0
cam_y dd 0.0
cam_z dd -5.0

title db "FASM GLX Cube",0

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

attr dd GL_RGBA, GL_DEPTH_SIZE, 24, GL_DOUBLEBUFFER, NULL

extrn XOpenDisplay
extrn XDefaultScreen
extrn XRootWindow
extrn XCreateSimpleWindow
extrn XMapWindow
extrn XStoreName

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

invoke glXChooseVisual, [dsplay], [screen], attr
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

; configs
invoke glEnable,         GL_DEPTH_TEST 
invoke glMatrixMode,     GL_PROJECTION

; aspect
mov rax, [width]
cvtsi2sd xmm0, rax          ; integer -> double

mov rax, [height]
cvtsi2sd xmm1, rax          ; integer -> double

divsd xmm0, xmm1            ; width / height
movsd [left], xmm0

cvtss2sd xmm1, [minus_one]  ; 32-bit float -> 64-bit double 
mulsd xmm0, xmm1            ; aspect * (-1)
movsd [right], xmm0

; frustum
simd movsd, glFrustum, [left], [right], [bottom], [top], [near_val], [far_val]
invoke glMatrixMode,     GL_MODELVIEW

main_loop:
; clear screen 
invoke glClear, (GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)
call glLoadIdentity

; move camera
simd movss, glTranslatef, [cam_x], [cam_y], [cam_z]
simd movss, glRotatef, [angle], [one], [one], [zero]

; demo cube for now:
jmp draw_cube

draw_triangle:
invoke glBegin, GL_TRIANGLES

simvoke glColor3f, [one], [zero], [zero] ;1,0,0)
simvoke glVertex3f, [minus_half], [minus_half], [minus_one] ;-0.5,-0.5,-1)

simvoke glColor3f, [zero], [one], [zero] ;0,1,0)
simvoke glVertex3f, [half], [minus_half], [minus_one] ;0.5,-0.5,-1)

simvoke glColor3f, [zero], [zero], [one] ;0,0,1)
simvoke glVertex3f, [zero], [half], [minus_one] ;0,0.5,-1)

call glEnd
jmp swap

draw_cube:
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

swap:
; swap buffers
invoke glXSwapBuffers, [dsplay], [window]

; angle+= rot_speed
movss xmm0,[angle]
addss xmm0,[rot_speed]
movss [angle],xmm0

; sleep
invoke usleep, 16000

jmp main_loop

