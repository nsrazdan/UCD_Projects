# Target library
lib := libuthread.a
OBJS = queue.o uthread.o context.o preempt.o

libuthread.a: $(OBJS)
	ar rcs libuthread.a $(OBJS)

queue.o: queue.c
	gcc -c queue.c

uthread.o: uthread.c
	gcc -c uthread.c context.c

context.o: context.c
	gcc -c context.c

preempt.o: preempt.c
	gcc -c preempt.c
	
clean:
	rm -rf *.o *.a

## TODO: Phase 1.1
