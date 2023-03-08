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



##################################################
# Generate capset source files from capset lists #
##################################################

# Build list of source and header files generated from capset textfiles:
CAPSET_SOURCE_BASES := $(addprefix ti_,$(basename $(wildcard capset_*.txt)))
CAPSET_SOURCES := $(addsuffix .c,$(CAPSET_SOURCE_BASES))
CAPSET_SOURCES := $(CAPSET_SOURCES) $(addsuffix .h,$(CAPSET_SOURCE_BASES))

# Function that generates source (%.c) and header (%.h) files for a
# given capset_*.txt file
define extract_group =
	$(eval root = $(basename $(1)))
	$(eval sname != echo $(subst capset_,,$(root)) | tr [:lower:] [:upper:] )
	./ti_process_capset.sh -i $(1) -n -d -o ti_$(addsuffix .c,$(root)) -s $(sname) -t 1
	./ti_process_capset.sh -i $(1) -n -d -o ti_$(addsuffix .h,$(root)) -s $(sname) -t 2
endef

###### RULES #######

all: capset_files $(TARGET).so $(TARGET).a

# Generate intermediate files through out-of-date prerequisites
.PHONY: capset_files
capset_files: $(addsuffix .c,$(CAPSET_SOURCE_BASES))

$(TARGET).so: $(LIB_OBJECTS)
	$(CC) $(O_CFLAGS) --shared -o $@ $(LIB_OBJECTS)

$(TARGET).a: $(LIB_OBJECTS)
	ar rcs $@ $(LIB_OBJECTS)

# extract_group generates both .c and .h files, so .c targets are enough:
ti_capset_%.c: capset_%.txt
	$(call extract_group,$<)

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
	@echo $(CAPSET_SOURCES)
	@echo "Library Path is " $(LIBRARY_PATH)
	@echo "PREFIX is " $(PREFIX)

.PHONY: clean
clean:
	rm -f $(LIB_OBJECTS)
	rm -f $(EXECUTABLES)
	rm -f $(CAPSET_SOURCES)
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
