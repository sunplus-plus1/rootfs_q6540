# Makefile for compiling the key detection program

# Compiler
CC = $(CROSS)gcc
STRIP = $(CROSS)strip
# Compiler flags
CFLAGS ?= -Wall -Wextra -O2 -static

# Target executable
TARGET = adckey

# Source files
SRCS = adckey.c

# Default rule
all: $(TARGET)

# Rule to build the target executable
$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)
	$(STRIP) $(TARGET)

# Clean up build files
clean:
	rm -f $(TARGET)

# Install the binary to /usr/bin
install: $(TARGET)
	install -m 0755 $(TARGET) $(ROOTFS_DIR)/usr/bin/

# Uninstall the binary from /usr/bin
uninstall:
	rm -f $(ROOTFS_DIR)/usr/bin/$(TARGET)

.PHONY: all clean install uninstall
