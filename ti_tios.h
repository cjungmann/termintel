#ifndef TI_TIOS_H
#define TI_TIOS_H

void tios_save_incoming(void);
void tios_restore_incoming(void);
void tios_disable_echo(void);
void tios_restore_echo(void);
void tios_set_read_params(unsigned min_chars, unsigned timeout);
void tios_restore_read_params(void);
void tios_set_raw_mode(void);





#endif
