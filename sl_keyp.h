#ifndef SL_KEYP_H
#define SL_KEYP_H

#include "sl_caps.h"
#include "sl_tios.h"

int ti_get_keypress(int *key_index,
                    char *typed_char,
                    TIV *recognized_keys,
                    const char **sequence);


#endif
