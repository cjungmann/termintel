all: capset_files

.PHONY: capset_files
capset_files: ti_capset_control.c ti_capset_keys.c ti_capset_modes.c

# Function that generates source (%.c) and header (%.h) files for a
# given capset_*.txt file
define extract_group =
	$(eval root = $(basename $(1)))
	$(eval sname != echo $(subst capset_,,$(root)) | tr [:lower:] [:upper:] )
	./ti_process_capset.sh -i $(1) -o ti_$(addsuffix .c,$(root)) -s $(sname) -t 1
	./ti_process_capset.sh -i $(1) -o ti_$(addsuffix .h,$(root)) -s $(sname) -t 2
endef

ti_capset_%.c: capset_%.txt
	$(call extract_group,$<)



