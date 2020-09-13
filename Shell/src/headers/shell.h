/* include guard for SHELL_H */
#ifndef SHELL_H
#define SHELL_H

/* Struct representing the entire shell program run by the user
 * Stores all info relating to the handling of the shell
 * Included by SSHELL_C
 */
 
#include <command.h>

struct shell{
	struct command* processes;

	int num_cmd;
	char** valid_commands;
	int num_valid_commands;
	bool user_done;
};

#endif /* SHELL_H */
