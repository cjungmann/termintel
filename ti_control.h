#ifndef TI_CONTROL_H
#define TI_CONTROL_H

void ti_control_execute(enum enum_CTRL ctrl);
void ti_control_execute_args(enum enum_CTRL ctrl,...);

void ti_clear_screen(void);
void ti_clear_end_of_line(void);
void ti_clear_end_of_screen(void);
void ti_scroll_down(void);
void ti_scroll_up(void);
void ti_move_home(void);
void ti_move_cursor(int row, int column);
void ti_move_cursor_down(int howfar);
void ti_move_cursor_up(int howfar);
void ti_set_left_margin(int margin);
void ti_set_right_margin(int margin);
void ti_clear_margins(void);
void ti_report_cursor_position(int* rows, int* cols);


#endif

