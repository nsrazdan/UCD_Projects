/* include guard for COMMAND_H */
#ifndef COMMAND_H
#define COMMAND_H

/* Struct representing a single user-inputted command
 * Stores all high-level info relating to the command to allow easy execution
 * Included by SHELL_H and SSHELL_C
 */

struct command{
	char* cmd;
	char** args;
	int num_args;
	char* file;
	bool input_redirected;
	bool output_redirected;
};

#endif /* COMMAND_H */
