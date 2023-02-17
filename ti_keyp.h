#ifndef TI_KEYP_H
#define TI_KEYP_H

#include "ti_caps.h"
#include "ti_tios.h"

int ti_get_keypress(int *key_index,
                    char *typed_char,
                    TIV *recognized_keys,
                    const char **sequence);


#endif
