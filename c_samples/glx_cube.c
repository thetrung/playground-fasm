#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <GL/gl.h>
#include <GL/glx.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static void draw_cube(float angle)
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glLoadIdentity();
    glTranslatef(0.0f, 0.0f, -5.0f);
    glRotatef(angle, 1.0f, 1.0f, 0.0f);

    glBegin(GL_QUADS);

    glColor3f(1,0,0); // front
    glVertex3f(-1,-1, 1);
    glVertex3f( 1,-1, 1);
    glVertex3f( 1, 1, 1);
    glVertex3f(-1, 1, 1);

    glColor3f(0,1,0); // back
    glVertex3f(-1,-1,-1);
    glVertex3f(-1, 1,-1);
    glVertex3f( 1, 1,-1);
    glVertex3f( 1,-1,-1);

    glColor3f(0,0,1); // top
    glVertex3f(-1, 1,-1);
    glVertex3f(-1, 1, 1);
    glVertex3f( 1, 1, 1);
    glVertex3f( 1, 1,-1);

    glColor3f(1,1,0); // bottom
    glVertex3f(-1,-1,-1);
    glVertex3f( 1,-1,-1);
    glVertex3f( 1,-1, 1);
    glVertex3f(-1,-1, 1);

    glColor3f(1,0,1); // right
    glVertex3f( 1,-1,-1);
    glVertex3f( 1, 1,-1);
    glVertex3f( 1, 1, 1);
    glVertex3f( 1,-1, 1);

    glColor3f(0,1,1); // left
    glVertex3f(-1,-1,-1);
    glVertex3f(-1,-1, 1);
    glVertex3f(-1, 1, 1);
    glVertex3f(-1, 1,-1);

    glEnd();
}

int main()
{
    Display *dpy = XOpenDisplay(NULL);
    if(!dpy) {
        printf("Cannot open display\n");
        return 1;
    }

    int screen = DefaultScreen(dpy);

    static int attr[] = {
        GLX_RGBA,
        GLX_DEPTH_SIZE, 24,
        GLX_DOUBLEBUFFER,
        None
    };

    XVisualInfo *vi = glXChooseVisual(dpy, screen, attr);


    if (!vi) {
      printf("No appropriate visual found\n");
      exit(1);
    }

    Colormap cmap = XCreateColormap(
        dpy,
        RootWindow(dpy, vi->screen),
        vi->visual,
        AllocNone
    );

    XSetWindowAttributes swa;
    swa.colormap = cmap;
    swa.event_mask = ExposureMask | KeyPressMask | StructureNotifyMask;

    Window win = XCreateWindow(
        dpy,
        RootWindow(dpy, vi->screen),
        0,0,800,600,
        0,
        vi->depth,
        InputOutput,
        vi->visual,
        CWColormap | CWEventMask,
        &swa
    );

    XMapWindow(dpy, win);
    XStoreName(dpy, win, "GLX Rotating Cube");

    GLXContext glc = glXCreateContext(dpy, vi, NULL, GL_TRUE);
    glXMakeCurrent(dpy, win, glc);

    glEnable(GL_DEPTH_TEST);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    float aspect = 800.0f / 600.0f;
    glFrustum(-aspect, aspect, -1, 1, 1, 100);

    glMatrixMode(GL_MODELVIEW);

    float angle = 0.0f;

    while(1)
    {
        while(XPending(dpy))
        {
            XEvent xev;
            XNextEvent(dpy, &xev);

            if(xev.type == KeyPress)
                goto end;
        }

        draw_cube(angle);
        glXSwapBuffers(dpy, win);

        angle += 1.0f;
        usleep(16000); // ~60 FPS
    }

end:
    glXMakeCurrent(dpy, None, NULL);
    glXDestroyContext(dpy, glc);
    XDestroyWindow(dpy, win);
    XCloseDisplay(dpy);

    return 0;
}
