#include "ti_capset_control.inc"
#include "ti_caps.h"
#include "ti_tios.h"

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include <curses.h>
#include <term.h>

void ti_control_execute(enum enum_CTRL ctrl)
{
   if (ctrl>=0 && ctrl < CTRL_END)
   {
      TIV *tiv = &caps_CTRL[ctrl];
      if (tiv && tiv->sequence)
         tputs(tiv->sequence, 1, putchar);
   }
}

void ti_control_execute_args(enum enum_CTRL ctrl,...)
{
   if (ctrl>=0 && ctrl < CTRL_END)
   {
      TIV *tiv = &caps_CTRL[ctrl];
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

void ti_clear_screen(void) { ti_control_execute(CTRL_CLEAR_SCREEN); }
void ti_clear_end_of_line(void) { ti_control_execute(CTRL_CLR_EOL); }
void ti_clear_end_of_screen(void) { ti_control_execute(CTRL_CLR_EOS); }
void ti_scroll_down(void) { ti_control_execute(CTRL_SCROLL_FORWARD); }
void ti_scroll_up(void) { ti_control_execute(CTRL_SCROLL_REVERSE); }
void ti_move_home(void) { ti_control_execute(CTRL_CURSOR_HOME); }
void ti_move_cursor(int row, int column)
{
   ti_control_execute_args(CTRL_CURSOR_ADDRESS, row, column);
}
void ti_move_cursor_down(int howfar)
{
   ti_control_execute_args(CTRL_PARM_DOWN_CURSOR, howfar);
}
void ti_move_cursor_up(int howfar)
{
   ti_control_execute_args(CTRL_PARM_UP_CURSOR, howfar);
}

void ti_set_left_margin(int margin)
{
   ti_control_execute_args(CTRL_SET_LEFT_MARGIN_PARM, margin);
}

void ti_set_right_margin(int margin)
{
   ti_control_execute_args(CTRL_SET_RIGHT_MARGIN_PARM, margin);
}

void ti_clear_margins(void)
{
   ti_control_execute(CTRL_CLEAR_MARGINS);
}

void ti_report_cursor_position(int* rows, int* cols)
{
   struct termios tsave;
   *rows = *cols = -1;

   const char *seq = TIV_get_sequence(&caps_CTRL[CTRL_USER7]);
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

#include "ti_caps.c"
#include "ti_tios.c"

void run_test(void)
{
   int rows_before=0, cols_before=0;
   int rows_after=0, cols_after=0;
   ti_report_cursor_position(&rows_before, &cols_before);

   ti_clear_screen();

   ti_report_cursor_position(&rows_before, &cols_before);
   ti_move_cursor(25, 100);
   printf("Before, rows=%d, columns=%d.\nAfter, rows=%d, columns=%d.\n",
          rows_before, cols_before,
          rows_after, cols_after);

   // ti_set_left_margin(40);
   // ti_set_right_margin(140);

   ti_move_cursor(25, 100);
   ti_report_cursor_position(&rows_before, &cols_before);
   ti_move_cursor(28, 100);
   printf("\nAfter move to 2000,2000, the cursor is at row=%d, columns=%d.\n",
          rows_before, cols_before);

   ti_clear_margins();
   printf("\nAfter clearing the margins.\n");

   printf("<- 20, 20");
   ti_scroll_up();
   printf("scroll result");
   ti_scroll_up();
   printf("scroll result");
   ti_scroll_up();
   printf("scroll result");
   ti_move_home();
   printf("<- home");

   int rows, cols;
   ti_report_cursor_position(&rows, &cols);
}

int main(int argc, const char **argv)
{
   if (TIV_setup())
   {
      TIV_set_array(caps_CTRL);
      run_test();
      TIV_destroy_array(caps_CTRL);
   }

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

