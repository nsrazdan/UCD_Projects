#include <stdio.h>
#include <stdlib.h>

#include <uthread.h>
#include <preempt.h>

/* Test case for preemption
 * Runs in 3 phases, as denoted by the print statements:
 * 1) DEFAULT, where no preemption statement has been called from the user
 * 2) DISABLED, where the user has called preempt_disable() after default
 * 3) ENABLED, where the user has reenabled preempt by calling preempt_enable()
 * 4) EXITING, where all user threads call exit and get their memory freed
 *
 * The rest of the program runs in a loop, with 2 functions that become threads,
 * huge and hello_thread
 *
 * huge) Only 1 thread is made of huge, which is a very very long loop
 * It increments an integer i until it is equal to the macro INTERVAL
 * After which it resets i to 0, prints a message, and increments a counter
 * for how many times it has printed
 * This counter, count_huge_print, is the control variable of the whole program
 *
 * hello_thread) Many threads of this function are made (about 1/4 * END)
 * It print its tid and joins to a new thread of itself
 * So, at the very end, we will have about (about 1/4 * END) threads, all
 * joined to each other
 *
 * count_huge_print:
 * After huge has printed END / 3 times (count_huge_print == END / 3), phase 2 
 * begins and preemption is disabled
 * After huge has printed 2 * END / 3 times (count_huge_print == 2 * (END / 3)),
 * phase 3 begins and preemption is re-enabled
 * Finally, once count_huge_print == END, the loop ends and all the threads
 * have terminated
 *
 * Upon termination, huge calls uthread_exit(), followed by the hello_thread
 * thread with the largest tid and going down from there
 * Each thread frees the memory of the thread further down the chain (with the
 * higher tid)
 * And when we reach main, all memory has been freed
 */
 
#define INTERVAL 5000000
#define END 200

int count_huge_print = 0;

int huge(void* arg)
{	
	long int i = 0;
	count_huge_print = 0;
	
	printf("\n\nDEFAULT\n\n\n");
	
	while(1) {
		if ((i % INTERVAL) == 0) {
			i = 0;
			printf("Hello huge %d!\n", ++count_huge_print);
		}	
		if (count_huge_print == END) {
			printf("\n\nEXITING\n\n\n");
			break;
		} else if ((count_huge_print == (END / 3)) && (i % INTERVAL == 0)) {
			printf("\n\nDISABLED\n\n\n");
			preempt_disable();
		} else if (count_huge_print == (2 * (END / 3)) && (i % INTERVAL == 0)) {
			printf("\n\nENABLED\n\n\n");
			preempt_enable();
		}
		
		i++;
	}
	
	printf("huge exiting!\n");

	return 3;
}

int hello_thread(void* arg) {
	printf("Hello thread %d!\n", uthread_self());
	
	if(count_huge_print != END) {
		uthread_join(uthread_create(hello_thread, NULL), NULL);
	}
	
	printf("Parent thread %d!\n", uthread_self());
	
	return 6;
}

int main(void)
{
	int ret1, ret2;
	uthread_t tid, tid2;

	tid = uthread_create(huge, NULL);
	tid2 = uthread_create(hello_thread, NULL);

	uthread_join(tid, &ret1);
	uthread_join(tid2, &ret2);
	
	printf("\nHello main (thread %d)! Retvals: %d %d \n\n",
		uthread_self(), ret1, ret2);

	return 0;
}
