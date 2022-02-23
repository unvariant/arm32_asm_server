run: server.out
	./server.out

server.out: server.o
	ld server.o -o server.out

server.o: server.s
	as server.s -o server.o -I ./include -I ./include/algorithms -I ./include/collections

clean:
	find . -name "*.o" -type f -delete
	find . -name "*.out" -type f -delete
