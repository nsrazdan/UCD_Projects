#include <signal.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>

#include "preempt.h"
#include "uthread.h"

/*
 * Frequency of preemption
 * 100Hz is 100 times per second
 * 0.01 seconds, or 10,000 milliseconds is T, period
 */
 
#define HZ 100
#define T 10000

/* Yield to new thread */
void timer_handler(int signum) {
	uthread_yield();
}

/* Disable signal handler for timer */
void preempt_disable(void)
{
	struct sigaction sig;

	/* Set signal handler to ignore signal */
 	sig.sa_handler = SIG_IGN;
 	sigaction(SIGVTALRM, &sig, NULL);
}

/* Enable signal handler for timer */
void preempt_enable(void)
{
	struct sigaction sig;

	/* Set signal handler to handle signal */
 	sig.sa_handler = &timer_handler;
 	sigaction(SIGVTALRM, &sig, NULL);
}

/* Create and enable timer and handler for timer, using SIGVTALRM signals */
void preempt_start(void)
{
	struct sigaction sig;
	struct itimerval timer;

	/* Set timer_handler as signal handler for timer */
 	sig.sa_handler = &timer_handler;
 	sigaction(SIGVTALRM, &sig, NULL);
 
	/* Set timer to raise alarm every time period elapses */
	timer.it_value.tv_sec = 0;
	timer.it_interval.tv_sec = 0;
	timer.it_value.tv_usec = T;
	timer.it_interval.tv_usec = T;
	
	setitimer(ITIMER_VIRTUAL, &timer, NULL);
}

