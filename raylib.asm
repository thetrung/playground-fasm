format ELF64
public _start
public debug
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
msg   db "fovy = %.2f",0xA,0
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
.fovy       dd 45.0
.projection dd 0 ;CAMERA_PERSPECTIVE 
;; won't work if use indirect label.

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
  call BeginDrawing

  mov edi, [RAYWHITE]
  call ClearBackground

_mode3d:
  sub rsp, 48
  mov rax, rsp
  memcpy camera, rax, 48 
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
