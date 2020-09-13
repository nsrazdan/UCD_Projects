#include <stdio.h>
#include <stdlib.h>

#include <uthread.h>
#include <preempt.h>

/*
 * Thread yielding, exiting, and joining test
 * 
 * func2 and func3 call uthread_exit() before an error message gets printed.
 * If the error message gets printed, that means that the threads are still
 * getting executed when they should be zombies
 *
 * When func1 creates and joins a thread of func3, every other thread should
 * be blocked or a zombie. Thus, func3 should finish execution despite the
 * fact that it calls uthread_yield() in the middle
 *
 * func1 should print the retvals of both func2 and func3 after they exit.
 * and main should print the retval of func1 when it returns
 *
 * If any of the above fail, then uthread_exit(), uthread_join(), and/or
 * uthread_yield() do not have the proper behavior. If not, then the functions
 * work as intended.
 * 
 * Should output:
 * 
 * Arrive thread1 Hi
 * Arrive thread2 Hi
 * Retval func2: 2
 * Arrive func3 Hi
 * thread3
 * Retval func3: 0
 * thread 1 exiting
 * retval func1: 1
 * thread0
 */
 
int func3(void* arg)
{
	printf("Arrive func3 Hi\n");
	uthread_yield();
	
	printf("thread%d\n", uthread_self());
	
	int retval = 3;
	uthread_exit(retval);

	perror("func3");
	return 3;
}

int func2(void* arg)
{
	printf("Arrive func2 Hi\n");
	uthread_yield();

	int retval = 2;
	uthread_exit(retval);
	
	perror("func2");
	return 2;
}

int func1(void* arg)
{
	int ret1, ret2;
	
	printf("Arrive func1 Hi\n");
	
	uthread_join(uthread_create(func2, NULL), &ret1);
	
	printf("Retval func2: %d\n", ret1); 
	
	uthread_join(uthread_create(func3, NULL), &ret2);
	
	printf("Retval func3: %d\n", ret2); 

	uthread_yield();
	printf("thread %d exiting\n", uthread_self());
	return 1;
}

int main(void)
{
	/* Just to make sure preemption doesn't get in the way of testing */
	preempt_disable();
	
	int retval;
	
	uthread_join(uthread_create(func1, NULL), &retval);
	printf("retval func1: %d\n", retval);
	printf("thread%d\n", uthread_self());
	
	return 0;
}
