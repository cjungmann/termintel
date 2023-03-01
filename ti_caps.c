#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <curses.h>
#include <term.h>
#include <unistd.h>   // for STDIN_FILENO


#include "ti_caps.h"

/**
 * @brief Idenfify terminating TIV element
 * @param "tiv"  element to discern if terminating or not
 * @return 1 (true) if terminating, 0 if not
 */
int TIV_is_terminator(TIV *tiv)
{
   return tiv->code[0] == 0;
}

/**
 * @brief Call to initialize terminfo environment and set of TIV arrays
 *
 * Calls library setupterm() to initialize terminfo database access.
 * Initializes a set of TIV arrays with sequences taken from the database.
 * Call @ref TIV_destroy_arrays with the same array to free the memory,
 * or call @ref TIV_destroy_array for each TIV array.
 *
 * @param "count"   number of elements in the following array
 * @param "tivs"    pointer to an array of TIV arrays that should
 *                  be initialized with sequences found in terminfo
 *                  database.
 *
 * @return 1 for success, 0 for failure.
 */
int TIV_setup(int count, TIV *tivs[])
{
   int erret;
   int result = setupterm((char*)NULL, STDIN_FILENO, &erret);
   if (result)
   {
      switch(erret)
      {
         case 1: printf("Hardcopy output: curses unavailable.\n"); break;
         case 0: printf("Generic terminal: curses not supported.\n"); break;
         case -1: printf("Terminfo database not found.\n"); break;
      }
   }

   // Initialise array of TIV arrays
   if (count > 0)
   {
      TIV **tiv = tivs;
      for (int i=0; i<count; ++i)
      {
         TIV_set_array(*tiv);
         ++tiv;
      }
   }

   return result==OK;
}

/**
 * @brief Frees sequence memory for each @ref TIV element in array.
 *
 * @param "tiv"  Pointer to array of @ref TIV elements, the last member of
 *               which should be an element whose code member is {0};
 */
void TIV_destroy_array(TIV *tiv)
{
   TIV *ptr = tiv;
   while (!TIV_is_terminator(ptr))
   {
      if (ptr->sequence)
      {
         free(ptr->sequence);
         ptr->sequence = NULL;
      }

      ++ptr;
   }
}

/**
 * @brief Free memory from a set of TIV arrays.
 *
 * This function is a companion to the @ref TIV_setup function that
 * allocated memory in a set of TIV arrays to start the program.
 *
 * @param "count"   number of elements in the following array
 * @param "tivs"    pointer to an array of TIV arrays that should
 *                  be destroyed to free the memory in which the
 *                  terminfo sequences are saved.
 */
void TIV_destroy_arrays(int count, TIV *tivs[])
{
   // Destroy array of TIV arrays
   if (count > 0)
   {
      TIV **tiv = tivs;
      for (int i=0; i<count; ++i)
      {
         TIV_destroy_array(*tiv);
         ++tiv;
      }
   }
}

/**
 * @brief For TIV instance, set sequence member with copy of sequence using malloced buffer.
 * @param "tiv"   TIV instance to set
 * @param "seq"   Escape sequence to copy to @p tiv argument
 * @return errno value, 0 is success.  Main point of failure would be ENOMEM.
 */
int TIV_set_sequence(TIV *tiv, const char *seq)
{
   if (tiv->sequence)
      free(tiv->sequence);

   int len = strlen(seq);
   char *buff = (char*)malloc(len+1);
   if (buff)
   {
      memcpy(buff, seq, len);
      buff[len] = '\0';

      tiv->sequence = buff;
   }

   return errno;
}

/**
 * @brief Called by @ref TIV_set to search, and save if found, escape sequence for given termcap code
 *
 * The @p tiv argument must have its @p code element set to the
 * termcap code indicated by this capability.
 *
 * @param "tiv"   TIV instance to set
 * @return 0 for success, otherwise errno.  Any error is likely to be either EINVAL or ENOMEM.
 */
int TIV_set_from_env(TIV *tiv)
{
   static char less_termcap[] = "LESS_TERMCAP_xx";
   memcpy(&less_termcap[13], tiv->code, 2);
   const char *area = getenv(less_termcap);
   if (area)
      return TIV_set_sequence(tiv, area);

   return EINVAL;
}

/**
 * @brief Called by @ref TIV_set to set escape sequence from terminfo database.
 *
 * The @p tiv argument must have its @p code element set to the
 * termcap code indicated by this capability.
 *
 * @param "tiv"   TIV instance to set
 * @return 0 for success, otherwise errno.  Any error is likely to be either EINVAL or ENOMEM.
 */
int TIV_set_from_termcap(TIV *tiv)
{
   static char buff[256];
   char *area = buff;
   char *value;
   value = tgetstr(tiv->code, &area);
   if (value)
      return TIV_set_sequence(tiv, value);

   return EINVAL;
}


/**
 * @brief Populate sequence member of @p tiv instance fron environment or terminfo database.
 *
 * Searches for an escape sequence based on the 2-character termcap
 * code set in the @p tiv code member.
 *
 * If there is an environment variable of the form:
 * `LESS_TERMCAP_xx`, where the `xx` is replaced by the termcap code,
 * the string assigned to the LESS_TERMCAP_xx variable will be used,
 * otherwise the escape sequence found in the terminfo database will
 * be used.
 *
 * @param "tiv"   TIV instance to set
 * @return 0 for success, otherwise errno.  Any error is likely to be either EINVAL or ENOMEM.
 */
int TIV_set(TIV *tiv)
{
   int rval = TIV_set_from_env(tiv);
   if (rval)
      rval = TIV_set_from_termcap(tiv);
   return rval;
}

/**
 * @brief Set escape sequence values for an array of @ref TIV elements.
 *
 * @param "tiv"  Pointer to array of @ref TIV elements, the last member of
 *               which should be an element whose code member is {0};
 */
void TIV_set_array(TIV *tiv)
{
   TIV *ptr = tiv;
   int index=0;
   while (!TIV_is_terminator(ptr))
   {
      TIV_set(ptr);
      ptr->index = index++;
      ++ptr;
   }
}

/**
 * @brief Returns longest string in a NULL-terminated arraya of string pointers.
 *
 * @param "strings"   Pointer to first element of array to be scanned.
 * @return length of longest string in the array.
 */
int TIV_string_array_max_length(const char **strings)
{
   int maxlen = 0;
   int curlen;
   const char **ptr = strings;
   while (*ptr)
   {
      curlen = strlen(*ptr);
      if (curlen > maxlen)
         maxlen = curlen;
      ++ptr;
   }

   return maxlen;
}

/**
 * @brief Print an display-friendly string of an escape sequence.
 *
 * This function will print an escape sequence with non-printable characters
 * replaced with a color-highlighted, caret-prefixed control character.
 * For example, ESCAPE will be rendered as a red `^[`.
 *
 * Also, a space character will be printed with a different background
 * color to clarify intent.
 *
 * @param "seq"   The NULL-terminated escape sequence string to print
 */
void TIV_print_sequence(const char *seq)
{
   const char *tptr = seq;
   while (*tptr)
   {
      if (*tptr < ' ')
         printf("\033[31;1m^%c\033[m", (*tptr + 64));
      else if (*tptr == ' ')
         printf("\033[44m \033[m");
      else if (*tptr == 127)  // backspace
         printf("\033[31;1m^?\033[m");
      else
         printf("%c", *tptr);

      ++tptr;
   }
}

/**
 * @brief Print every every element of the @p tiv array.
 *
 * @param "tiv"            Pointer to array of @ref TIV elements, the last member of
 *                         which should be an element whose code member is {0};
 * @param "strings"        Correlated array of strings to print with each @p tiv element.
 *                         For safety, use arrays generated by `ti_process_capset` script.
 * @param "strings_width"  If set, this value will be used to format the @p strings
 *                         values.  Use @ref TIV_string_array_max_length to scan the
 *                         array to find the longest string.
 */
void TIV_dump(TIV *tiv, const char **strings, int strings_width)
{
   if (strings)
   {
      if (strings_width)
         printf("%3d: %2s %-*s  ", tiv->index, tiv->code, strings_width, strings[tiv->index]);
      else
         printf("%3d: %2s %20s  ", tiv->index, tiv->code, strings[tiv->index]);
   }
   else
      printf("%3d: %2s  ", tiv->index, tiv->code);

   if (tiv->sequence)
      TIV_print_sequence(tiv->sequence);
   else
      printf("N/A");
}

/**
 * @brief Print every element of @p riv array, including descriptions from @p strings.
 *
 * @param "tiv"       Pointer to array of @ref TIV elements, the last member of
 *                    which should be an element whose code member is {0};
 * @param "strings"   Correlated array of strings to print with each @p tiv element.
 *                    For safety, use arrays generated by `ti_process_capset` script.
 */
void TIV_dump_array(TIV *tiv, const char **strings)
{
   int desc_len = 0;
   if (strings)
      desc_len = TIV_string_array_max_length(strings);

   TIV *ptr = tiv;
   while (!TIV_is_terminator(ptr))
   {
      TIV_dump(ptr, strings, desc_len);
      printf("\n");

      ++ptr;
   }
}

/**
 * @brief Returns index into @p tiv array whose sequence member matches the
 *        @p sequence argument.
 *
 * Use this function to identify keypress string returned by non-character
 * keyboard keys like `PgDN`, `Home`, or `ESC`.
 *
 * @param "tiv"       Pointer to array of @ref TIV elements, the last member of
 *                    which should be an element whose code member is {0};
 * @param "sequence"  Sequence string to seek.
 *
 * @return Index to matching @ref TIV element, otherwise -1 if not found.
 */
int TIV_find_index_by_sequence(TIV *tiv, const char *sequence)
{
   TIV *ptr = tiv;
   while (!TIV_is_terminator(ptr))
   {
      if (strcmp(ptr->sequence, sequence)==0)
         return ptr->index;
      ++ptr;
   }

   return -1;
}

/**
 * @brief Returns index into @p tiv array whose code member matches the
 *        @p code argument.
 *
 * Use this function to find escape sequences associated with specific
 * actions as indicated by the @p code argument.  Examples would be
 * `md` and `me` to start and end bold output mode.
 *
 * @param "tiv"   Pointer to array of @ref TIV elements, the last member of
 *                which should be an element whose code member is {0};
 * @param "code"  Code string to seek.
 *
 * @return Index to matching @ref TIV element, otherwise -1 if not found.
 */
int TIV_find_index_by_code(TIV *tiv, const char *code)
{
   TIV *ptr = tiv;
   while (!TIV_is_terminator(ptr))
   {
      if (memcmp(tiv->code, code, 2)==0)
         return ptr->index;
      ++ptr;
   }

   return -1;
}

/**
 * @brief Search environment and terminfo database for sequence
 *        associated with @p code.
 *
 * Find escape sequence for a given two-character **termcap** code,
 * searching environment variables first, then the **terminfo**
 * database.
 *
 * The recognized environment variable names start **LESS_TERMCAP_**,
 * followed by the two-character **termcap** code.  This feature is
 * modelled after system utility **less**, serving the same purpose.
 *
 * @param "sequence"   pointer to char* in to which a pointer to the
 *                     sequence value is set.
 * @param "code"       two-character **termcap** code to be sought
 *
 * @return 0 for success, errno value if failed to find the entry.
 */
int TIV_get_sequence_from_code(const char **sequence, const char *code)
{
   int rval = EINVAL;
   const char *seq = NULL;
   *sequence = NULL;

   static char less_termcap[] = "LESS_TERMCAP_xx";
   memcpy(&less_termcap[13], code, 2);
   seq = getenv(less_termcap);
   if (!seq)
   {
      static char buff[128];
      char *area = buff;
      seq = tgetstr(code, &area);
   }

   if (seq)
   {
      *sequence = seq;
      rval = 0;
   }

   return rval;
}

/**
 * @brief Simple function to extract the sequence from a TIV variable
 * @param "tiv"    pointer to a TIV struct
 * @return pointer to escape sequence, or NULL if no sequence available
 */
const char *TIV_get_sequence(const TIV *tiv)
{
   if (tiv && tiv->sequence)
      return tiv->sequence;
   else
      return NULL;
}

/**
 * @brief Simple submission of sequence associated with the indicate TIV element.
 *
 * This is not a "safe" function in that it does not confirm a sane
 * index number (within the range of the array).  If safety is needed,
 * write a wrapper function that confirms the index.
 *
 * @param "tiv"   Array of TIV elements from which the item will be selected
 * @param "index" Index into array @p tiv.
 */
void TIV_execute(const TIV **tiv, int index)
{
   const TIV *t = tiv[index];
   if (t->sequence)
      tputs(t->sequence, 1, putchar);
}

/**
 * @brief Same as @ref TIV_execute, but includes a lines-affected parameter.
 *
 * Unlike @ref TIV_execute, this function sets the "affcnt" argument of
 * @p tputs to indicated affected lines.  Mostly for scrolling functions,
 * but may be necessary for other capabilities also.
 *
 * @param "tiv"       Array of TIV elements from which the item will be selected
 * @param "index"     Index into array @p tiv.
 * @param "linecount" Number of lines to be affected by the call.
 */
void TIV_execute_with_lines(const TIV **tiv, int index, int linecount)
{
   const TIV *t = tiv[index];
   if (t->sequence)
      tputs(t->sequence, linecount, putchar);
}

/**
 * @brief Simple submission of sequence with arguments.
 *
 * This is not a "safe" function in that it does not confirm a sane
 * index number (within the range of the array).  If safety is needed,
 * write a wrapper function that confirms the index.
 *
 * @param "tiv"   Array of TIV elements from which the item will be selected
 * @param "index" Index into array @p tiv.
 * @param "..."   const int arguments as necessary for the indicated capability.
 */
void TIV_execute_params(const TIV **tiv, int index,...)
{
   const TIV *t = tiv[index];
   if (t->sequence)
   {
      va_list list_args;
      va_start(list_args, index);
      int arg1 = va_arg(list_args, int);
      int arg2 = va_arg(list_args, int);
      int arg3 = va_arg(list_args, int);
      int arg4 = va_arg(list_args, int);
      int arg5 = va_arg(list_args, int);
      va_end(list_args);

      const char *str = tiparm(t->sequence, arg1, arg2, arg3, arg4, arg5);
      tputs(str, 1, putchar);
   }
}

/**
 * @brief Simple submission of sequence with arguments with lines-affected parameter.
 *
 * This is not a "safe" function in that it does not confirm a sane
 * index number (within the range of the array).  If safety is needed,
 * write a wrapper function that confirms the index.
 *
 * @param "tiv"       Array of TIV elements from which the item will be selected
 * @param "index"     Index into array @p tiv.
 * @param "linecount" Number of lines to be affected by the call.
 * @param "..."       const int arguments as necessary for the indicated capability.
 */
void TIV_execute_params_with_lines(const TIV **tiv, int index, int linecount,...)
{
   const TIV *t = tiv[index];
   if (t->sequence)
   {
      va_list list_args;
      va_start(list_args, linecount);
      int arg1 = va_arg(list_args, int);
      int arg2 = va_arg(list_args, int);
      int arg3 = va_arg(list_args, int);
      int arg4 = va_arg(list_args, int);
      int arg5 = va_arg(list_args, int);
      va_end(list_args);

      const char *str = tiparm(t->sequence, arg1, arg2, arg3, arg4, arg5);
      tputs(str, linecount, putchar);
   }
}

#ifdef TI_CAPS_MAIN

// Main
int main(int argc, const char **argv)
{
   printf("This program only includes main() to allow successful test compile.\n");
   return 0;
}

#endif

/* Local Variables:           */
/* compile-command: "gcc     \*/
/* -Wall -Werror -pedantic   \*/
/* -ggdb -std=c99            \*/
/* -ltinfo                   \*/
/* -fsanitize=address        \*/
/* -DTI_CAPS_MAIN            \*/
/* -o ti_caps ti_caps.c"      */
/* End:                       */
