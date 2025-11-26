CC=fasm
CFLAGS=-dynamic-linker /lib64/ld-linux-x86-64.so.2
CLIBS=-lc
CLEAR=*.o *.dump
.PHONY: default build

default: build

build: time malloc mmap printf_float

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

clean: 
	rm -f \
	time time.o \
	mmap mmap.o \
	malloc malloc.o \
	printf_float.o printf_float 
