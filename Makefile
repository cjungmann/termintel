
all: ti_capset_control.inc ti_capset_keys.inc ti_capset_modes.inc


ti_capset_control.inc:
	./ti_script_process_capset -i capset_control.txt -o ti_capset_control.inc -s CTRL

ti_capset_keys.inc:
	./ti_script_process_capset -i capset_keys.txt -o ti_capset_keys.inc -s KEYS

ti_capset_modes.inc:
	./ti_script_process_capset -i capset_modes.txt -o ti_capset_modes.inc -s MODES

