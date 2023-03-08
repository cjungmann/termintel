# TermIntel Templates

The files in this directory can serve as a headstart in beginning
a new TermIntel project.

## SOURCE FILES

### main.c and main.h
These files implement a useful program entry point, taking care
of terminal setup and teardown, setting up signals to handle
unexpected termination gracefully (as far as the terminal goes).

The screen dimensions are retrieved during initialization and
stored in global variables, **g_swide** and **g_stall**, which
are made available to other modules through the **extern**
statements in **main.h**.

## CAPSET FILES

The capset txt files are processed by the default Makefile
to create capset source and header files.  The source file
will define an array of structs that will be initialized
with matching escape sequences, and may include additional
arrays of strings to define matching entry names and/or
descriptive texts.

The header file will include a coordinated *enum* statement
to define index values associated with the entries.  The
enum values can be used to invoke an entry to set a mode or
execute a control command, or to identify keystrokes with
an integer, which is more suitable for a `switch` statement.

Each of the capset text files consist of isolated commonly-useful
entries, followed by many commented-out entries that are
typically not needed by most applications.  Feel free to
adjust the lists according to the needs of your application.

### capset_keys.txt

This capset allows the program to identify specific
keypresses.  Use the **caps_KEYS** array with function
`TIV_find_index_by_sequence` after calling `ti_get_keypress`
to identify the action keystrokes.

### capset_control.txt

Contains terminal and other control entries.  Array
**caps_CONTROL** is the TIV array that can be used with one
of the `TIV_execute_???` functions.

### capset_modes.txt

Contains entries for changing several terminal modes.
Text display modes include to enter or exit underline mode, bold mode
or standout mode.  Terminal modes like keypad mode or cup mode
are used to prepare the terminal for a program using cursor
manipulation controls (from the **caps_CONTROL** array).

## BUILD FILES

This mainly means the **Makefile**.  Use the Makefile
template as a starting point for your own project.