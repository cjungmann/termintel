
all: ti_capset_control.c ti_capset_control.h ti_capset_keys.c ti_capset_keys.h ti_capset_modes.c ti_capset_modes.h


ti_capset_control.c: capset_control.txt
	./ti_process_capset.sh -i capset_control.txt -t 1 -o ti_capset_control.c -s CTRL
ti_capset_control.h: capset_control.txt
	./ti_process_capset.sh -i capset_control.txt -t 2 -o ti_capset_control.h -s CTRL

ti_capset_keys.c: capset_keys.txt
	./ti_process_capset.sh -i capset_keys.txt -t 1 -o ti_capset_keys.c -s KEYS
ti_capset_keys.h: capset_keys.txt
	./ti_process_capset.sh -i capset_keys.txt -t 2 -o ti_capset_keys.h -s KEYS

ti_capset_modes.c: capset_modes.txt
	./ti_process_capset.sh -i capset_modes.txt -t 1 -o ti_capset_modes.c -s MODES
ti_capset_modes.h: capset_modes.txt
	./ti_process_capset.sh -i capset_modes.txt -t 2 -o ti_capset_modes.h -s MODES


