# ECS 150 Simple Shell: Project Report
- By Nikhil Razdan & Linda Li
***
# Part I - Project Heirarchy
- To implement the shell, we designed a heirarchy of functions which add abstraction 
  and clarity to each step of the project.
- They function as follows (only major functions outlined below, not all):

```
main
│   initializes major vars used by all functions
│   handles the running of the shell loop exiting
│
└───run_loop
│   │   dynamically allocates memory for user input and calls relevant functions
│   │   calls function to checks if error in user input
│   │   runs both shell functions and /bin functions
│   │
│   └───get_parse_user_input
│   │   │   reads in user input and then parses into cmds, args, and pipes
│   │   │   stores all tokens in correct category in command structs
│   │ 
│   └───check_errors
│       │   check general errors in user input
│ 
└───clean_up
    │   cleans all dynamically allocated memory
```
- In addition we utilize two structs, the definitions of which are separated into header files:
  - `command`, which holds all the relevant data to execute a single, valid command
  - `shell`, which holds information about the shell and its execution, i.e. whether the user wishes to terminate the shell
***
# Part II - Parsing
- To parse the user input, we operate under a few assumptions:
  - The all valid commands and arguments will be separated by whitespace
  - Pipes and redirection characters do not necessarily have to be separated by whitespace from other fields
  - If a word is redirected into a valid command, it must be a file
- With these assumptions, we opted to parse in two passes.
- The first pass parses the input using whitespace as a delimiter, also removing the whitespace from the resultant strings.
  - For example, if our input was `sshell$ ls -la> file.txt`, the first pass will parse into strings `"ls", "-la>", "file.txt"`
- The second pass will parse the new strings using `">", "<", "|"` as delimiters.
  - This allows us to find where, if anywhere, redirection or piping occurs.
  - After this stage, our strings look like `"ls", "-la", "file.txt"`
- But how do we know if redirection or piping occurs if we remove the character in the strings?
  - This is solved by our `command` struct, which actually stores all the memory relevant to a single command.
  - In the above example, the current instance of `command` is holding `"ls"` in the `char* cmd` field, `-la`
    in `index 0` of the `char** args` field, and `file.txt` in `char* file`.
  - But there are few more fields in `command`, namely `bool output_redirected`, `bool input_redirected`, and
    `char* file`.
  - If, when we parse in our second pass, we run into a redirection symbol, we set the related boolean value
    to `true` and put the next string in the `char* file` field.
  - This is how we know if we have a redirected input or output.
  - In our current example, the current instance of `command` would have `output_redirected == 1` and `file == "file.txt"`.
- After this our instance of `command` has all the relevant data to execute the command, and thus the string is correctly parsed.
***
# Part III - Testing
- The majority of our testing was done by hand, by testing all major cases we could think of
  - For basic command execution, we tested every command with every argument slot full
  - For example, we tested ls by running:
    - `ls <valid_optional_args>`, `ls <valid_dir_name>`, `ls <valid_optional_args> <valid_dir_name>`, 
      `ls <invalid_optional_args> <valid_dir_name>`, `ls <valid_optional_args> <invalid_dir_name>`
  - For redirection, we tested by rediredirecting both a valid and invalid argument for both input and output 
    files for each command (4 tests total per command) 
  - Although these tests did not represent all possible command executions, they represent each general category,
    which is sufficient for a test done by hand.
- We also utilized the provided testing script, and used it to fix how our output was printed.
***
# Resources
  - For relearning the specifics of C and for general help, two sources were instrumental:
    - [The GNU C Reference Manual](https://www.gnu.org/software/gnu-c-manual/gnu-c-manual.html)
      was useful for understanding C Syntax and its implementation.
    - [CPlusPlus Reference](http://www.cplusplus.com/reference/) was useful when using C Standard libraries, 
      as they provide many useful examples not necessarily included by The GNU Manual.
  - For specific, essential functions used in this shell, the LINUX manuals were very helpful.
    - [EXEC Man Page](http://man7.org/linux/man-pages/man3/exec.3.html)
    - [EXECVE Man Page](http://man7.org/linux/man-pages/man2/execve.2.html)
    - [DUP2 Man Page](http://man7.org/linux/man-pages/man2/dup.2.html)
    - [All Other Man Pages](http://man7.org/linux/man-pages/dir_section_2.html)
