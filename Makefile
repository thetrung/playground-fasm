CC=fasm
CFLAGS=-dynamic-linker /lib64/ld-linux-x86-64.so.2
CLIBS=-lc
CLEAR=*.o *.dump
.PHONY: default build time

default: build

build: time malloc

time: time.asm
	$(CC) time.asm
	ld time.o $(CLIBS) $(CFLAGS) -o time

malloc: malloc.asm
	$(CC) malloc.asm
	ld malloc.o $(CLIBS) $(CFLAGS) -o malloc

clean: 
	rm -f \
	time time.o \
	malloc malloc.o
