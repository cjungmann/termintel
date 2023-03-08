TARGET = libtermintel

PREFIX ?= /usr/local

DEBUG=0
ifeq ($(DEBUG),1)
	DEBUG_FLAGS := -ggdb
endif

CFLAGS = -Wall -Werror -std=c99 -pedantic $(DEBUG_FLAGS)
O_CFLAGS = $(CFLAGS) -fPIC

# List of object files needed for building library
LIB_OBJECTS := $(addsuffix .o,$(basename $(wildcard sl_*.c)))
# Create lists of generated files
EXECUTABLES := $(basename $(wildcard *.c))

###### RULES #######

all: $(TARGET).so $(TARGET).a

$(TARGET).so: $(LIB_OBJECTS)
	$(CC) $(O_CFLAGS) --shared -o $@ $(LIB_OBJECTS)

$(TARGET).a: $(LIB_OBJECTS)
	ar rcs $@ $(LIB_OBJECTS)

sl_%.o : sl_%.c
	$(CC) $(O_CFLAGS) -c -o $@ $<

.PHONY: install
install:
	install -D --mode=755 $(TARGET).so $(PREFIX)/lib
	install -D --mode=755 $(TARGET).a  $(PREFIX)/lib
	install -D --mode=644 termintel.h  $(PREFIX)/include
	install -D --mode=755 ti_create_capset_code.sh $(PREFIX)/bin
	ldconfig $(PREFIX)/lib

.PHONY: uninstall
uninstall:
	rm -f $(PREFIX)/bin/ti_create_capset_code.sh
	rm -f $(PREFIX)/include/$(TARGET).h
	rm -f $(PREFIX)/lib/$(TARGET).a
	rm -f $(PREFIX)/lib/$(TARGET).so
	ldconfig $(PREFIX)/lib

.PHONY: report
report:
	@echo $(LIB_OBJECTS)
	@echo $(EXECUTABLES)
	@echo "Library Path is " $(LIBRARY_PATH)
	@echo "PREFIX is " $(PREFIX)

.PHONY: clean
clean:
	rm -f $(LIB_OBJECTS)
	rm -f $(EXECUTABLES)
	rm -f $(TARGET).so $(TARGET).a

.PHONY: help
help:
	@echo "make                      to generate outdated files."
	@echo "make install              to install libraries and header file."
	@echo "make uninstall            to delete libraries and header file."
	@echo "make clean                to remove all generated files."
	@echo "make help                 this display."
	@echo "make report               debugging display of derived file lists."
	@echo
	@echo "make PREFIX=/usr install  to install files under /usr/lib and /usr/include"
	@echo "make DEBUG=1              to compile with -ggdb debugging option"
