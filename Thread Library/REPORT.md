# ECS 150 Simple Shell: Project Report
- By Nikhil Razdan & Linda Li
***
# Part I - Queue
- We implemented Queue as a doubly linked list to allow all operations apart 
from iterate and delete operation to be O(1).
- We have two struct implemented: Queue, and Node. Queue stores all the 
information related to the queue, such as head, tail, and length.

***
# Part II - Uthread
- We have five queues: queue, running, zombies, blocked, main_queue.
- We represent respectively different states of the thread: ready, running,
zombie, blocked. We have a special queue for main thread.
- We implemented a uthread struct. It contains tid, context, stack, tid_child 
and retval. tid_child stores the tid of the child that is blocking itself. 
Retval stores the return value of the thread.
- We passed the thread around in different states, which are implemented as 
different queues. 
- When we `yield`, we saves the context of the current thread, and dequeues
it from running, and enqueue it to queue, which is the ready state. Then, load
the next thread from (ready)queue.
- When we `join`, the child thread is granted CPU, and parent is pushed into 
`blocked`, saving the child tid in child_tid. 
- When a thread dies, the thread check whether its tid is someone's child_tid.
If yes, then we unblock the parent, and push it back to ready. if no, we exit,
saving our retval in our struct so our parent can collect later.

***
# Part III - Preemption
- Our preemption works through the `sigaction` function found in `signal.h`,
  and the `setitimer` function found in `sys/time.h`
- We define a signal handler `timer_handler` which simply calls `uthread_yield`
- We then define our signal handler function to be called when the *SIGVTALARM*
  flag is raised, using `sigaction`
- Our timer, set using `setitimer`, is set to raise the *SIGVTALARM* at 100Hz
- Thus, every 0.01 seconds, if preemption is not disabled, we will yield the
  currently running thread
- `preempt_{disable, enable}` work simply by overwritting the current signal
  handler with *SIG_IGN* or `timer_handler`, respectively.

***
# Part IV - Testing

- Our queue tester checks every situation in which the function might return 
with a negative 1, as well as all the functionality of the queue.
- Our yield tester checks that we are able to yield in a correct order, as well
block parent and unblock parent successfully.
- Our largest test case, which tests all our implementation 
  `preempt_{start, enable, disable}` and 
  `uthread_{yield, join, exit, create}`, is `test_preempt`

- This test case runs in 4 phases
1. **DEFAULT**, where the library and the main thread have been intialized, and
  two other normal threads have been intialized and are running with preemption
2. **DISABLED**, where the user has called `preempt_disable()` after running
  with the defult parameters
3. **ENABLED**, where the user has reenabled preempt by calling 
  `preempt_enable()`
4. **EXITING**, where all the threads have terminated and we begin to free their
  memory and return to the main thread

- **Overview**
  - There are two functions in this program `huge` and `hello_world`
  - `huge` 
    - Runs a very long loop and prints every time the iterator variable
      reaches 5,000,000
    - In addition, it enables and disables preemption, begining
      phases 2 and 3, at specific times in our program
    - There is only 1 thread of `huge`, but it runs for the lifetime of the
      program
  - `hello_world`
    - Simply prints its tid and creates a new thread of `hello_world` and joins
      to it
    - This means that by the end of the program, we have about 50 threads of 
      `hello_world` in our program, all of which are joined to some other thread

- **DEFAULT**
  - In this phase, preemption is enabled with a frequency of 100 Hz
  - When running the program, you can clearly see this, as threads of both 
  `huge` and `hello_world` print to the terminal

- **DISABLED**
  - In this phase, preemption is disabled in the single thread of `huge`
  - Thus, `huge` is the only thread that runs and only prints to the terminal
  
- **ENABLED** 
  - In this phase, preemption is re-enabled and the current thread of 
    `hello_world`begins running again, creating more threads that take away from
    take away from the processor time of `huge` 
  
- **EXITING**
  - In this phase, `huge` breaks its loop, allowing for all threads to begin
    exiting
  - First, `huge` exits
  - Then all the `hello_world` threads exit, from highest to lowest tid, as
    they are all joined to each other
  - Finally, main exits
  - Notice how all memory of the children is freed, as there is no segfault
    when the program terminates
  - The freeing is handled by the parent, in `uthread_join`
  
- **Conclusion**
  - This program adequetely tests all of the functions of our implementation
  - All the major functions mentioned above are called 50+ times, and all
    engage in the predicted behavior

***
# Resources
- [GNU Manual for signal handling and blocking signals]
  (https://www.gnu.org/software/libc/manual/html_mono/libc.html#Signal-Actions)
- [LINUX Manual for signal handling]
  (http://man7.org/linux/man-pages/man2/sigaction.2.html)
- [GNU Manual for alarm]
  (https://www.gnu.org/software/libc/manual/html_mono/libc.html#Setting-an-Alarm)
- [Excerpt from book Advanced Linux Programming for alarm]
  (http://www.informit.com/articles/article.aspx?p=23618&seqNum=14)
- [tldp.com for makefile]
  (http://tldp.org/HOWTO/Program-Library-HOWTO/static-libraries.html)
