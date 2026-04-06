default: build run clean

run:
	./arg11
	./glx_cube

build: arg11 glx_cube dump_x11


arg11: arg11.c
	gcc arg11.c -S -masm=intel
	# gcc will generate AT&T syntax by default.
	as arg11.s -o arg11.o -msyntax=intel
	# as need -msyntax if not AT&T syntax.
	gcc arg11.o -o arg11

glx_cube: glx_cube.c
	gcc glx_cube.c -o glx_cube -lX11 -lGL -lm
	gcc glx_cube.c -S -masm=intel

dump_x11: dump_x11.c
	gcc dump_x11.c -o dump_x11 -lX11 
	./dump_x11

clean:
	rm -rf \
		dump_x11.o dump_x11 \
		arg11.o arg11.s arg11 \
		glx_cube.s glx_cube

