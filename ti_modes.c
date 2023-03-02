#include "sl_caps.h"
#include "ti_capset_modes.h"

#include <unistd.h>
#include <stdio.h>
#include <string.h>

void ti_set_mode(enum enum_MODES mode)
{
   if (mode>=0 && mode < MODES_END)
   {
      TIV *tiv = &caps_MODES[mode];
      if (tiv && tiv->sequence)
      {
         int len = strlen(tiv->sequence);
         write(STDIN_FILENO, tiv->sequence, len);
      }
   }
}

void ti_enter_ca_mode(void) { ti_set_mode(MODES_ENTER_CA_MODE); }
void ti_exit_ca_mode(void)  { ti_set_mode(MODES_EXIT_CA_MODE); }

void ti_enter_keypad_mode(void) { ti_set_mode(MODES_KEYPAD_XMIT); }
void ti_exit_keypad_mode(void)  { ti_set_mode(MODES_KEYPAD_LOCAL); }

void ti_enter_bold(void) { ti_set_mode(MODES_ENTER_BOLD_MODE); }
void ti_exit_bold(void)  { ti_set_mode(MODES_EXIT_ATTRIBUTE_MODE); }

void ti_enter_underline(void) { ti_set_mode(MODES_ENTER_UNDERLINE_MODE); }
void ti_exit_underline(void)  { ti_set_mode(MODES_EXIT_UNDERLINE_MODE); }

void ti_enter_standout_mode(void) { ti_set_mode(MODES_ENTER_STANDOUT_MODE); }
void ti_exit_standout_mode(void)  { ti_set_mode(MODES_EXIT_STANDOUT_MODE); }

void ti_enter_reverse_mode(void) { ti_set_mode(MODES_ENTER_REVERSE_MODE); }
void ti_exit_reverse_mode(void)  { ti_set_mode(MODES_EXIT_ATTRIBUTE_MODE); }

void ti_enter_blink_mode(void) { ti_set_mode(MODES_ENTER_BLINK_MODE); }
void ti_exit_blink_mode(void)  { ti_set_mode(MODES_EXIT_ATTRIBUTE_MODE); }

#ifdef TI_MODES_MAIN

#include "ti_capset_modes.c"

int main(int argc, const char **argv)
{
   printf("Nothing to see here.  Just here to enable file-compile.\n");
   return 0;
}

#endif



/* Local Variables:         */
/* compile-command: "gcc   \*/
/* -Wall -Werror -pedantic \*/
/* -ggdb -std=c99          \*/
/* -DTI_MODES_MAIN         \*/
/* -ltinfo                 \*/
/* -fsanitize=address      \*/
/* -o ti_modes             \*/
/* ti_modes.c"              */
/* End:                     */

