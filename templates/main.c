#include <termintel.h>

#include "ti_capset_control.h"
#include "ti_capset_keys.h"
#include "ti_capset_modes.h"

#include "program.h"

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

TIV *g_capsets[] = { caps_CONTROL, caps_KEYS, caps_MODES };
int g_capset_count = sizeof(g_capsets) / sizeof(TIV*);
int g_swide = 0;
int g_stall = 0;

/**
 * @brief Print simple message for a given signal.
 * @param "signal"   signal value
 */
void announce_signal(int signal)
{
   const char *stype = NULL;
   switch(signal)
   {
      case SIGINT:  stype = "program interrupt";     break;
      case SIGQUIT: stype = "program quit (Ctrl-C)"; break;
      case SIGABRT: stype = "program aborted";       break;
      case SIGSEGV: stype = "memory segment error";  break;
      case SIGTERM: stype = "program terminated";    break;
      case SIGKILL: stype = "process killed";        break;
      case SIGTSTP: stype = "program stop";          break;
      default:      stype = "unrecognized signal";   break;
   };
   printf("Received signal %d (%s)\n", signal, stype);
}

/**
 * @brief Undo everything done in @ref main_init.
 *
 * Setup as a signal handler to help ensure that the incoming
 * terminal environment is restored before leaving this application.
 *
 * If called as result of a signal, an informative message will be
 * printed the application will terminate after the cleanup.
 *
 * @param "signal"   != 0 if called as a signal handler
 */
void main_deinit(int signal)
{
   tios_restore_echo();

   // Reverse modes from main_init()
   TIV_execute(caps_MODES, MODES_KEYPAD_LOCAL);
   TIV_execute(caps_MODES, MODES_EXIT_CA_MODE);

   // Release memory after last use
   TIV_destroy_arrays(g_capset_count, g_capsets);

   tios_restore_incoming();

   if (signal)
   {
      announce_signal(signal);
      exit(1);
   }
}

/**
 * @brief Initialize program, paired with @ref main_deinit, where
 * everything done here is undone.
 *
 * Save, then modify environment for our use.  Collect terminfo escape
 * sequences, and set signal handlers to ensure cleanup.
 */
int main_init(void)
{
    tios_save_incoming();

   // Start CUP mode
   if (TIV_setup(g_capset_count, g_capsets))
   {
      // Ensure CUP mode exit for unexpected exit:
      signal(SIGINT, main_deinit);    // 2
      signal(SIGQUIT, main_deinit);   // 3
      signal(SIGABRT, main_deinit);   // 6
      signal(SIGSEGV, main_deinit);   // 11
      signal(SIGTERM, main_deinit);   // 15
      signal(SIGKILL, main_deinit);
      signal(SIGTSTP, main_deinit);

      ti_get_screen_size(&g_stall, &g_stall);

      TIV_execute(caps_MODES, MODES_ENTER_CA_MODE);
      TIV_execute(caps_MODES, MODES_KEYPAD_XMIT);

      tios_disable_echo();
      return 1;
   }

   return 0;
}

/**
 * @brief Necessary @p main function, calls @ref program.
 *
 * Rather than implementing function @p main, use this function
 * to call a custom @p program function with @p argc and @p argv
 * arguments.
 */
int main(int argc, const char **argv)
{
   if (main_init())
   {
      program(argc, argv);

      main_deinit(0);
   }
   return 0;
}
