malloc: malloc.o main.o
	ld malloc.o main.o -o malloc -dynamic-linker /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o -lc

debug: malloc.o main.co
	ld malloc.o main.c o -o malloc -dynamic-linker /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /usr/lib/x86_64-linux-gnu/crt1.o /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o -lc

malloc.o: malloc.s
	as malloc.s -o malloc.o -g

main.co: main.c
	gcc -S main.c -o main.cs
	as main.cs -o main.co -g

main.o: main.c
	gcc -c main.c -o main.o -g

clean:
	rm -f *.o *.cs *.co

purge: clean
	rm -f malloc
