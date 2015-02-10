/*
 *  winiphone.h
 *  iNetHack
 *
 *  Created by dirk on 6/26/09.
 *  Copyright 2009 Dirk Zimmermann. All rights reserved.
 *
 */

//  This file is part of iNetHack.
//
//  iNetHack is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, version 2 of the License only.
//
//  iNetHack is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with iNetHack.  If not, see <http://www.gnu.org/licenses/>.

#include "hack.h"

void iphone_init_nhwindows(int* argc, char** argv);
void iphone_player_selection();
void iphone_askname();
void iphone_get_nh_event();
void iphone_exit_nhwindows(const char *str);
void iphone_suspend_nhwindows(const char *str);
void iphone_resume_nhwindows();
winid iphone_create_nhwindow(int type);
void iphone_clear_nhwindow(winid wid);
void iphone_display_nhwindow(winid wid, BOOLEAN_P block);
void iphone_destroy_nhwindow(winid wid);
void iphone_curs(winid wid, int x, int y);
void iphone_putstr(winid wid, int attr, const char *text);
void iphone_display_file(const char *filename, BOOLEAN_P must_exist);
void iphone_start_menu(winid wid);
void iphone_add_menu(winid wid, int glyph, const ANY_P *identifier,
					 CHAR_P accelerator, CHAR_P group_accel, int attr, 
					 const char *str, BOOLEAN_P presel);
void iphone_end_menu(winid wid, const char *prompt);
int iphone_select_menu(winid wid, int how, menu_item **menu_list);
void iphone_update_inventory();
void iphone_mark_synch();
void iphone_wait_synch();
void iphone_cliparound(int x, int y);
void iphone_cliparound_window(winid wid, int x, int y);
void iphone_print_glyph(winid wid, XCHAR_P x, XCHAR_P y, int glyph);
void iphone_raw_print(const char *str);
void iphone_raw_print_bold(const char *str);
int iphone_nhgetch();
int iphone_nh_poskey(int *x, int *y, int *mod);
void iphone_nhbell();
int iphone_doprev_message();
char iphone_yn_function(const char *question, const char *choices, CHAR_P def);
void iphone_getlin(const char *prompt, char *line);
int iphone_get_ext_cmd();
void iphone_number_pad(int num);
void iphone_delay_output();
void iphone_start_screen();
void iphone_end_screen();
void iphone_outrip(winid wid, int how);

// bones will be loaded
void iphone_will_load_bones(const char *bonesid);
// bones were loaded 
void iphone_finished_bones(const char *bonesid);

void iphone_test_main();
void iphone_main();

void iphone_reset_glyph_cache(); //iNethack2: reset glyph cache
#define VERSION_SANITY2_64 0xb8d26958UL //iNethack2: the versioninfo string for 64-bit bones

