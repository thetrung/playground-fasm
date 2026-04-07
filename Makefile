CC=fasm
CFLAGS=-dynamic-linker /lib64/ld-linux-x86-64.so.2
CLIBS=-lc
X11=-lX11
GLX=-lGL
RAYLIB=-lraylib
CLEAR=*.o *.dump
.PHONY: default build

default: build

build: fib tui time hello malloc mmap concat_string framebuffer printf_float invoke x11 glx raylib

fib: fib.asm
	$(CC) fib.asm

concat_string: concat_string.asm
	$(CC) concat_string.asm

mmap: mmap.asm
	$(CC) mmap.asm

hello: hello.asm
	$(CC) hello.asm

framebuffer: framebuffer.asm
	$(CC) framebuffer.asm

tui: tui.asm
	$(CC) tui.asm

time: time.asm
	$(CC) time.asm
	ld time.o $(CLIBS) $(CFLAGS) -o time

malloc: malloc.asm
	$(CC) malloc.asm
	ld malloc.o $(CLIBS) $(CFLAGS) -o malloc

printf_float: printf_float.asm
	$(CC) printf_float.asm
	ld printf_float.o $(CLIBS) $(CFLAGS) -o printf_float

invoke: invoke.asm
	$(CC) invoke.asm
	ld invoke.o $(CLIBS) $(CFLAGS) -o invoke

x11: x11.asm
	$(CC) x11.asm
	ld x11.o -o x11 $(CLIBS) $(X11) $(CFLAGS)

glx: glx.asm
	$(CC) glx.asm
	ld glx.o -o glx $(CLIBS) $(CFLAGS) $(X11) $(GLX)

raylib: raylib.asm
	$(CC) raylib.asm
	ld raylib.o -o raylib $(RAYLIB) $(CLIBS) $(CFLAGS)

clean: 
	rm -f \
	fib \
	tui \
	x11 x11.o \
	glx glx.o \
	time time.o \
	mmap mmap.o \
	hello hello.o \
	raylib raylib.o \
	invoke invoke.o \
	malloc malloc.o \
	framebuffer framebuffer.o \
	printf_float printf_float.o \
	concat_string concat_string.o 
