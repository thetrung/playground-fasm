format ELF64
public _start
extrn _exit
;; libC
extrn strcpy
extrn printf
extrn sprintf
;; raylib
extrn InitWindow
extrn CloseWindow
extrn DrawGrid
extrn EndDrawing
extrn BeginDrawing
extrn BeginMode3D
extrn EndMode3D
extrn UpdateCamera
extrn ClearBackground
extrn SetTargetFPS
extrn WindowShouldClose
extrn GetApplicationDirectory
include 'linux64a.inc'
section '.note.GNU-stack'
section '.data' writable
title db "raylib demo on FASM",0,0
msg   db "float: %.2f",0xA,0
RAYWHITE           dd 0xFFFFFFFF
CAMERA_PERSPECTIVE dd 0
CAMERA_ORBITAL     dd 2
GRID_UNIT          dd 0.5
GRID_SIZE          dd 40
struc Vec3 x,y,z {
  .x dd x
  .y dd y
  .z dd z
}
camera:
.position   Vec3 6.0, 6.0, 6.0
.target     Vec3 0.0, 2.0, 0.0
.up         Vec3 0.0, 1.0, 0.0
.fovy       dd 30.0
.projection dd CAMERA_PERSPECTIVE
; Note: 
; This is where Raylib become ugly for FASM or ASM in general.
; So X11/GLX (or GLFW) is much more friendly.
section '.text' writable executable
_start:
  ; test value 
  cvtss2sd xmm0, [camera.fovy]
  invoke printf, msg

  invoke InitWindow, 1600, 1200, title
  invoke SetTargetFPS, 60

_loop:
  call WindowShouldClose
  test eax, eax
  jnz _exit
  invoke UpdateCamera, camera, CAMERA_ORBITAL

_rendering_begin:
; Rendering pipeline 
  call BeginDrawing
  ; white background
  mov edi, [RAYWHITE]
  call ClearBackground

_mode3d:
  ; Note (cont.) 
  ; This is where RAYLIB suck hard for FASM :
  ; It pass another copy of Camera3D struct 
  ; instead of just pointer to it.
  ; BeginMode3D(Camera3D camera)
  ;
  sub rsp, 48
  mov rax, rsp
  ; Copy Struct :
  ; But this isn't seem to be stable enough,
  ; as it really depends on how the function
  ; actually access struct data.
  movss xmm0, [camera.position.x]
  movss [rax]  , xmm0
  movss [rax+4], xmm0
  movss [rax+8], xmm0

  movss xmm0, [camera.target.x]
  movss [rax+12], xmm0
  movss [rax+20], xmm0
  movss xmm0, [camera.target.y]
  movss [rax+16], xmm0

  movss xmm0, [camera.up.x]
  movss [rax+24], xmm0
  movss [rax+32], xmm0
  movss xmm0, [camera.up.y]
  movss [rax+28], xmm0

  movss xmm0, [camera.fovy]
  movss [rax+36], xmm0 

  ; this doesn't work : 
  ; mov rdi, qword [camera.projection] 
  
  ; but either way below work :
  xor rdi, rdi
  mov qword [rax+40], rdi
  ; pxor xmm0, xmm0
  ; movss [rax+40], xmm0

  call BeginMode3D
  add rsp, 48
  xor rax, rax
  
  ; grid 10x10 @ 1.0f
  movss xmm0, [GRID_UNIT]
  mov    edi,  [GRID_SIZE]
  call DrawGrid
  
  call EndMode3D

_rendering_end:
  call EndDrawing
  jmp _loop
