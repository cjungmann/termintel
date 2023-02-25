#include "ti_capset_control.h"
#include "ti_capset_keys.h"
#include "ti_capset_modes.h"
#include "ti_caps.h"
#include "ti_tios.h"

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include <curses.h>
#include <term.h>

void ti_control_execute(enum enum_CONTROL ctrl)
{
   if (ctrl>=0 && ctrl < CONTROL_END)
   {
      TIV *tiv = &caps_CONTROL[ctrl];
      if (tiv && tiv->sequence)
         tputs(tiv->sequence, 1, putchar);
   }
}

void ti_control_execute_args(enum enum_CONTROL ctrl,...)
{
   if (ctrl>=0 && ctrl < CONTROL_END)
   {
      TIV *tiv = &caps_CONTROL[ctrl];
      if (tiv && tiv->sequence)
      {
         va_list list_args;
         va_start(list_args, ctrl);
         int arg1 = va_arg(list_args, int);
         int arg2 = va_arg(list_args, int);
         int arg3 = va_arg(list_args, int);
         int arg4 = va_arg(list_args, int);
         int arg5 = va_arg(list_args, int);
         va_end(list_args);

         const char *seq = tiv->sequence;
         const char *str = tiparm(seq, arg1, arg2, arg3, arg4, arg5);
         tputs(str, 1, putchar);
      }
   }
}

void ti_clear_screen(void) { ti_control_execute(CONTROL_CLEAR_SCREEN); }
void ti_clear_end_of_line(void) { ti_control_execute(CONTROL_CLR_EOL); }
void ti_clear_end_of_screen(void) { ti_control_execute(CONTROL_CLR_EOS); }

void ti_move_home(void) { ti_control_execute(CONTROL_CURSOR_HOME); }
void ti_save_cursor(void) { ti_control_execute(CONTROL_SAVE_CURSOR); }
void ti_restore_cursor(void) { ti_control_execute(CONTROL_RESTORE_CURSOR); }

void ti_insert_line(void) { ti_control_execute(CONTROL_INSERT_LINE); }

void ti_scroll_down(void)
{
   ti_save_cursor();
   ti_move_home();
   ti_insert_line();
   // ti_control_execute(CONTROL_SCROLL_FORWARD);
   ti_restore_cursor();
}

void ti_scroll_up(void) { ti_control_execute(CONTROL_SCROLL_REVERSE); }

void ti_scroll_forward(int howfar)
{
   ti_control_execute_args(CONTROL_PARM_INDEX, howfar);
}

void ti_scroll_backward(int howfar)
{
   ti_control_execute_args(CONTROL_PARM_RINDEX, howfar);
}

void ti_set_scroll_region(int top, int bottom)
{
   ti_control_execute_args(CONTROL_CHANGE_SCROLL_REGION, top, bottom);
}

void ti_move_cursor(int row, int column)
{
   ti_control_execute_args(CONTROL_CURSOR_ADDRESS, row, column);
}

void ti_move_cursor_down(int howfar)
{
   ti_control_execute_args(CONTROL_PARM_DOWN_CURSOR, howfar);
}

void ti_move_cursor_up(int howfar)
{
   ti_control_execute_args(CONTROL_PARM_UP_CURSOR, howfar);
}

void ti_move_cursor_left(int howfar)
{
   ti_control_execute_args(CONTROL_PARM_LEFT_CURSOR, howfar);
}

void ti_set_left_margin(int margin)
{
   ti_control_execute_args(CONTROL_SET_LEFT_MARGIN_PARM, margin);
}

void ti_set_right_margin(int margin)
{
   ti_control_execute_args(CONTROL_SET_RIGHT_MARGIN_PARM, margin);
}

void ti_clear_margins(void)
{
   ti_control_execute(CONTROL_CLEAR_MARGINS);
}

void ti_report_cursor_position(int* rows, int* cols)
{
   struct termios tsave;
   *rows = *cols = -1;

   const char *seq = TIV_get_sequence(&caps_CONTROL[CONTROL_USER7]);
   if (seq)
   {
      char buff[32] = {0};

      tcgetattr(STDIN_FILENO, &tsave);
      tios_set_raw_mode();

      write(STDIN_FILENO, seq, strlen(seq));
      int bytes_read = read(STDIN_FILENO, buff, sizeof(buff));
      if (bytes_read >= 0)
         buff[bytes_read] = '\0';

      tcsetattr(STDIN_FILENO, TCSAFLUSH, &tsave);

      sscanf(buff, "\033[%d;%dR", rows, cols);
   }
}

#ifdef TI_CONTROL_MAIN

#include <signal.h>

#include "ti_caps.c"
#include "ti_tios.c"
#include "ti_modes.c"
#include "ti_keyp.c"

#include "ti_capset_control.c"
#include "ti_capset_keys.c"
#include "ti_capset_modes.c"

void key_wait(const char *msg)
{
   if (!msg)
      msg = "Press any key to continue.";

   printf("\033[34;1m");
   int len = printf(msg);
   printf("\033[m");
   fflush(stdout);   // flush non-newline terminated text

   int index;
   char chr;
   ti_get_keypress(&index, &chr, caps_KEYS, NULL);

   ti_move_cursor_left(len);
   ti_clear_end_of_line();
   ti_move_cursor_left(len);
}


void test_scrolling(void)
{
   ti_clear_screen();

   printf("This is a test of the scrolling functions.\n");
   printf("Between keypresses, you should be able to see\n");
   printf("how different scroll commands affect the screen.\n");

   ti_scroll_down();

   key_wait("Execute a ti_scroll_down.");

   ti_scroll_forward(5);

   key_wait("Change scroll area, then scroll again.");

   ti_scroll_down();

   key_wait("Execute a ti_scroll_up.");

   ti_scroll_up();

   key_wait("Press any key to continue to the next test.");


}

void run_tests(void)
{
   printf("About to start the tests.\n");
   key_wait(NULL);

   test_scrolling();
}

// Global variables holding TIV arrays and their count enables
// paired initialization and destruction of TIV arrays in main()
// and takedown() in response to a signal or completion of the
// program.
static TIV *g_main_tivs[] = { caps_CONTROL, caps_KEYS, caps_MODES };
static int g_main_tivs_count = sizeof(g_main_tivs) / sizeof(TIV*);
void takedown(int signal)
{
   TIV_destroy_arrays(g_main_tivs_count, g_main_tivs);

   if (signal)
      exit(1);
}

int main(int argc, const char **argv)
{
   if (TIV_setup(g_main_tivs_count, g_main_tivs))
   {
      signal(SIGINT, takedown);
      signal(SIGQUIT, takedown);
      signal(SIGABRT, takedown);
      signal(SIGTERM, takedown);

      run_tests();
      takedown(0);

      return 0;
   }

   return 1;
}

#endif


/* Local Variables:         */
/* compile-command: "gcc   \*/
/* -Wall -Werror -pedantic \*/
/* -ggdb -std=c99          \*/
/* -DTI_CONTROL_MAIN       \*/
/* -ltinfo                 \*/
/* -fsanitize=address      \*/
/* -o ti_control           \*/
/* ti_control.c"              */
/* End:                     */

