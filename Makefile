CC=fasm
CFLAGS=-dynamic-linker /lib64/ld-linux-x86-64.so.2
CLIBS=-lc
X11=-lX11
CLEAR=*.o *.dump
.PHONY: default build

default: build

build: time malloc mmap printf_float x11

time: time.asm
	$(CC) time.asm
	ld time.o $(CLIBS) $(CFLAGS) -o time

malloc: malloc.asm
	$(CC) malloc.asm
	ld malloc.o $(CLIBS) $(CFLAGS) -o malloc

printf_float: printf_float.asm
	$(CC) printf_float.asm
	ld printf_float.o $(CLIBS) $(CFLAGS) -o printf_float

mmap: mmap.asm
	$(CC) mmap.asm
	ld mmap.o $(CLIBS) $(CFLAGS) -o mmap

x11: x11.asm
	$(CC) x11.asm
	ld x11.o -o x11 $(CLIBS) $(X11) $(CFLAGS)

clean: 
	rm -f \
	x11 x11.o \
	time time.o \
	mmap mmap.o \
	malloc malloc.o \
	printf_float.o printf_float 
