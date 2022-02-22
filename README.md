# ARM32 Web Server

This is a web server written completely in assembly, to help me understand ARM assembly better.<br>
The challenge I gave myself was to write a basic web server and only use assembly. This meant no C or C++ allowed at all.

The first issue I ran into was that without C, I did not have access to malloc and free to allocate/deallocate memory at runtime. So the first thing I did was implement malloc and free. To write malloc I had two options, use the [brk](https://www.man7.org/linux/man-pages/man2/sbrk.2.html) syscall or the [mmap and munmap](https://www.man7.org/linux/man-pages/man2/mmap.2.html) syscalls. The brk syscall changes the end address of the programs data segment, and can either increase or decrease the size of the data segment. The mmap syscall allocates pages of virtual memory to the calling process and munmap deallocates the memory. I ended up using mmap and munmap instead of brk because it seemed simpler.

My malloc allocates data in multiples of page size (4096 bytes) using mmap. It then splits up these bins of memory into chunks that are the user is able to use. When a chunk is freed it is simply marked as freed and when all the chunks in a bin have been freed the entire bin in deallocated using munmap.

In order to parse and store the http headers I wrote a hashmap that uses strings as keys and stores strings as values.<br>
The hashmap contains a pointer to an array of linked lists that store key value pairs. The reason for linked lists is to avoid collisions when two different keys generate the same hash.

The server opens up a socket and listens for incoming requests. When it finds a request it accepts the connection and reads the requests data into a 4kb buffer. It parses the data and if it finds "GET " in the first line it will extract the requested path and attempt to return the corresponding file. If the file does not exist it will return 404. If it finds "POST " in the first line it will return 404. Anything else and it will respond with 404.

TODO: revisit hashmap implementation and attempt to make a version that accepts generic types
TODO: look into KMP and other string search algorithms
TODO: implement threading for the server using clone
TODO: test for possible buffer overflows
