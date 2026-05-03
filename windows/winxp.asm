format PE GUI 4.0
entry start
;; wine winxp.exe
include 'include/win32ax.inc'

section '.data' data readable writeable
    className db 'MyWnd',0
    title     db 'FASM XP Window',0

section '.code' code readable executable

start:
    invoke  GetModuleHandle, 0
    mov     [wc.hInstance], eax

    invoke  LoadCursor, 0, IDC_ARROW
    mov     [wc.hCursor], eax

    mov     [wc.style], CS_HREDRAW or CS_VREDRAW
    mov     [wc.lpfnWndProc], WndProc
    mov     [wc.lpszClassName], className

    invoke  RegisterClass, wc

    invoke  CreateWindowEx, \
            0, \
            className, \
            title, \
            WS_OVERLAPPEDWINDOW, \
            CW_USEDEFAULT, \
            CW_USEDEFAULT, \
            400, \
            300, \
            0, \
            0, \
            [wc.hInstance], \
            0

    mov     [hwnd], eax

    invoke  ShowWindow, eax, SW_SHOWNORMAL
    invoke  UpdateWindow, eax

msg_loop:
    invoke  GetMessage, msg, 0, 0, 0
    cmp     eax, 0
    je      exit

    invoke  TranslateMessage, msg
    invoke  DispatchMessage, msg
    jmp     msg_loop

exit:
    invoke  ExitProcess, [msg.wParam]

proc WndProc hwnd, uMsg, wParam, lParam
    cmp     [uMsg], WM_DESTROY
    je      .destroy

    invoke  DefWindowProc, [hwnd], [uMsg], [wParam], [lParam]
    ret

.destroy:
    invoke  PostQuitMessage, 0
    xor     eax, eax
    ret
endp

section '.bss' readable writeable
    wc   WNDCLASS
    msg  MSG
    hwnd dd ?

section '.idata' import data readable writeable
    library kernel32,'KERNEL32.DLL',\
            user32,'USER32.DLL'

    include 'include/api/kernel32.inc'
    include 'include/api/user32.inc'
