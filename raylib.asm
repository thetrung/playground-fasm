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
.projection dd 0;CAMERA_PERSPECTIVE
; NOTE: 
; =============================================
; since this is treated as pure value,
; if we otherwise do this :
;   .projection dd CAMERA_PERSPECTIVE
; =============================================
; then it become address @ CAMERA_PERSPECTIVE
; instead of actual value there.
; => Always [ label->value ] not [label->label]
; =============================================
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
  ; NOTE:
  ; This is where RAYLIB suck hard for FASM :
  ; It pass another copy of Camera3D struct 
  ; instead of just pointer to it.
  ; > BeginMode3D ( Camera3D camera )
  ;
  sub rsp, 48
  mov rax, rsp
  ; Copy Struct #1 manually like Compiler :
  ; movss xmm0 => 4-bytes
  ; movss xmm0, [camera.position.x]
  ; movss [rax]  , xmm0
  ; movss [rax+4], xmm0
  ; movss [rax+8], xmm0
  ;
  ; movss xmm0, [camera.target.x]
  ; movss [rax+12], xmm0
  ; movss [rax+20], xmm0
  ; movss xmm0, [camera.target.y]
  ; movss [rax+16], xmm0
  ;
  ; movss xmm0, [camera.up.x]
  ; movss [rax+24], xmm0
  ; movss [rax+32], xmm0
  ; movss xmm0, [camera.up.y]
  ; movss [rax+28], xmm0
  ;
  ; movss xmm0, [camera.fovy]
  ; movss [rax+36], xmm0 
  ;
  ; movss xmm0, [camera.projection]  
  ; movss [rax+40], xmm0
; NOTE:
; what happen when we write :
; .projection dd CAMERA_PERSPECTIVE
; And produce trash value like :
; gdb> x/wx $rax+40 = 0x00403086
; it will hold address like :
; mov edi, CAMERA_PERSPECTIVE
; mov [rax+44], edi   
; instead of :
; gdb> x/wx $rax+40 = 0x00000000
; (which is the value what we want.)
;
; NOTE:
; Copy struct #2 by rep movxx :
; Copy 48-bytes from camera -> [rax] via movsb :
; rsi - src pointer 
; rdi - dest pointer
; rcx - bytes amount
; df  - direction flag
; mov rsi, camera ; addr/src 
; mov rdi, rax    ; addr/dest
; mov rcx, 48     ; bytes
; rep movsq       ; movsb/sw/ss/sq = 1/2/4/8-byte.

  ; Or just use macro :
  copy movsq, camera, rax, 48 

debug:
  call BeginMode3D
  add rsp, 48
  
  ; grid 10x10 @ 1.0f
  movss xmm0, [GRID_UNIT]
  mov    edi,  [GRID_SIZE]
  call DrawGrid
  
  call EndMode3D

_rendering_end:
  call EndDrawing
  jmp _loop
