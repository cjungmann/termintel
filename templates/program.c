#include <stdio.h>
#include <termintel.h>

#include "ti_capset_keys.h"
#include "ti_capset_modes.h"
#include "ti_capset_control.h"

/**
 * @brief mirror of main(), called by main() to start application.
 */
int program(int argc, const char **argv)
{
   printf("Hello from program().\n");
   return 0;
}
