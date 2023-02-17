# TERMINFO REPORT

While not exactly obscured, the concepts and techniques of using
**terminfo** are usually buried in established code and not
discussed.  In trying to understand what is going on, I'm going to
use the document to make a record of what I learn and where I learned
it.

## TERMINFO DATABASES

There are documents supporting a great number of terminals, each one
being a collection of names and character sequences that report or
control the terminal.

The databases are located under directory */usr/lib/terminfo*,
which contains subdirectories with single-character names that
contain the terminal databases that start with that letter.

For example, terminal type *xterm-256color* is found under
*/use/lib/terminfo/x*.

## SCRIPT ti_comp

This Bash script consolidates data from three sources to create
a reference of terminfo capabilities on the current terminal.

A capability record contains the following fields:
1. The name of the capability
2. The terminfo name used by the capability to access the
3. The legacy two-character termcap code use to access the
   capability
4. A descriptive string for the capability, often including
   instructions for its use
5. The escape sequence used to recognize keys or initiate
   an action

### ti_comp Usage Hint

The descriptive string is colored to make it easier to
distinguish from the escape sequence that immediately follows
it.  Either or both strings may be very long, so they must be
run together, making it hard to scan.

The long list of capabilities suggests using **less** or another
pager to view the contents.  The use of color will likely make
**less** produce a confusing screen.  Use the **-r** option
(raw control characters) to embedded escape sequences.

For example: 

`./ti_cont | less -r`

## FACTOIDS

Random interesting things I learned while trying to determine terminfo
best practices, which are thinly if at all documented.

### write() vs tputs()

The use of `tputs` is strongly recommended by the `terminfo`
documentation.

As far as I can tell, the main advantage of using `tputs` over `write`
is that `tputs` is designed to implement delays to accommodate line
speed limitations. (Search for *tputs.c*, this file is found in many
repositories).

## REFERENCES

- The [terminfo wiki][wiki] is a small but useful source of
  information.

- Look at **infocmp**(5), a tool for examining a terminfo
  database.

- Other terminfo names are somewhat obvious, user7 (u7) containing
  the Cursor Position Report (cpr) is not.  An explicit reference
  is found online in [Terminfo source code file][terminfo_src].
  A local man file, user_caps(5) references u6 - u9 as a set of
  variables that includes CPR.

- Navigate to this [XCurses TermInfo page][opengroup] for a
  list of Terminfo names and explanations.

- If using **ioctl**, refer to **ioctl_tty**(2), particularly
  for TIOCGWINSZ, which may be the best way to get console dimensions.

- Include file references (*/usr/include/*)
  Study these files for reference, but follow the coding advice
  contained within: include **<termios.h** to include these files.
  - **/usr/include/bits/termios-struct.h** for the isolated structure definition.
  - **/usr/include/bits/termios-c_iflag.h** for *input mode* flags
  - **/usr/include/bits/termios-c_oflag.h** for *output mode* flags
  - **/usr/include/bits/termios-c_cflag.h** for *control mode* flags
  - **/usr/include/bits/termios-c_lflag.h** for *local mode* flags
  - **/usr/include/bits/termios-c_cc.h** for *special characters**







[wiki]:      https://en.wikipedia.org/wiki/Terminfo
[opengroup]: https://pubs.opengroup.org/onlinepubs/7908799/xcurses/terminfo.html#tag_002_001_003
[terminfo_src]: https://invisible-island.net/ncurses/terminfo.src.html#toc-_T_E_R_M_I_N_A_L__T_Y_P_E__D_E_S_C_R_I_P_T_I_O_N_S__S_O_U_R_C_E__F_I_L_E