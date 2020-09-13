#include <assert.h>
#include <signal.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <limits.h>
#include <ucontext.h>

#include "context.h"
#include "preempt.h"
#include "queue.h"
#include "uthread.h"

#define STACK_SIZE 32768

queue_t queue;
queue_t running;
queue_t main_queue;
queue_t zombies;
queue_t blocked;

struct uthread{
	uthread_t tid;
	uthread_ctx_t* context;
	char* stack;
	uthread_t tid_child;
	int retval;
};

/* Global var
 * tid_idx = tid of the next thread we create
 * If 0, then the library has not yet been initialized
 */
uthread_t tid_idx = 0;

/* UTILITY FUCTIONS */
/* Return tid of currently running thread */
uthread_t uthread_self(void)
{
	void* curr;
	uthread_t tid;
	
	if (queue_length(running) == 0) return 0;
	preempt_disable();
	queue_dequeue(running, &curr);
	queue_enqueue(running, curr);
	preempt_enable();	
	tid = ((struct uthread*)curr)->tid;
	
	return tid;

}

/* Check two threads are equal */
int find_tid(void *data, void *arg)
{
	struct uthread* thread = (struct uthread*)data;
	if (thread->tid == *(uthread_t*)arg){
		return 1;
	}
	return 0;
}

/* Check if one thread is the child of another */
int block_tid(void *data, void *arg)
{
	struct uthread* thread = (struct uthread*)data;
	if (thread->tid_child == *(uthread_t*)arg){
		return 1;
	}
	return 0;
}

/* Check if current thread has finished running ie is a zombie */
int check_thread_done(uthread_t tid)
{
	int done = 1;
	void* data;
	/* Safe guarding queue checking and modification*/
	preempt_disable();
	for(int i = 0; i < queue_length(queue); i++) {
		queue_dequeue(queue, &data);
		if (((struct uthread*)data)->tid == tid) done = 0;
		queue_enqueue(queue,data);
	}
	
	for(int i = 0; i < queue_length(blocked); i++) {
		queue_dequeue(blocked, &data);
		if (((struct uthread*)data)->tid == tid) done = 0;
		queue_enqueue(blocked,data);
	}
	preempt_enable();
	return done;
}

/* INITIALIZERS */
/* Creates all the needed queues and main thread, starts preemption */
int create_main()
{
	/* Creating queues */
	queue = queue_create();
	running = queue_create();
	main_queue = queue_create();
	zombies = queue_create();
	blocked = queue_create();

	/* Starting preemption */
	preempt_start();
	
	/* Init main thread */
	uthread_ctx_t* uctx = (uthread_ctx_t*)malloc(sizeof(uthread_ctx_t));
	struct uthread* thread = (struct uthread*)malloc(sizeof(struct uthread));
	if (getcontext(uctx)){
		return -1;
	}
	thread->context = uctx;
	thread->tid = tid_idx;
	thread->stack = uthread_ctx_alloc_stack();

	tid_idx++;
	/* Safe guarding queue modification*/
	preempt_disable();
	queue_enqueue(main_queue, thread);
	preempt_enable();	
	return 0;
}

/* Create a new thread given function for thread and its argument */
int uthread_create(uthread_func_t func, void *arg)
{
	/* Create main thread if the next tid = 0 */
	if (tid_idx == 0){
		create_main();
	}
	/* Safe guarding queue modification*/
	preempt_disable();
	/* Otherwise, initilize a new, basic thread and enqueue to ready queue */
	int retval;
	void* stack = uthread_ctx_alloc_stack();
	uthread_ctx_t* uctx = (uthread_ctx_t*)malloc(sizeof(uthread_ctx_t));
	retval = uthread_ctx_init(uctx, stack, func, NULL);
	if (retval !=0){
		return -1;
	}	
	struct uthread* thread = (struct uthread*)malloc(sizeof(struct uthread));

	thread->tid = tid_idx;
	thread->context = uctx;
	thread->stack = stack;
	thread->tid_child = 0;
	tid_idx++;
	queue_enqueue(queue, thread);
	preempt_enable();
	return thread->tid;
}

/* EXIT THREAD */
/* Run the next thread given the currently running thread
 * ONLY used by exit
 * Needed because yield() removes the next thread in running, which would 
 * throw away the context data of the currently running thread
 * Instead, we use the current thread to context switch here
 */
void run_next_thread(void** curr) 
{
	void *data;
	
	if(queue_length(queue) == 0) return;
	/* Safe guarding queue modification*/
	preempt_disable();	
	queue_dequeue(queue, &data); //pop the next in line;
	queue_enqueue(running, data);
	preempt_enable();
	struct uthread* curr_t = (struct uthread*)(*curr);
	struct uthread* thread = (struct uthread*)data;
	uthread_ctx_switch(curr_t->context, thread->context);
}

/* Function to exit currently running thread
 * Remove thread from running, store in zombies, unblock parent, and 
 * run the next thread
 */
void uthread_exit(int retval)
{	
	/* Pull thread out of running and store */
	void* curr;
	void* parent;
	queue_dequeue(running, &curr);
	struct uthread* curr_t = (struct uthread*)curr;
	curr_t->retval = retval;
	/* Safe guarding queue modification*/
	preempt_disable();
	/* Store thread in zombies */
	queue_enqueue(zombies, (void*)curr_t);
	
	/* check if it is blocking by parent */	
	queue_iterate(blocked, block_tid , &curr_t->tid, &parent);

	if (parent != NULL){
		queue_enqueue(queue, parent);
	}
	preempt_enable();
	
	/* Run next thread */
	run_next_thread(&curr);
}

/* YEILD AND JOIN */
/* Yield current running thread and run the next available thread */
void uthread_yield(void)
{
	void* data;
	void* next;
	void* curr;
	
	/* No other process to run, so keep running current process */
	if(queue_length(queue) == 0){
		return;
	}
	/* Safe guarding queue modification*/
	preempt_disable();	
	/* Get next ready and currently running threads */
	queue_dequeue(queue, &next);
	queue_dequeue(running, &curr);
	struct uthread* curr_t = (struct uthread*)curr;
	struct uthread* next_t = (struct uthread*)next;

	/* Enqueue the next thread to run */
	queue_enqueue(running, (void*)next_t);
	
	/* Enqueue old running thread back in ready queue or main queue, if main */
	if (curr_t->tid != 0) { 
		queue_enqueue(queue, (void*)curr_t);
	} else { 
		queue_enqueue(main_queue, (void*)curr_t);	
	}
	preempt_enable();	
	/* Context switch */
	uthread_ctx_switch( curr_t->context, next_t->context);

}

/* Join the calling thread to thread with matching tid_child
 * This means that the calling thread is blocked from running until child
 * has finished
 * Caller gets unblocked via the uthread_exit() function 
 */
int uthread_join(uthread_t tid, int* retval)
{	
	/* Logic overview:
	 * Get all info about current running thread, that is the parent
	 * set parent state to blocked (1)
	 * loop where all threads in ready queue run
	 * break loop when child is not in ready or blocked queue
	 * if child is in zombies, retrieve return value
	 * then set parent status to ready (0)
	 */

	/* Return error if thread tries to join with main */
	if (tid == 0) return -1;
	 
	void* parent;
	void* next;
	/* Safe guarding queue modification*/
	preempt_disable();
	/* Set parent to parent thread, either running or main */
	if(queue_length(running) != 0) {
		queue_dequeue(running, &parent);
	} else {
		queue_dequeue(main_queue, &parent);
		queue_enqueue(main_queue, parent);
	}
	
	/* Set parent thread state to blocked */
	struct uthread* parent_t = (struct uthread*)parent;
	queue_enqueue(blocked, parent);
	parent_t->tid_child = tid;

	/* Check if child has finished executing */
	int is_child_done = check_thread_done(tid);		
	
	/* Run other threads until the child finishes and parent can begin */
	if(!is_child_done) {
	
		/* Get next ready thread */
		queue_dequeue(queue, &next);

		/* Run child */
		struct uthread* next_t = (struct uthread*)next;
		queue_enqueue(running, (void*)next_t);
		preempt_enable();
		/* Switch context to new */
		uthread_ctx_switch(parent_t->context, next_t->context);
	}
	preempt_enable();
	/* Get child and retval */
	void* child;
	queue_iterate(zombies, find_tid , &tid, &child);
	
	if (retval != NULL) *retval = (((struct uthread*)child)->retval);

	/* Delete from zombies and free memory of child */
	queue_delete(zombies, child);
	free(((struct uthread*)child)->context);
	uthread_ctx_destroy_stack(((struct uthread*)child)->stack);
	free((struct uthread*)child);
	
	return 0;
}
