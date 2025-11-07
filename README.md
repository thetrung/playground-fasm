Playground FASM
======================
A sum of all bite-size puzzles/examples to learn Flat Assembler (FASM), piece by piece.

### syscall (no library)
- hello world : [hello.asm](https://github.com/thetrung/playground-fasm/blob/master/hello.asm)
- concat string : [concate_string.asm](https://github.com/thetrung/playground-fasm/blob/master/concat_string.asm)
- fibonacci & print numbers : [fib.asm](https://github.com/thetrung/playground-fasm/blob/master/fib.asm)

### call function from library
Need to run `make` to compile & link :
- time / lib64 : [time.asm](https://github.com/thetrung/playground-fasm/blob/master/time.asm)
- malloc / lib64 : [malloc.asm](https://github.com/thetrung/playground-fasm/blob/master/malloc.asm)

### Run via Docker
- If you consider my minimal already-setup image based on `ubuntu-24.04/6.11.11-linuxkit`:

        docker pull deulamco/ubuntu-amd64:latest

- Else, start your own container :

        docker run --rm -it --platform linux/amd64 -v $(pwd):/local ubuntu:24.04

- Install packages :

        apt update -y && apt install fasm make binutils libc6-dev

- Save your container -> image to use later :

        docker ps
        docker commit asteartnh3 your_hub/repo_name:tag
        docker push your_hub/repo_name:tag

- Run :

        docker run -it -v $(pwd):/local your_hub/repo_name:tag

** This playground is based on x86-64 only, so we need a fixed environment to emulate it exclusively.