# The compiler to use
CC ?= cc

# Compiler flags
CFLAGS ?= -Wall -Wextra -std=c99

# The final executable name
TARGET := hello-world

# The directory for all build files (objects, executables)
BUILDDIR := build

# Source files
SRCS := main.c

# Object files are placed in the build directory
OBJS := $(patsubst %.c,$(BUILDDIR)/%.o,$(SRCS))

# Default installation prefix
# Can be overridden from the command line, e.g., `make install PREFIX=/usr`
PREFIX ?= /usr/local


# The default target, which is executed when you just run `make`
all: $(BUILDDIR)/$(TARGET)


# Rule to link the final executable
# It depends on all the object files
$(BUILDDIR)/$(TARGET): $(OBJS)
	@echo "==> Linking..."
	@$(CC) $(LDFLAGS) -o $@ $^


# A pattern rule to compile .c files into .o files in the build directory
# The `| $(BUILDDIR)` is an "order-only prerequisite". It ensures the build
# directory is created before any compilation starts.
$(BUILDDIR)/%.o: %.c | $(BUILDDIR)
	@echo "==> Compiling $<..."
	@$(CC) $(CFLAGS) -c -o $@ $<


# Rule to create the build directory.
# This is triggered by the order-only prerequisite above.
$(BUILDDIR):
	@mkdir -p $@


# Target to install the executable to $(PREFIX)/bin
install: all
	@echo "==> Installing to $(PREFIX)/bin..."
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@install -m 755 $(BUILDDIR)/$(TARGET) $(DESTDIR)$(PREFIX)/bin


# Target to clean up all generated files
clean:
	@echo "==> Cleaning up..."
	@rm -rf $(BUILDDIR)


# Declare targets that are not actual files.
# This prevents `make` from getting confused if a file named 'clean' or 'install' exists.
.PHONY: all install clean
