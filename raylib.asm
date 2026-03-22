format ELF64
public _start
include 'linux64a.inc'
; use int3 for debugging 
import  _exit, \
        WindowShouldClose, \ 
        DrawGrid, UpdateCamera, ClearBackground, SetTargetFPS, \
        InitWindow, CloseWindow, BeginDrawing, EndDrawing, BeginMode3D, EndMode3D

section '.text' writable executable
_start:
  invoke InitWindow, 1600, 1200, title
  invoke SetTargetFPS, 60

_loop:
  call WindowShouldClose
  if_not_zero rax, _exit
  invoke UpdateCamera, camera, CAMERA_ORBITAL

_rendering_begin:
  call BeginDrawing
  mov edi, [RAYWHITE]
  call ClearBackground

_mode3d:
  pass camera, 48   ; pass @camera struct     
  call BeginMode3D  ; > BeginMode3D( Camera3D camera )
  add  rsp,    48   ; restore rsp 

  ; grid 10x10 @ 1.0f
  movss xmm0,  [GRID_UNIT]
  mov    edi,  [GRID_SIZE]
  call DrawGrid
  ; done 3D 
  call EndMode3D

_rendering_end:
  call EndDrawing
  jmp _loop

;; data layout
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
;; > won't work if use indirect label.
