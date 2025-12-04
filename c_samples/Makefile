default: build run

run:
	./arg11

build:
	gcc arg11.c -S -masm=intel
	# gcc will generate AT&T syntax by default.
	as arg11.s -o arg11.o -msyntax=intel
	# as need -msyntax if not AT&T syntax.
	gcc arg11.o -o arg11

clean:
	rm -rf arg11.o arg11.s arg11
