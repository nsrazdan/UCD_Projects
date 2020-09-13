#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <queue.h>
#include <uthread.h>


void test_create(void)
{
	queue_t q;

	q = queue_create();
	assert(q != NULL);
	assert(queue_length(q) == 0);
}



void test_queue_simple(void)
{
    queue_t q;
    int data = 3, *ptr;
    q = queue_create();
    queue_enqueue(q, &data);
    queue_dequeue(q, (void**)&ptr);
    assert(ptr == &data);
}

/*print and find 7 , Stop when found*/
int print(void *data, void *arg)
{
	if (*(int*)data == 7){
		return 1;
	}
	return 0;

}

void test_queue_iterate(void)
{
	/* find object 7 */
	queue_t q;
	int data = 3, data2 = 7, data3 = 9, *ptr;
	
	queue_func_t print_ptr = &print;
	
	q = queue_create();
	queue_enqueue(q, &data);
	queue_enqueue(q, &data2);
	queue_enqueue(q, &data3);
	queue_iterate(q, *print_ptr, NULL,(void**)&ptr);
	assert(ptr == &data2);
	assert(queue_length(q) == 3);
	
}

void test_queue_delete(void)
{
	/* delete number 2 */
	queue_t q;
	int data = 3,data2=6,data3=9, *ptr;
	int r;

	q = queue_create();
	queue_enqueue(q, &data);
	queue_enqueue(q, &data2);
	queue_enqueue(q, &data3);
	queue_delete(q, &data);
	queue_dequeue(q, (void**)&ptr);
	assert(ptr == &data2);
	assert(queue_length(q) == 1);
	r = queue_destroy(q);
	assert(r == -1);
	
}

/*Test queue when there is error involved */ 
void test_queue_error(void)
{
	queue_t q;
	int  *data_null= NULL, *ptr, r;
	queue_func_t print_ptr = &print;
	queue_func_t null_ptr = NULL;
	q = NULL;
	/* get queue length when q is NULL */
	assert(queue_length(q) == -1);
	/* enqueue with null queue */
	r = queue_enqueue(q, &data_null);
	assert(r == -1);
	/* dequeue with null queue */
	r = queue_dequeue(q, (void**)&data_null);
	assert(r == -1);
	/* delete null data */
	r = queue_delete(q, &data_null);
	assert(r == -1);
	/* delete null queue */
	r = queue_destroy(q);
	assert(r == -1);
	q = queue_create();
	/* enqueue with null data */
	r = queue_enqueue(q, data_null);
	assert(r == -1);
	/* dequeue without anything */
    	r = queue_dequeue(q, (void**)&ptr);
	assert(r == -1);
	/* iterate with null queue and null data */
	r = queue_iterate(q, null_ptr, NULL,(void**)&ptr);
	assert(r == -1);
	r = queue_iterate(NULL, *print_ptr, NULL,(void**)&ptr);
	assert(r == -1);

}

int main(void)
{
	test_create();
	test_queue_simple();
	test_queue_error();
	test_queue_delete();
	test_queue_iterate();
	return 0;
}
