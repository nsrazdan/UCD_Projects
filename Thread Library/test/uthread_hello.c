#include <stdio.h>
#include <stdlib.h>

#include <uthread.h>

/*
 * Hello world test of uthread_exit and uthread_join
 * 
 * Creates NUM threads of hello, with thread i being the parent of thread
 * i + 1. When NUM threads are reached, they all exit and print out their
 * tid and the return value of their child. Note that uthread_exit() is being
 * called by the given context files here, even though it's not being called
 * explicitly.
 *
 * Will work for any NUM you define! Try it!
 *
 * If I have a statement <from _ to _>, the statement should repeat that many
 * times. IE
 * <from i = 1 to i = 2>        =             Hello world!       
 * Hello world!                               Hello world! 
 *
 * Should output:
 *
 * <from i = 1 to i = NUM>
 * Hello world from thread i!
 * I am the final thread, thread n!
 * <from i = NUM - 1 to i = 1>
 * Thread i is parent of thread i + 1! Exiting!
 * Main thread: 0. Child returned: 1
 */
 
#define NUM 10

int hello(void* arg)
{
	int retval;
	int self = uthread_self();
	
	printf("Hello world from thread %d!\n", self);
	
	if (uthread_self() != NUM) {
		uthread_join(uthread_create(hello, NULL), &retval);	
	} else {
		printf("I am the final thread, thread %d!\n", self);
		return self;
	}
	
	printf("Thread %d is parent of thread %d! Exiting!\n", self, retval);

	return self;
}

int main(void)
{
	int retval;
	uthread_t tid;

	tid = uthread_create(hello, NULL);
	uthread_join(tid, &retval);
	
	printf("Main thread: %d. Child returned: %d\n", uthread_self(), retval);
	
	return 0;
}
