run: server.out
    ./server.out

server.out: server.o
    ld server.o -o server.out

server.o: server.s
    as server.s -o server.o -I ./include

clean:
    rm -r . *.o
    rm -r . *.out
