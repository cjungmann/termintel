#ifndef TI_MODES_H
#define TI_MODES_H

void ti_set_mode(int mode);
void ti_enter_ca_mode(void);
void ti_exit_ca_mode(void);

void ti_enter_keypad_mode(void);
void ti_exit_keypad_mode(void);

void ti_enter_bold(void);
void ti_exit_bold(void);

void ti_enter_underline(void);
void ti_exit_underline(void);

void ti_enter_standout_mode(void);
void ti_exit_standout_mode(void);

void ti_enter_reverse_mode(void);
void ti_exit_reverse_mode(void);

void ti_enter_blink_mode(void);
void ti_exit_blink_mode(void);



#endif
