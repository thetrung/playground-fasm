format ELF64
public _start
include 'linux64a.inc'
; use int3 for debugging 
import  _exit, \
        WindowShouldClose,InitWindow, CloseWindow, \ 
        BeginDrawing, EndDrawing, BeginMode3D, EndMode3D, \
        DrawGrid, UpdateCamera, ClearBackground, SetTargetFPS
section '.text' writable executable
_start:
  invoke InitWindow, 1600, 1200, title
  invoke SetTargetFPS, 60

_loop:
  call WindowShouldClose
  if_not_zero rax, _exit
  invoke UpdateCamera, camera, 2; CAMERA_ORBITAL

_rendering_begin:
  call BeginDrawing
  invoke ClearBackground, 0xFFFFFFFF ;[RAYWHITE]

_mode3d:
  pass camera, 48   ; pass @camera struct     
  call BeginMode3D  ; > BeginMode3D( Camera3D camera )
  add  rsp,    48   ; restore rsp 
  ; grid 40x40 @ 0.5f
  movss xmm0,  [GRID_UNIT]
  mov edi,     [GRID_SIZE]
  call DrawGrid
  call EndMode3D

_rendering_end:
  call EndDrawing
  jmp _loop

section '.data' writable
title db "raylib demo on FASM",0x0,0
GRID_UNIT   dd 0.5
GRID_SIZE   dd 40
camera:
.position   dd 6.0, 6.0, 6.0
.target     dd 0.0, 2.0, 0.0
.up         dd 0.0, 1.0, 0.0
.fovy       dd 45.0
.projection dd 0 ;CAMERA_PERSPECTIVE   
