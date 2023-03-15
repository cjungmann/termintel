/**
 * @file termintel.h
 * @brief consolidated library header
 *
 * Include this header for source files that use functions from
 * the @p termintel library.
 */

#ifndef TERMINTEL_H
#define TERMINTEL_H

#include <stddef.h>

/**
 * @brief Contains a terminfo escape string as identified by a TERMCAP code.
 *
 * This array is initialized only with the @p code element, the
 * @p sequence and @p index are set when querying the terminal
 * for the associated escape sequences.
 */
typedef struct terminfo_value {
   char code[2];           ///< Termcap code
   char *sequence;         ///< escape sequence for this terminal for the code
   int  index;             ///< index reference into array containing this element.
} TIV;

int TIV_is_terminator(TIV *tiv);

// Initialize environment
int TIV_setup(int count, TIV *tivs[]);

// Deinitialize/Memory recovery
void TIV_destroy_array(TIV *tiv);
void TIV_destroy_arrays(int count, TIV *tivs[]);

// Use to populate TIV elements with escape sequences
int TIV_get_sequence_from_code(const char **sequence, const char *code);

// Setting capability escape sequences
int TIV_set_sequence(TIV *tiv, const char *seq);
int TIV_set_from_env(TIV *tiv);
int TIV_set_from_termcap(TIV *tiv);
int TIV_set(TIV *tiv);
void TIV_set_array(TIV *tiv);

// Display/debugging functions
int TIV_string_array_max_length(const char **strings);
void TIV_print_sequence(const char *seq);
void TIV_translate_sequence(char *buff, int len, const char *seq);
void TIV_dump(TIV *tiv, const char **names, int names_width);
void TIV_dump_array(TIV *tiv, const char **names);

// Searching functions
int TIV_find_index_by_sequence(TIV *tiv, const char *sequence);
int TIV_find_index_by_code(TIV *tiv, const char *code);

const char *TIV_get_sequence(const TIV *tiv);

// Using capabilities
void TIV_execute(const TIV *tiv, int index);
void TIV_execute_with_lines(const TIV *tiv, int index, int linecount);
void TIV_execute_params(const TIV *tiv, int index,...);
void TIV_execute_params_with_lines(const TIV *tiv, int index, int linecount,...);

/* sl_tios.c */
void tios_save_incoming(void);
void tios_restore_incoming(void);
void tios_disable_echo(void);
void tios_restore_echo(void);
void tios_set_read_params(unsigned min_chars, unsigned timeout);
void tios_restore_read_params(void);
void tios_set_raw_mode(void);

/* sl_keyp.c */
int ti_get_keypress(int *key_index,
                    char *typed_char,
                    TIV *recognized_keys,
                    const char **sequence);


/* sl_ioctl.c */
void ti_get_screen_size(int *rows, int *cols);

#endif
