#ifndef TI_CAPS_H
#define TI_CAPS_H

#include <stddef.h>

typedef struct terminfo_value {
   char code[2];
   char *sequence;
   int  index;
} TIV;

int TIV_is_terminator(TIV *tiv);

// Initialize environment
int TIV_setup(void);

// Setting capability escape sequences
int TIV_set_sequence(TIV *tiv, const char *seq);
int TIV_set_from_env(TIV *tiv);
int TIV_set_from_termcap(TIV *tiv);
int TIV_set(TIV *tiv);
void TIV_set_array(TIV *tiv);

// Memory recovery
void TIV_destroy_array(TIV *tiv);

// Display/debugging functions
int TIV_string_array_max_length(const char **strings);
void TIV_print_sequence(const char *seq);
void TIV_dump(TIV *tiv, const char **names, int names_width);
void TIV_dump_array(TIV *tiv, const char **names);

// Searching functions
int TIV_find_index_by_sequence(TIV *tiv, const char *sequence);
int TIV_find_index_by_code(TIV *tiv, const char *code);

const char *TIV_get_sequence(const TIV *tiv);



#endif






