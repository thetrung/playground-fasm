
#include <fcntl.h>
#include <linux/fb.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <stdint.h>
#include <stdio.h>

int main() {
    int fb = open("/dev/fb0", O_RDWR);
    if (fb < 0) {
        perror("open fb0");
        return 1;
    }

    struct fb_var_screeninfo vinfo;
    struct fb_fix_screeninfo finfo;

    ioctl(fb, FBIOGET_FSCREENINFO, &finfo);
    ioctl(fb, FBIOGET_VSCREENINFO, &vinfo);

    long screensize = vinfo.yres_virtual * finfo.line_length;

    uint8_t *fbp = mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fb, 0);

    for (int y = 0; y < vinfo.yres; y++) {
        for (int x = 0; x < vinfo.xres; x++) {
            uint32_t color = ((x * 255 / vinfo.xres) << 16); // red gradient
            ((uint32_t*)fbp)[x + y * (finfo.line_length / 4)] = color;
        }
    }

    munmap(fbp, screensize);
    close(fb);
    return 0;
}
