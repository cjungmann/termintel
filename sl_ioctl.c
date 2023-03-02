#include <sys/ioctl.h>
#include <asm/termbits.h>

void ti_get_screen_size(int *rows, int *cols)
{
   struct winsize ws;
   int result = ioctl(STDIN_FILENO, TIOCGWINSZ, &ws);
   if (result==0)
   {
      *rows = ws.ws_row;
      *cols = ws.ws_col; 
  }
   else
      *rows = *cols = -1;
}
