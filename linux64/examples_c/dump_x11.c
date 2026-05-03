#include <X11/Xlib.h>
#include <stddef.h>
#include <stdio.h>
#include <termios.h>
void main(void) {
  printf("termio.c_lflag %zu\n", offsetof(struct termios, c_lflag));

  printf("#define XKeyEvent_KeyCode %zu\n", offsetof(XKeyEvent, keycode));

  printf("#define XButtonEvent_X %zu\n", offsetof(XButtonEvent, x));
  printf("#define XButtonEvent_Y %zu\n", offsetof(XButtonEvent, y));

  printf("XConfigure.width %zu\n", offsetof(XConfigureEvent, width));
  printf("XConfigure.height %zu\n", offsetof(XConfigureEvent, height));
}
