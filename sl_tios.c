#include <termios.h>
#include <ctype.h>
#include <unistd.h>    // for STDIN_FILENO
#include <stdlib.h>    // for exit()
#include <stdio.h>     // for printf()

/**
 * @brief Stores incoming termios settings to be restore up program exit.
 */
struct termios g_termios_incoming = { 0 };

/**
 * @brief Saves the termios state to be restored upon leaving program.
 */
void tios_save_incoming(void)
{
   int result = tcgetattr(STDIN_FILENO, &g_termios_incoming);
   if (result)
   {
      printf("Fatal error: failed to access termios information.\n");
      exit(result);
   }
}

/**
 * @brief Restores termios state saved when @ref tios_save_incoming was called.
 */
void tios_restore_incoming(void)
{
   tcsetattr(STDIN_FILENO, TCSANOW, &g_termios_incoming);
}

/**
 * @brief Declared globally so available for disable and enable functions.
 */
tcflag_t tios_local_mode_echo_flags =
   ECHO         // echo input characters
   | ECHONL     // echo NewLine even if ECHO is OFF
   | ICANON
   // | IEXTEN
   ;

/**
 * @brief Turns off character echo for key presses.
 */
void tios_disable_echo(void)
{
   struct termios tcur;
   tcgetattr(STDIN_FILENO, &tcur);
   tcur.c_lflag &= ~ tios_local_mode_echo_flags;
   tcsetattr(STDIN_FILENO, TCSANOW, &tcur);
}

/**
 * @brief Reverse settings made in @ref tios_disable_echo
 */
void tios_restore_echo(void)
{
   struct termios tcur;
   tcgetattr(STDIN_FILENO, &tcur);
   tcur.c_lflag |= tios_local_mode_echo_flags;
   tcsetattr(STDIN_FILENO, TCSANOW, &tcur);
}

/**
 * @brief Set parameters that affect the @p read function.
 *
 * Use this function to prepare `read` to return at a timeout
 * or after a minimum of characters.
 *
 * @param "min_chars"   Minimum character needed for `read` to return
 * @param "timeout"     `read` returns after a timeout
 */
void tios_set_read_params(unsigned min_chars, unsigned timeout)
{
   struct termios tcur;
   tcgetattr(STDIN_FILENO, &tcur);
   tcur.c_cc[VMIN] = min_chars;
   tcur.c_cc[VTIME] = timeout;
   tcsetattr(STDIN_FILENO, TCSAFLUSH, &tcur);
}

/**
 * @brief Restore original settings for min_chars and timeout.
 */
void tios_restore_read_params(void)
{
   struct termios tcur;
   tcgetattr(STDIN_FILENO, &tcur);
   tcur.c_cc[VMIN] = g_termios_incoming.c_cc[VMIN];
   tcur.c_cc[VTIME] = g_termios_incoming.c_cc[VTIME];
   tcsetattr(STDIN_FILENO, TCSANOW, &tcur);
}

/**
 * @brief Set raw mode, more restrictive than disable echo.
 *
 * There is no corresponding exit_raw_mode() function, It seems like
 * this mode will only be necessary for very short times, so the procedure
 * should be to save the current termios settings, call @p tios_set_raw_mode,
 * do your deed, then restore from the saved value.
 */
void tios_set_raw_mode(void)
{
   struct termios tcur;
   tcgetattr(STDIN_FILENO, &tcur);
   // Unset some input mode flags
   tcur.c_iflag &= ~( BRKINT | ICRNL | INPCK | ISTRIP | IXON );

   // Unset some output mode flags
   tcur.c_oflag &= ~( OPOST );

   // Unset some control mode flags
   tcur.c_cflag &= ~( CS8 );

   // Unset some local mode flags
   /* tcur.c_lflag &= ~( ECHO | ICANON | IEXTEN | ISIG ); */
   tcur.c_lflag &= ~( ECHO | ICANON | IEXTEN );

   tcsetattr(STDIN_FILENO, TCSAFLUSH, &tcur);
}

// Hide debugging code from Doxygen
/** @cond */

#ifdef SL_TIOS_MAIN

int main(int argc, const char **argv)
{
   printf("Nothing to see here.  Just here to enable file-compile.\n");
   return 0;
}

#endif

/** @endcond */


/* Local Variables:         */
/* compile-command: "gcc   \*/
/* -Wall -Werror -pedantic \*/
/* -ggdb -std=c99          \*/
/* -DSL_TIOS_MAIN          \*/
/* -ltinfo                 \*/
/* -fsanitize=address      \*/
/* -o sl_tios              \*/
/* sl_tios.c"               */
/* End:                     */
