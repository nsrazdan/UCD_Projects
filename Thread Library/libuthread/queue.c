#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "queue.h"
#include "uthread.h"

/* individual node */
struct queue {
	struct node *head;
	struct node *tail;	
	int length;
};

struct node {
	struct node *next;
	struct node *prev;
	void *data;
};

/* Create new queue */
queue_t queue_create(void)
{
	queue_t queue = (queue_t)malloc(sizeof(queue_t));
	queue->length = 0;
	return queue;
}

/* Destroy a queue */
int queue_destroy(queue_t queue)
{
	if (queue == NULL || queue_length(queue)!=0 ){
		return -1;
	}
	free(queue);
	return 0;
}

/* Enqueue data, meaning push to back end of queue */
int queue_enqueue(queue_t queue, void *data)
{
	struct node* new_node = (struct node*)malloc(sizeof(struct node));
	
	if (queue == NULL || data == NULL || new_node == NULL){
		return -1;
	}
	new_node->data = data;
	new_node->next = NULL;
	/* If empty */
	if (queue->head == NULL){
		new_node->prev = NULL;
		queue->head = new_node;
	}
	else{/*if not empty */
		/*points to the head */
		struct node* curr_node = queue->tail;
		new_node->prev = curr_node;
		curr_node->next = new_node;	
	}
	queue->tail = new_node;
	queue->length = queue->length + 1;
	return 0;
}

/* Dequeue data, meaning pop next element in queue and move others up */
int queue_dequeue(queue_t queue, void **data)
{
	if (queue == NULL || queue->head == NULL || queue->head->data == NULL){
		return -1;
	}
	struct node* head = queue->head;
	*data =  head ->data;
	if (head->next == NULL){/* empty the queue */
		queue->head = NULL;
		queue->tail = NULL;
		queue->length = 0;
	}
	else{
		struct node* new_head = head->next;
		new_head->prev = NULL;
		queue->head = new_head;
		queue->length = queue->length - 1;
	}
	return 0;
	
}

/* Delete element with matching data from queue */
int queue_delete(queue_t queue, void *data)

{
	if (queue == NULL || data == NULL){
		return -1;
	}
	struct node* curr_node = queue->head;

	while(curr_node != NULL && curr_node->data != NULL){
		if (curr_node->data == data){
			/* Empty the queue*/
			if (curr_node->next ==NULL && curr_node->prev == NULL){
				queue->head = NULL;
				queue->tail = NULL;			
			}/* then we are deleting the head */
			else if (curr_node->next !=NULL && curr_node->prev == NULL){
				struct node* next = curr_node->next;
				next->prev = NULL;
				queue->head = next ;	
			}/* then we are deleting the tail */			
			else if (curr_node->prev != NULL && curr_node->next ==NULL){
				struct node* previous = curr_node->prev;
				previous->next =NULL;
				queue->tail = previous ;
			}
			else{ /* we are deleting the middle node*/
				struct node* next = curr_node->next;
				struct node* previous = curr_node->prev;				
				next->prev = previous;
				previous->next = next;
			}
			queue->length = queue->length - 1;
			return 1;
		} else {
			if(curr_node->next == NULL) return -1;
			curr_node = curr_node->next;
		}
	}
	return -1;
}

/*
 * queue_func_t - Queue callback function type
 * @data: Data item
 * @arg: Extra argument
 *
 * Return: 0 to continue iterating, 1 to stop iterating at this particular item.
 */


/*@data: (Optional) Address of data pointer where an item can be received*/
int queue_iterate(queue_t queue, queue_func_t func, void *arg, void **data)
{
	int stop = 0;

	if (queue == NULL || func == NULL)
	{
		return -1;
	}
	struct node* curr_node = queue->head;

	while(curr_node != NULL )
	{/* while not the end */
		stop = func(curr_node->data, arg);
		/* End Prematurely */
		if (stop == 1 )
		{
			if (curr_node->data != NULL){
				*data = curr_node->data;
				return 0;
			}
			return -1;
		}
		curr_node = curr_node->next;
	}
	*data = NULL;
	return -1;
}

/* Return length of queue */
int queue_length(queue_t queue)
{
	if (queue == NULL)
	{
		return -1;
	}
	return queue->length;
	
}

