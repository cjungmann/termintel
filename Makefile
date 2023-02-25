
# Create lists of generated files
EXECUTABLES := $(basename $(wildcard *.c))
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


all: capset_files

.PHONY: capset_files
capset_files: $(addsuffix .c,$(CAPSET_SOURCE_BASES))

# extract_group generates both .c and .h files, so .c targets are enough:
ti_capset_%.c: capset_%.txt
	$(call extract_group,$<)

.PHONY: report_lists
report_lists:
	@echo $(EXECUTABLES)
	@echo $(CAPSET_SOURCES)

.PHONY: clean
clean:
	rm -f $(EXECUTABLES)
	rm -f $(CAPSET_SOURCES)
