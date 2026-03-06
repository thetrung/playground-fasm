CC=fasm
CFLAGS=-dynamic-linker /lib64/ld-linux-x86-64.so.2
CLIBS=-lc
X11=-lX11
GLX=-lgl
CLEAR=*.o *.dump
.PHONY: default build

default: build

build: fib time malloc mmap printf_float x11 invoke

fib: fib.asm
	$(CC) fib.asm

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

mmap: mmap.asm
	$(CC) mmap.asm
	ld mmap.o $(CLIBS) $(CFLAGS) -o mmap

x11: x11.asm
	$(CC) x11.asm
	ld x11.o -o x11 $(CLIBS) $(X11) $(CFLAGS)

clean: 
	rm -f \
	fib \
	x11 x11.o \
	time time.o \
	mmap mmap.o \
	invoke invoke.o \
	malloc malloc.o \
	printf_float.o printf_float 
