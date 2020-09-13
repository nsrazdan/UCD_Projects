/* Simple shell for UNIX and LINUX machines similar to bash
 * Can run all commands predefined in /usr/bin folder
 * Supports standard bash piping 
 * Works by using fork() and exec() to clone and mutate processes
 */

/* C Standard Library header files */
#include <ctype.h>
#include <stdio.h>
#include <stdbool.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/stat.h>

/* Project header files */
#include <shell.h>
#include <command.h>

/* ERROR CHECKS */
/* check if directory already exists or if directory can't be opened */
bool check_dir_error(char** dir_name) {
	DIR* dir = opendir(*dir_name);
	
	/* dir exists, so no error */
	if(dir) {
		closedir(dir);
		return false;
	}
	
	/* dir doesn't exist, print error and quit */
	else if(ENOENT == errno) {
		fprintf(stderr,"Error: no such directory\n");
		free (*dir_name);
		return true;
	}
	
	/* some other error doesn't let dir open */
	else {
		fprintf(stderr, "Error: directory cannot be opened\n");
		free (*dir_name);
		return true;
	}
}

/* Check if more than 15 arguments for a given command */
bool check_arg_error(struct command* cur_cmd) {
	if (cur_cmd->num_args >= 16){
		fprintf(stderr,"Error: too many process arguments\n");
		return true;
	}
	
	return false;
}

/* Check if inputted command is valid */
bool check_valid_command_error(struct shell* sshell, struct command* cur_cmd) {
	for(int i = 0; i < sshell->num_valid_commands; i++) {
		if (strstr(sshell->valid_commands[i], cur_cmd->cmd) != NULL) {
			return false;
		}
	}
	
	fprintf(stderr,"Error: command not found\n");
	return true;
}

/* Check if is dir */
bool check_dir(char** file_name, char* file_type) {
	
	struct stat sb;
	
	/* File exists */
	if (stat(*file_name, &sb) == 0 && S_ISDIR(sb.st_mode)) {
		/* File doesn't exist, make correct error msg, and print msg */
		char err_msg[256];
		strcpy(err_msg, "Error: cannot open");
		strcat(err_msg, file_type);
		strcat(err_msg, "file\n");
		fprintf(stderr, "%s", err_msg);
	
		return true;
	}
	
	return false;
}

/* Check if there is no file for command with redirection*/
bool check_no_file(char* file_name, char* file_type) {
	if (!file_name) {
		char err_msg[256];
		strcpy(err_msg, "Error: no");
		strcat(err_msg, file_type);
		strcat(err_msg, "file\n");
		fprintf(stderr, "%s", err_msg);
		
		return true;
	}

	while (*file_name != '\0') {
		if (!isspace((unsigned char) *file_name)) {
			return false;
		}
		file_name++;
	}
	
	char err_msg[256];
	strcpy(err_msg, "Error: no");
	strcat(err_msg, file_type);
	strcat(err_msg, "file\n");
	fprintf(stderr, "%s", err_msg);
			
	return true;
}
/* Check all errors before running command */
bool check_errors(struct shell* sshell, struct command* cur_cmd) {
	if (check_arg_error(cur_cmd) | 
		check_valid_command_error(sshell, cur_cmd)) {
		return true;
	}
	
	return false;
}

/* SHELL COMMANDS */
/* Check if the user seeks to exit shell */
bool check_exit(struct command* cur_cmd){
	/* If user seeks to exit shell, print exit message and return true */
	if (strcmp(cur_cmd->cmd, "exit") == 0) {
		fprintf(stderr, "Bye...\n");
		return true;
	} else {
		return false;
	}
}

/* Run Print Working Directory command */
bool pwd(struct command* cur_cmd){
	
	/* If user seeks to exit shell, print exit message and return true */
	if (strcmp(cur_cmd->cmd, "pwd") == 0) {
		size_t size = 256;
		while (1)
		{
			char *buffer = malloc (size);
			if (getcwd (buffer, size) == buffer){
				fprintf(stdout, "%s\n",buffer);	
				fprintf(stderr,"+ completed '%s' [%d]\n", cur_cmd->cmd, 0);			
				return buffer;
			}
			free (buffer);
			size *= 2;
		}
		return true;
	} else {
		return false;
	}
}

/* Run Change Directory command*/
bool cd(struct command* cur_cmd, char** user_cmd){
	
	if (strcmp(cur_cmd->cmd, "cd") == 0) {
		size_t size = 100;
		while (1)
		{
			char *buffer = malloc (size);
			char *new_dir = cur_cmd->args[0];
			if (getcwd (buffer, size) == buffer){
				strcat(buffer, "/");
				strcat(buffer, new_dir);
				chdir(buffer);
				
				if(check_dir_error(&buffer)) return true;
				
				fprintf(stderr,"+ completed '%s' [0]\n", *user_cmd);	
				return buffer;
			}
			free (buffer);
			size *= 2;
		}
		return true;
	} else {
		return false;
	}
}

/* READ, PARSE INPUT */
/* Read in line of user input and parse into command*/
void get_parse_user_input(int* MAX, struct command* cur_cmd, char** user_cmd) {
	int i = 0;
	char buf[*MAX];
	bool get_command = false;
	char delim[] = " ";
	cur_cmd->num_args = 0;
	/* Read in line from user deliminated by " " */

	fgets(buf, *MAX, stdin);
	
	/* Echoing command line for grading purposes */
	if (!isatty(STDIN_FILENO)) {
		printf("%s", buf);
		fflush(stdout);
	}
	
	
	/*Get rid of the extra new line at the end */
	char *newline = strchr( buf, '\n' );
	if (newline) {
		*newline = 0;
	}
	char *arg = strtok(buf, delim);

	/* Read in each word as arg and put in correct array in cur_cmd structint */
	cur_cmd->output_redirected = false;
	cur_cmd->input_redirected = false;
	
	while(arg != NULL)
	{	
		/* Search for piping character */
		char *output_ptr = strchr( arg, '>');
		char *input_ptr = strchr( arg, '<');
		
		/* If the current arg contains > or < then parse it or skip it. */
		if (output_ptr || input_ptr){
			
			if (output_ptr ) {
				if (strcmp(arg,">")!=0){
					/* move pointer forward to delete '>' */
					output_ptr++;
					
					if (strcmp(output_ptr,"") !=0){
						
						/* If there is any string after > 
						 * then we store it as file
						 */
						cur_cmd->file = malloc(strlen(arg)* sizeof(char*));
						strcpy(cur_cmd->file,output_ptr);
					}
					/* Move pointer Backward to delete '<' */
					output_ptr--;
					
					if (strcmp(output_ptr,"") !=0){
						*output_ptr = '\0';
						
						/* If there is any string before < 
						 * then we store it as either argument or cmd
						 */
						if(get_command == false){
							cur_cmd->cmd = malloc(strlen(arg)* sizeof(char*));
							strcpy(cur_cmd->cmd, arg);
							get_command = true;
						}
						else{
							strcpy(cur_cmd->args[cur_cmd->num_args], arg);
							cur_cmd->num_args++;
						}
					}
				}
				cur_cmd->output_redirected = true;
			}
			if (input_ptr ) {
				if( strcmp(arg,"<")!=0){
					if (strcmp(input_ptr,"") !=0){
						/* If there is any string after >
						 * then we store it as file
						 */
						cur_cmd->file = malloc(strlen(arg)* sizeof(char*));
						*input_ptr = '\0';
						input_ptr++;
						strcpy(cur_cmd->file,input_ptr);	
					}
					/* move pointer Backward to delete '<' */
					input_ptr--;
					
					if (strcmp(input_ptr, "") !=0 ){
						*input_ptr = '\0';
						
						/* If we have not get command then get command */
						if(get_command == false){
							cur_cmd->cmd = malloc(strlen(arg)* sizeof(char*));
							strcpy(cur_cmd->cmd, arg);
							get_command = true;
						}
						
						/* Otherwise get argument */
						else{
							strcpy(cur_cmd->args[cur_cmd->num_args], arg);
							cur_cmd->num_args++;
						}
					}
				}
				cur_cmd->input_redirected = true;

			}
		}
		/* Get command if first token read, 
		 * as all valid calls start with * a command 
		 * Get args (all words read in past the first) 
		 */
		else{
			if(get_command == false){
				cur_cmd->cmd = malloc(strlen(arg)* sizeof(char*));
				strcpy(cur_cmd->cmd, arg);
				get_command = true;
				
			}
			else if(cur_cmd->output_redirected|| cur_cmd->input_redirected){
				cur_cmd->file = malloc(strlen(arg)* sizeof(char*));
				strcpy(cur_cmd->file,arg);
			}		
			else{
				strcpy(cur_cmd->args[cur_cmd->num_args], arg);
				cur_cmd->num_args++;
				
			}
		}
		arg = strtok(NULL, delim);
	}
	
	/* Append all the command back together as user_cmd */
    strcpy(*user_cmd, cur_cmd->cmd);
    for (i= 0; i < cur_cmd->num_args; i++){
        strcat(*user_cmd, " ");
        strcat(*user_cmd,cur_cmd->args[i]);
    }
	
}

/* REDIRECTION */
/* Open file for input redirection */
void input_redirect(struct command* cur_cmd){
	size_t size = 100;
	char *path = malloc (size);				
	
	/* Close STDIN to use file as input*/
	close(STDIN_FILENO);
	
	/* Getting path for input file and replacing STDIN with input file*/
	getcwd (path, size);
	strcat(path, "/"); 
	strcat(path,cur_cmd->file); 
	open(path, O_RDWR);
	
	getcwd(path, size);	
}

/* Open file for output redirection */
void output_redirect(struct command* cur_cmd){
	size_t size = 100;
	char *path = malloc (size);
	
	/* Close STDOUT to use file as input*/
	close(STDOUT_FILENO);
	
	/* Getting path for output file and replacing STDOUT with output file*/
	getcwd (path, size);
	strcat(path, "/"); 
	strcat(path,cur_cmd->file); 
	open(path, O_RDWR|O_CREAT, 0666);
	
	getcwd (path, size);	
}

/* RUN LOOP, RUN PROCESSES */
void sigint_handler(int signum)
{
	printf("Let's resume!\n");
}

/* high-level handle terminal display, input parsing, and running processes */
bool run_loop(struct shell* sshell, struct command* cur_cmd, char** user_cmd){
	int MAX = 256;
	bool error = false;
	int retval;
	size_t pid;
	int status;
	
	/* Dynamically allocate memory for:
	 * cur_cmd->args (array of strings to hold arguments of command)
	 * user_cmd (pointer to string for user input)
	 */
	*user_cmd = malloc(MAX * sizeof(char));
	cur_cmd->args = malloc(MAX * sizeof(char*));
	for(int i = 0; i < MAX; i++) {
		cur_cmd->args[i] = malloc(MAX * sizeof(char));
	}
	
	/* Get user input, parse into structs, and check if errors input */
	get_parse_user_input(&MAX, cur_cmd, user_cmd);
	error = check_errors(sshell, cur_cmd);
	
	/* Check if redirection file is valid, if redirection file is used */
	if (cur_cmd->input_redirected) {
		error = (check_dir(&cur_cmd->file, " input ") | 
			check_no_file(cur_cmd->file, " input "));
	} else if(cur_cmd->output_redirected) {
		error = (check_dir(&cur_cmd->file, " output ") |
			check_no_file(cur_cmd->file, " output "));
	}
	
	/* Check user input and run Shell process of exit if user seeks to exit*/
	if (check_exit(cur_cmd)) return true;
	
	/* Run process */
	if (!error){
		
		/* Run Shell processes of pwd and cd*/
		if (pwd(cur_cmd)) return false;
		if (cd(cur_cmd,user_cmd)) return false;
		
		/* Init exec_args array of strings to match execvp format:
		 * exec_args[0] = command to be executed
		 * exec_args[1:length - 1] = args of command to executed
		 * exec_args[length] = NULL
		 */
		char* exec_args[cur_cmd->num_args + 2];
		int i = 0;

		exec_args[0] = cur_cmd->cmd;
		for(i = 0; i < cur_cmd->num_args; i++) {
			exec_args[i + 1] = cur_cmd->args[i];
		}
		exec_args[i+1] = NULL;
	
		/* Run process as fork */
		pid=fork();
		
		if (pid  == 0){
			/* Child
			 * Run process and get return value for shell printing
			 */
			signal(SIGINT, sigint_handler);
			//pause();
			if (cur_cmd->output_redirected){
				output_redirect(cur_cmd);
			}
			else if(cur_cmd->input_redirected){
				input_redirect(cur_cmd);
			}

			retval = execvp(exec_args[0], exec_args);
	
			printf("%d\n",retval);
			exit(retval);
		}
		else if(pid > 0){
			/* Parent
			 * Wait for child to complete
			 */	
			waitpid(-1, &status, 0);
			fprintf(stderr,"+ completed '%s' [%d]\n", *user_cmd, status);
		}
		else{
			/* If not child or parent, then must be error */
			perror("fork");
			exit(1);
		}
	}
	return false;
}

/* FREE ALLOCATED MEMORY */
/* free all dynamically allocated memory */
void clean_up(struct shell* sshell, struct command* cur_cmd, char** user_cmd) {
	const int MAX = 256;
	
	for(int i = 0; i < MAX; i++) {
		free(cur_cmd->args[i]);
	}
	free(cur_cmd->args);
	free(*user_cmd);
	
	free(sshell->valid_commands);
}

/* INIT STRUCT VALUES & HANDLE SHELL */
/* Initialize struct values */
void struct_init(struct shell* sshell, struct command* cur_cmd) {
	char* valid_commands[] = {"cat", "cd", "clear", "cp", "date", "echo", 
	"exit", "gcc", "gdb", "gedit", "git", "grep", "g++", "ls", "make", "mkdir",
	"mv", "pwd", "rm", "rmdir", "sleep", "touch", "vim", "wc"};
	
	sshell->user_done = false;
	sshell->num_valid_commands = sizeof(valid_commands) / 
		sizeof(valid_commands[0]);
	
	/* Allocate memory for array of valid command strings */
	sshell->valid_commands = malloc(sshell->num_valid_commands * sizeof(char*));
		
	for(int i = 0; i < sshell->num_valid_commands; i++) {
		sshell->valid_commands[i] = malloc(sizeof(valid_commands[i]) * 
			sizeof(char));
		sshell->valid_commands[i] = valid_commands[i];
	}
	
	cur_cmd->file = NULL;
}

/* main function to begin terminal loop and handle exiting of loop */
int main(int argc, char *argv[]){
	/* initialize shell, command structs, and user input string */
	struct shell sshell;
	struct command cur_cmd;
	struct_init(&sshell, &cur_cmd);
	char* user_cmd;
	/*
	 * Run loop of displaying terminal, parsing input, and handling input while
	 * user has not exited terminal
	 */
	while(!sshell.user_done){
		printf("sshell$ ");
		sshell.user_done = run_loop(&sshell,&cur_cmd, &user_cmd);
	}
	
	clean_up(&sshell, &cur_cmd, &user_cmd);
	return 0;
}

