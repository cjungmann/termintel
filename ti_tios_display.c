#include <termios.h>
#include <term.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>  // for strerror
#include <unistd.h>  // for STDIN_FILENO

void ti_disp_show_val_name(int value, const char *name)
{
   const char *tog = " -";
   if (value)
      tog = "ON";

   printf("%-15s %s\n", name, tog);
}

void ti_disp_show_termios_iflags(const struct termios *ti)
{
   ti_disp_show_val_name(ti->c_iflag & IGNBRK, "IGNBRK");
   ti_disp_show_val_name(ti->c_iflag & BRKINT, "BRKINT");
   ti_disp_show_val_name(ti->c_iflag & IGNPAR, "IGNPAR");
   ti_disp_show_val_name(ti->c_iflag & PARMRK, "PARMRK");
   ti_disp_show_val_name(ti->c_iflag & INPCK, "INPCK");
   ti_disp_show_val_name(ti->c_iflag & ISTRIP, "ISTRIP");
   ti_disp_show_val_name(ti->c_iflag & INLCR, "INLCR");
   ti_disp_show_val_name(ti->c_iflag & IGNCR, "IGNCR");
   ti_disp_show_val_name(ti->c_iflag & ICRNL, "ICRNL");
   ti_disp_show_val_name(ti->c_iflag & IUCLC, "IUCLC");
   ti_disp_show_val_name(ti->c_iflag & IXON, "IXON");
   ti_disp_show_val_name(ti->c_iflag & IXANY, "IXANY");
   ti_disp_show_val_name(ti->c_iflag & IXOFF, "IXOFF");
   ti_disp_show_val_name(ti->c_iflag & IMAXBEL, "IMAXBEL");
   ti_disp_show_val_name(ti->c_iflag & IUTF8, "IUTF8");
}


void ti_disp_show_termios_lflags(const struct termios *ti)
{
   ti_disp_show_val_name(ti->c_lflag & ISIG, "ISIG");
   ti_disp_show_val_name(ti->c_lflag & ICANON, "ICANON");
#if defined __USE_MISC || (defined __USE_XOPEN && !defined __USE_XOPEN2K)
   ti_disp_show_val_name(ti->c_lflag & XCASE, "XCASE");
#endif
   ti_disp_show_val_name(ti->c_lflag & ECHO, "ECHO");
   ti_disp_show_val_name(ti->c_lflag & ECHOE, "ECHOE");
   ti_disp_show_val_name(ti->c_lflag & ECHOK, "ECHOK");
   ti_disp_show_val_name(ti->c_lflag & ECHONL, "ECHONL");
   ti_disp_show_val_name(ti->c_lflag & NOFLSH, "NOFLSH");
   ti_disp_show_val_name(ti->c_lflag & TOSTOP, "TOSTOP");
#ifdef __USE_MISC
   ti_disp_show_val_name(ti->c_lflag & ECHOCTL, "ECHOCTL");
   ti_disp_show_val_name(ti->c_lflag & ECHOPRT, "ECHOPRT");
   ti_disp_show_val_name(ti->c_lflag & ECHOKE, "ECHOKE");
   ti_disp_show_val_name(ti->c_lflag & FLUSHO, "FLUSHO");
   ti_disp_show_val_name(ti->c_lflag & PENDIN, "PENDIN");
#endif
   ti_disp_show_val_name(ti->c_lflag & IEXTEN, "IEXTEN");
#ifdef __USE_MISC
   ti_disp_show_val_name(ti->c_lflag & EXTPROC, "EXTPROC");
#endif
}

#ifdef TI_TIOS_DISPLAY_MAIN


int main(int argc, const char **argv)
{
   struct termios cur_termios;
   int result = tcgetattr(STDIN_FILENO, &cur_termios);
   if (result)
      printf("Function tcgetattr failed, %s.\n", strerror(errno));
   else
   {
      printf("The current termios iflag (input modes) settings are:\n");
      ti_disp_show_termios_iflags(&cur_termios);
      printf("\n\nThe current termios lflag (local modes)  settings are:\n");
      ti_disp_show_termios_lflags(&cur_termios);
   }
   return result;
}


#endif


/* Local Variables:         */
/* compile-command: "gcc   \*/
/* -Wall -Werror -pedantic \*/
/* -ggdb -std=c99          \*/
/* -DTI_TIOS_DISPLAY_MAIN  \*/
/* -ltinfo                 \*/
/* -fsanitize=address      \*/
/* -o ti_tios_display      \*/
/* ti_tios_display.c"       */
/* End:                     */
