# @file: Makefile

# Overrideable path with recommended value as default:
PREFIX ?= /usr/local

# Overrideable static variable
STATIC_OUTPUT = 0

TARGET = first

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


# Setup compiling flags:
CFLAGS = -Wall -Werror -std=c99 -pedantic -ggdb
LFLAGS = -ltinfo
ifeq ($(STATIC_OUTPUT),1)
	LFLAGS += -l:libtermintel.a
else
	LFLAGS += -ltermintel
endif

CAPSET_SOURCES := $(addprefix ti_,$(addsuffix .c,$(basename $(wildcard *.txt))))
CAPSET_MODULES += $(addsuffix .o,$(basename $(CAPSET_SOURCES)))
SOURCE_MODULES := $(addsuffix .o,$(basename $(wildcard *.c)))
SOURCE_MODULES += $(filter-out $(SOURCE_MODULES),$(CAPSET_MODULES))

# Prevent intermediate capset_*.c files from being deleted:
.SECONDARY:

.PHONY: all
all: $(TARGET)

$(TARGET) : $(SOURCE_MODULES)
	# ld -o $@ $(SOURCE_MODULES) /lib/crt1.o -lc -ltinfo -Bstatic -ltermintel
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
	install -D --mode=75 $(TARGET) $(PREFIX)/bin/$(TARGET)

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

