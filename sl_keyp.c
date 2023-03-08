#include <unistd.h>
#include "termintel.h"

/**
 * @brief Get and categorize a "silent" keypress.
 *
 * Designed to recognize keypresses identified by escape sequences.
 * Values returned through pointer arguments to disambiguate integer
 * values that may be characters or indexes into an array of
 * recognized keycodes.
 *
 * Can use all NULL parameters if simple unrecognized keypress is all
 * that is needed.
 *
 * @param[out] "key_index"       pointer to integer representing the index into
 *                               the array @p recognized_keys. The integer will be
 *                               set to '-1' if not found in the array.
 * @param[out] "typed_char"      The character value of the typed key.  This value
 *                               will be set if the user typed a character key, and
 *                               it will be set to -1 if the keycode is not a
 *                               typeable character.
 * @param[in] "recognized_keys"  Array of TIV elements to search for a matching
 *                               escape string.
 * @param[out] "sequence"        Optional parameter.  If a pointer to a pointer to a
 *                               string is provided, it will be set to the uninterpreted
 *                               buffer in which the keyboard output is saved.
 *
 * @return -1 if unknown escape sequence (refer to optional @p sequence,  
 *         0 for timeout,  
 *         1 if result in @p key_index of escape sequence,  
 *         2 if result in @p typed_char when not an escape sequence.
 */
int ti_get_keypress(int *key_index, char *typed_char, TIV *recognized_keys, const char **sequence)
{
   char buff[80] = { 0 };
   ssize_t bytes_read;

   if (sequence)
      *sequence = buff;

   // Set unused values to output parameters in case of early exit
   if (key_index)
      *key_index = -1;
   if (typed_char)
      *typed_char = -1;

   tios_set_read_params(1, 10);

   bytes_read = read(STDIN_FILENO, buff, sizeof(buff));

   tios_restore_read_params();

   if (bytes_read == -1)
      return 0;
   else if (buff[0] == '\033' && key_index && recognized_keys)
   {
      buff[bytes_read] = '\0';
      *key_index = TIV_find_index_by_sequence(recognized_keys, buff);
      if (*key_index >= 0)
         return 1;
   }
   else if (typed_char)
   {
      *typed_char = buff[0];
      return 2;
   }

   return -1;
}



#ifdef SL_KEYP_MAIN

#include "sl_caps.c"
#include "sl_tios.c"

#include "ti_modes.c"
#include "ti_capset_keys.c"
#include "ti_capset_modes.c"

#include <signal.h>


void run_program(void)
{
   int key_index = -1;
   char key_char = -1;
   int result;
   const char *seq;

   tios_disable_echo();
   // write(STDIN_FILENO, "\033[?1h", 5);
   ti_enter_keypad_mode();

   while (key_char != 'q' && key_char != 'Q')
   {
      result = ti_get_keypress(&key_index, &key_char, caps_KEYS, &seq);
      if (result == 0)
         continue;
      else if (result == 1)
         printf("You pressed %s.\n", desc_KEYS[key_index]);
      else if (result == 2)
         printf("You pressed the '%c' key.\n", key_char);
      else if (result == -1)
      {
         printf("Unrecognized sequence: ");
         TIV_print_sequence(seq);
         printf("\n");
      }
   }

   // write(STDIN_FILENO, "\033[?1l", 5);
   ti_exit_keypad_mode();
   tios_restore_echo();
}

void signal_constant(const char *from, int val)
{
   printf("Signal in '%s'...", from);
   switch(val)
   {
      case SIGINT: printf("SIGINT\n"); break;
      case SIGILL: printf("SIGILL\n"); break;
      case SIGABRT: printf("SIGABRT\n"); break;
      case SIGFPE: printf("SIGFPE\n"); break;
      case SIGSEGV: printf("SIGSEGV\n"); break;
      case SIGTERM: printf("SIGTERM\n"); break;
      case SIGHUP: printf("SIGHUP\n"); break;
      case SIGQUIT: printf("SIGQUIT\n"); break;
      case SIGTRAP: printf("SIGTRAP\n"); break;
      case SIGKILL: printf("SIGKILL\n"); break;
      case SIGPIPE: printf("SIGPIPE\n"); break;
      case SIGALRM: printf("SIGALRM\n"); break;
      default: printf("Unknown signal %d.\n", val); break;
   }
}

// Globally defined to make these definitions available to signal functions
TIV *g_capsets[] = { caps_KEYS, caps_MODES };
int g_capset_count = sizeof(g_capsets) / sizeof(TIV*);

void restore_environment(int signal)
{
   ti_exit_ca_mode();

   tios_restore_incoming();

   TIV_destroy_arrays(g_capset_count, g_capsets);

   if (signal)
   {
      // Signal constants defined in /usr/include/asm/signal.h
      printf("Exiting due to signal %d.\n", signal);
      exit(1);
   }
}

int initialize_environment(void)
{
   tios_save_incoming();

   if (TIV_setup(g_capset_count, g_capsets))
   {
      ti_enter_ca_mode();
      tios_disable_echo();

      signal(SIGINT, restore_environment);   // 2
      signal(SIGQUIT, restore_environment);  // 3
      signal(SIGABRT, restore_environment);  // 6
      signal(SIGTERM, restore_environment);  // 15

      return 1;
   }

   return 0;
}

int main(int argc, const char **argv)
{
   if ( initialize_environment())
   {
      run_program();
      restore_environment(0);
   }

   return 0;
}

#endif

/* Local Variables:          */
/* compile-command:   "gcc  \*/
/* -Wall -Werror -pedantic  \*/
/* -ggdb -std=c99           \*/
/* -DSL_KEYP_MAIN           \*/
/* -fsanitize=address       \*/
/* -ltinfo                  \*/
/* -o sl_keyp               \*/
/* sl_keyp.c"                */
/* End:                      */
