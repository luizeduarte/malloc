# Compiler and linker options
CC = gcc
AS = as
LD = ld

# Source files
AS_SRC = malloc.s
C_SRC = main.c

# Object files
AS_OBJ = $(AS_SRC:.s=.o)
C_OBJ = $(C_SRC:.c=.o)

# Executable name
TARGET = my_program

# Default target
all: $(TARGET)

# Compile assembly source file to object file
$(AS_OBJ): $(AS_SRC)
	$(AS) -o $@ $<

# Compile C source file to object file
$(C_OBJ): $(C_SRC)
	$(CC) -c -o $@ $<

# Link object files to create the executable
$(TARGET): $(AS_OBJ) $(C_OBJ)
	$(LD) -o $@ $^

# Clean up object files and the executable
clean:
	rm -f $(AS_OBJ) $(C_OBJ) $(TARGET)

.PHONY: all clean

