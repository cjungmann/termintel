# @file: Makefile

TARGET = target

# Overrideable path with recommended value as default:
PREFIX ?= /usr/local

CFLAGS = -Wall -Werror -std=c99 -pedantic
DEBUG=0
ifeq ($(DEBUG),1)
	CFLAGS += -ggdb
endif

LFLAGS = -ltinfo
STATIC_OUTPUT = 0
ifeq ($(STATIC_OUTPUT),1)
	LFLAGS += -l:libtermintel.a
else
	LFLAGS += -ltermintel
endif

# Function that generates source (%.c) and header (%.h) files for a
# given capset_*.txt file
define extract_group =
	$(eval root = $(basename $(1)))
	$(eval sname != echo $(subst capset_,,$(root)) | tr [:lower:] [:upper:] )
	ti_create_capset_code.sh -i $(1) -n -d -o ti_$(addsuffix .c,$(root)) -s $(sname) -t 1
	ti_create_capset_code.sh -i $(1) -n -d -o ti_$(addsuffix .h,$(root)) -s $(sname) -t 2
endef

CAPSET_SOURCES := $(addprefix ti_,$(addsuffix .c,$(basename $(wildcard *.txt))))
CAPSET_MODULES += $(addsuffix .o,$(basename $(CAPSET_SOURCES)))
SOURCE_MODULES := $(addsuffix .o,$(basename $(wildcard *.c)))
# Add without duplicates:
SOURCE_MODULES += $(filter-out $(SOURCE_MODULES),$(CAPSET_MODULES))

# Prevent intermediate capset_*.c files from being deleted:
.SECONDARY:

.PHONY: all
all: $(TARGET)

$(TARGET) : $(SOURCE_MODULES)
	$(CC) $(CFLAGS) -o $@ $(SOURCE_MODULES) $(LFLAGS)

%.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $<

ti_capset_%.c : capset_%.txt
	$(call extract_group,$<)

.PHONY: report
report:
	@echo "CAPSET_SOURCES are " $(CAPSET_SOURCES)
	@echo "CAPSET_MODULES are " $(CAPSET_MODULES)
	@echo "SOURCE MODULES are " $(SOURCE_MODULES)

.PHONY: clean
clean:
	rm -f $(CAPSET_SOURCES)
	rm -f $(SOURCE_MODULES)
	rm -f $(TARGET)

.PHONY: install
install:
	install -D --mode=755 $(TARGET) $(PREFIX)/bin/$(TARGET)

.PHONY: uninstall
uninstall:
	rm -f $(PREFIX)/bin/$(TARGET)

.PHONY: help
help:
	@echo "make                     build project"
	@echo "make install             copy executable to appropriate /bin directory."
	@echo "make uninstall           copy executable from /bin directory."
	@echo "make report              show debugging display of derived file names"
	@echo "make clean               delete generated files"
	@echo
	@echo "Changing default settings:"
	@echo "make STATIC_OUTPUT=1     build using static termintel library"
	@echo "                         default value 0 (for shared object library)."
	@echo "make PREFIX=/usr         Install/uninstall from \"/usr/bin\" directory."
	@echo "                         Default value is \"/usr/local\"."
	@echo "make DEBUG=1             Compile with -ggdb option on"

