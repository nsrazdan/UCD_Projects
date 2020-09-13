HDIR = headers
ODIR = objects

CC = gcc
CFLAGS = -Wall -Werror -I$(HDIR)

_DEPS = shell.h command.h
DEPS = $(patsubst %, $(HDIR)/%, $(_DEPS))

_OBJ = sshell.o
OBJ = $(patsubst %, $(ODIR)/%, $(_OBJ))

$(ODIR)/%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)
	
sshell: $(OBJ)
	$(CC) -o $@ $^ $(CFLAGS)

.PHONY: clean

clean:
	rm -f $(OBJ)/*.o sshell core
