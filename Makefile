CC=fasm
CFLAGS=-dynamic-linker /lib64/ld-linux-x86-64.so.2
CLIBS=-lc
CLEAR=*.o *.dump
.PHONY: default build

default: build

build: time malloc mmap print_float

time: time.asm
	$(CC) time.asm
	ld time.o $(CLIBS) $(CFLAGS) -o time

malloc: malloc.asm
	$(CC) malloc.asm
	ld malloc.o $(CLIBS) $(CFLAGS) -o malloc

print_float: print_float.asm
	$(CC) print_float.asm
	ld print_float.o $(CLIBS) $(CFLAGS) -o print_float

mmap: mmap.asm
	$(CC) mmap.asm
	ld mmap.o $(CLIBS) $(CFLAGS) -o mmap

clean: 
	rm -f \
	time time.o \
	mmap mmap.o \
	malloc malloc.o \
	print_float.o print_float 
