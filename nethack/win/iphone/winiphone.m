/*
 *  iphone.c
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

#import "winiphone.h"
#import "MainViewController.h"
#import "Window.h"
#import "NethackMenuItem.h"
#import "NethackYnFunction.h"
#import "NethackEvent.h"
#import "NethackEventQueue.h"
#import "NSString+Regexp.h"
#import "TilePosition.h"

// for md5 methods
#import "Hearse.h"

#import "NSString+Regexp.h"

#include <stdio.h>
#include <fcntl.h>
#include "dlb.h"
#include "hack.h"
#include "date.h"

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

#define kOptionUsername (@"username")
#define kOptionAutopickup (@"autopickup")
#define kOptionPickupTypes (@"pickupTypes")
#define kOptionWizard (@"wizard")
#define kOptionAutokick (@"autokick")
#define kOptionTime (@"time")
#define kOptionShowExp (@"showexp")
#define kOptionAutoDig (@"autodig")

#undef DEFAULT_WINDOW_SYS
#define DEFAULT_WINDOW_SYS "iphone"

boolean winiphone_autokick = TRUE;
boolean winiphone_clickable_tiles = FALSE;

struct window_procs iphone_procs = {
"iphone",
WC_COLOR|WC_HILITE_PET|
WC_ASCII_MAP|WC_TILED_MAP|
WC_FONT_MAP|WC_TILE_FILE|WC_TILE_WIDTH|WC_TILE_HEIGHT|
WC_PLAYER_SELECTION|WC_SPLASH_SCREEN,
0L,
iphone_init_nhwindows,
iphone_player_selection,
iphone_askname,
iphone_get_nh_event,
iphone_exit_nhwindows,
iphone_suspend_nhwindows,
iphone_resume_nhwindows,
iphone_create_nhwindow,
iphone_clear_nhwindow,
iphone_display_nhwindow,
iphone_destroy_nhwindow,
iphone_curs,
iphone_putstr,
iphone_display_file,
iphone_start_menu,
iphone_add_menu,
iphone_end_menu,
iphone_select_menu,
genl_message_menu,	  /* no need for X-specific handling */
iphone_update_inventory,
iphone_mark_synch,
iphone_wait_synch,
#ifdef CLIPPING
iphone_cliparound,
#endif
#ifdef POSITIONBAR
donull,
#endif
iphone_print_glyph,
iphone_raw_print,
iphone_raw_print_bold,
iphone_nhgetch,
iphone_nh_poskey,
iphone_nhbell,
iphone_doprev_message,
iphone_yn_function,
iphone_getlin,
iphone_get_ext_cmd,
iphone_number_pad,
iphone_delay_output,
#ifdef CHANGE_COLOR	 /* only a Mac option currently */
donull,
donull,
#endif
/* other defs that really should go away (they're tty specific) */
iphone_start_screen,
iphone_end_screen,
iphone_outrip,
genl_preference_update,
};

@interface WinIPhone : NSObject {}

+ (void) triggerInitialize;

@end

@implementation WinIPhone

+ (void) triggerInitialize {
	// do nothing
}

+ (void) initialize {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
								@"YES", kOptionAutopickup,
								@"$\"=/!?+", kOptionPickupTypes,
								@"YES", kOptionAutokick,
								@"YES", kOptionShowExp,
								@"YES", kOptionTime,
								@"YES", kOptionAutoDig,
								nil]];
}

@end

FILE *iphone_fopen(const char *filename, const char *mode) {
	NSString *path = [[NSBundle mainBundle]
					  pathForResource:[NSString stringWithCString:filename encoding:NSASCIIStringEncoding] ofType:@""];
	const char *pathc = [path fileSystemRepresentation];
	FILE *file = fopen(pathc, mode);
	return file;
}

// These must be defined but are not used (they handle keyboard interrupts).
void intron() {}
void introff() {}

int dosuspend() {
	//NSLog(@"dosuspend");
	return 0;
}

int dosh() {
	//NSLog(@"dosh");
	return 0;
}

void error(const char *s, ...) {
	//NSLog(@"error: %s");
	exit(0);
}

void regularize(char *s) {
	register char *lp;

	for (lp = s; *lp; lp++) {
		if (*lp == '.' || *lp == ':')
			*lp = '_';
	}
}

int child(int wt) {
	//NSLog(@"child %d", wt);
	return 0;
}

#pragma mark nethack window system API

void iphone_init_nhwindows(int* argc, char** argv) {
	iflags.window_inited = TRUE;
}

void iphone_player_selection() {
	//strcpy(pl_character, "Barb");
	[[MainViewController instance] doPlayerSelection];
}

void iphone_askname() {
	if (!wizard) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *name = [defaults objectForKey:kOptionUsername];
		if (!name || name.length == 0) {
			name = [NSFullUserName() capitalizedString];
			[defaults setObject:name forKey:kOptionUsername];
		}
		// issue 33 patch provided by ciawal
		if(![name getCString:plname maxLength:PL_NSIZ encoding:NSASCIIStringEncoding]) {
			// If the conversion fails attempt to perform a lossy conversion instead
			NSData* lossyName = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			[lossyName getBytes:plname length:PL_NSIZ-1];
			plname[lossyName.length] = 0;
		}
		NSCAssert1(plname[0], @"Failed to init plname from name '%@'", name);
	} else {
		strcpy(plname, "wizard");
	}
}

void iphone_get_nh_event() {
	//NSLog(@"iphone_get_nh_event");
}

void iphone_exit_nhwindows(const char *str) {
	// please don't touch this without previous discussion dirkz
	NSLog(@"iphone_exit_nhwindows %s", str);
}

void iphone_suspend_nhwindows(const char *str) {
	NSLog(@"iphone_suspend_nhwindows %s", str);
}

void iphone_resume_nhwindows() {
	NSLog(@"iphone_resume_nhwindows");
}

winid iphone_create_nhwindow(int type) {
	winid wid = [[MainViewController instance] createWindow:type];
	//NSLog(@"iphone_create_nhwindow(%d) -> %d", type, wid);
	return wid;
}

void iphone_clear_nhwindow(winid wid) {
	//NSLog(@"iphone_clear_nhwindow %d", wid);
	Window *w = [[MainViewController instance] windowWithId:wid];
	[w clear];
}

void iphone_display_nhwindow(winid wid, BOOLEAN_P block) {
	//NSLog(@"iphone_display_nhwindow %d", wid);
	[[MainViewController instance] displayWindowId:wid blocking:block ? YES:NO];
}

void iphone_destroy_nhwindow(winid wid) {
	//NSLog(@"iphone_destroy_nhwindow %d", wid);
	[[MainViewController instance] destroyWindow:wid];
}

void iphone_curs(winid wid, int x, int y) {
	//NSLog(@"iphone_curs %d %d,%d", wid, x, y);
}

void iphone_putstr(winid wid, int attr, const char *text) {
	//NSLog(@"iphone_putstr %d %s", wid, text);
	Window *w = [[MainViewController instance] windowWithId:wid];
	[w putString:text];
}

void iphone_display_file(const char *filename, BOOLEAN_P must_exist) {
	//NSLog(@"iphone_display_file %s", filename);
	[[MainViewController instance] displayFile:[NSString stringWithCString:filename encoding:NSASCIIStringEncoding]
									 mustExist:must_exist ? YES : NO];
}

void iphone_start_menu(winid wid) {
	//NSLog(@"iphone_start_menu %d", wid);
	Window *w = [[MainViewController instance] windowWithId:wid];
	[w startMenu];
}

void iphone_add_menu(winid wid, int glyph, const ANY_P *identifier,
					 CHAR_P accelerator, CHAR_P group_accel, int attr, 
					 const char *str, BOOLEAN_P presel) {
	//NSLog(@"iphone_add_menu %d %s", wid, str);
	NethackMenuItem *i = [[NethackMenuItem alloc] initWithId:identifier title:str glyph:glyph preselected:presel?YES:NO];
	Window *w = [[MainViewController instance] windowWithId:wid];
	[w addMenuItem:i];
	[i release];
}

void iphone_end_menu(winid wid, const char *prompt) {
	//NSLog(@"iphone_end_menu %d, %s", wid, prompt);
	if (prompt) {
		Window *w = [[MainViewController instance] windowWithId:wid];
		w.menuPrompt = [NSString stringWithCString:prompt encoding:NSASCIIStringEncoding];
	}
}

int iphone_select_menu(winid wid, int how, menu_item **selected) {
	//NSLog(@"iphone_select_menu %x", wid);
	Window *w = [[MainViewController instance] windowWithId:wid];
	w.menuHow = how;
	[[MainViewController instance] displayMenuWindow:w];
	*selected = w.menuList;
	//NSLog(@"iphone_select_menu -> %d", w.menuResult);
	w.menuPrompt = nil;
	return w.menuResult;
}

void iphone_update_inventory() {
	//NSLog(@"iphone_update_inventory");
}

void iphone_mark_synch() {
	//NSLog(@"iphone_mark_synch");
}

void iphone_wait_synch() {
	//NSLog(@"iphone_wait_synch");
}

void iphone_cliparound(int x, int y) {
	//NSLog(@"iphone_cliparound %d,%d", x, y);
	MainViewController *v = [MainViewController instance];
	v.clip.x = x;
	v.clip.y = y;
}

void iphone_cliparound_window(winid wid, int x, int y) {
	NSLog(@"iphone_cliparound_window %d %d,%d", wid, x, y);
}

void iphone_print_glyph(winid wid, XCHAR_P x, XCHAR_P y, int glyph) {
	//NSLog(@"iphone_print_glyph %d %d,%d", wid, x, y);
	Window *w = [[MainViewController instance] windowWithId:wid];
	[w setGlyph:glyph atX:x y:y];
}

void iphone_raw_print(const char *str) {
	if (strlen(str)) {
		NSLog(@"raw_print %s", str);
		winid window = create_nhwindow(NHW_TEXT);
		putstr(window, ATR_NONE, str);
		display_nhwindow(window, true);
		destroy_nhwindow(window);
	}
}

void iphone_raw_print_bold(const char *str) {
	if (strlen(str)) {
		NSLog(@"raw_print_bold %s", str);
		winid window = create_nhwindow(NHW_TEXT);
		putstr(window, ATR_BOLD, str);
		display_nhwindow(window, true);
		destroy_nhwindow(window);
	}
}

int iphone_nhgetch() {
	NSLog(@"iphone_nhgetch");
	return 0;
}

int iphone_nh_poskey(int *x, int *y, int *mod) {
	//NSLog(@"iphone_nh_poskey");
	NethackEvent *e = [[[MainViewController instance] nethackEventQueue] waitForNextEvent];
	*x = e.x;
	*y = e.y;
	*mod = CLICK_1;
	return e.key;
}

void iphone_nhbell() {}

// message log is accessible from the menu, so we don't really need it here
int iphone_doprev_message() {
	//NSLog(@"iphone_doprev_message");
	return 0;
}

// expands stuff like 'a-c' into 'abc'
static NSString *expandInventoryLetters(NSString *lets) {
	NSMutableString *res = [NSMutableString string];
	char lastChar;
	BOOL isRange = NO;
	for (int i = 0; i < lets.length; ++i) {
		char c = [lets characterAtIndex:i];
		if (isRange) {
			for (char ch = lastChar+1; ch <= c; ++ch) {
				[res appendString:[NSString stringWithFormat:@"%c", ch]];
			}
			isRange = NO;
		} else if (c == '-' && lastChar) {
			isRange = YES;
		} else {
			[res appendString:[NSString stringWithFormat:@"%c", c]];
			lastChar = c;
		}
	}
	//NSLog(@"expandInventoryLetters(@%) -> %@", lets, res);
	return res;
}

char iphone_yn_function(const char *question, const char *choices, CHAR_P def) {
	NSLog(@"iphone_yn_function %s", question);
	[[MainViewController instance] updateScreen];
	if (!choices) {
		NSString *s = [NSString stringWithCString:question encoding:NSASCIIStringEncoding];
		if ([s containsString:@"direction"]) {
			return [[MainViewController instance] getDirectionInput];
		} else {
			NSString *q = [NSString stringWithCString:question encoding:NSASCIIStringEncoding];
			NSString *preLets = [q substringBetweenDelimiters:@"[]"];
			if (preLets && preLets.length > 0) {
				Window *inventoryWindow = [[MainViewController instance] windowWithId:WIN_INVEN];
				inventoryWindow.nethackMenuItem = nil;
				BOOL alphaBegan = NO;
				BOOL terminateLoop = NO;
				int index;
				int start=0; //iNethack2: initializing this as it was causing a crash when bringing up screens with no inventory options
				for (int i = 0; i < preLets.length && !terminateLoop; ++i) {
					index = i;
					char c = [preLets characterAtIndex:i];
					if (!alphaBegan) {
						switch (c) {
							case '$':
								inventoryWindow.acceptMoney = YES;
								break;
							case '-':
								inventoryWindow.acceptBareHanded = YES;
								break;
							default:
								if (isalpha(c)) {
									start = i;
									alphaBegan = YES;
								}
								break;
						}
					} else {
						if (c == ' ') {
							terminateLoop = YES;
						}
					}
				}
				if (!terminateLoop) {
					index++;
				}
				NSRange r = NSMakeRange(start, index-start);
				NSString *lets = [preLets substringWithRange:r];
				r = [preLets rangeOfString:@"or "];
				if (r.location != NSNotFound) {
					NSString *moreOptions = [preLets substringFromIndex:r.location+r.length];
					for (int i = 0; i < moreOptions.length; ++i) {
						char c = [moreOptions characterAtIndex:i];
						if (c == '*') {
							inventoryWindow.acceptMore = YES;
						}
					}
				}
				lets = expandInventoryLetters(lets);
				inventoryWindow.menuPrompt = q;
				char c = display_inventory([lets cStringUsingEncoding:NSASCIIStringEncoding], TRUE);
				inventoryWindow.acceptMoney      = NO;
				inventoryWindow.acceptBareHanded = NO;
				inventoryWindow.acceptMore       = NO;
				if (inventoryWindow.nethackMenuItem && inventoryWindow.nethackMenuItem.amount != -1) {
					int amount = inventoryWindow.nethackMenuItem.amount;
					inventoryWindow.nethackMenuItem = nil;
					NSString *stringAmount = [NSString stringWithFormat:@"%d%c", amount, c];
					c = [stringAmount characterAtIndex:0];
					for (int i = 1; i < stringAmount.length; ++i) {
						char ch = [stringAmount characterAtIndex:i];
						[[[MainViewController instance] nethackEventQueue] addKeyEvent:ch];
					}
					return c;
				} else {
					return c;
				}
			} else {
				// no preLets defined ([])
				iphone_putstr(WIN_MESSAGE, ATR_NONE, question);
				[[MainViewController instance] updateScreen];
				[[MainViewController instance] showKeyboard:YES];
				NethackEvent *e = [[[MainViewController instance] nethackEventQueue] waitForNextEvent];
				[[MainViewController instance] showKeyboard:NO];
				return e.key;
			}
		}
	} else {
		NSString *s = [NSString stringWithCString:question encoding:NSASCIIStringEncoding];
		if ([s isEqualToString:@"Really save?"] || [s isEqualToString:@"Overwrite the old file?"]) {
			return 'y';
		} 
		NethackYnFunction *yn = [[NethackYnFunction alloc] initWithQuestion:question choices:choices defaultChoice:def];
		[[MainViewController instance] displayYnQuestion:yn];
		[yn autorelease];
		return yn.choice;
	}
}

void iphone_getlin(const char *prompt, char *line) {
	//NSLog(@"iphone_getlin %s", prompt);
	[[MainViewController instance] getLine:line prompt:prompt];
}

int iphone_get_ext_cmd() {
	return [[MainViewController instance] getExtendedCommand];
}

void iphone_number_pad(int num) {
	//NSLog(@"iphone_number_pad %d", num);
}

void iphone_delay_output() {
	//NSLog(@"iphone_delay_output");
}

void iphone_start_screen() {
	//NSLog(@"iphone_start_screen");
}

void iphone_end_screen() {
	//NSLog(@"iphone_end_screen");
}

void iphone_outrip(winid wid, int how) {
	//NSLog(@"iphone_outrip %d", wid);
}

#pragma mark options

void iphone_init_options() {
	[WinIPhone triggerInitialize];
	iflags.use_color = TRUE;
	iflags.runmode = RUN_STEP;
	flags.verbose = TRUE;
	flags.toptenwin = TRUE;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	flags.pickup = [defaults boolForKey:kOptionAutopickup];
	NSString *pickupTypes = [defaults objectForKey:kOptionPickupTypes];
	if (flags.pickup && pickupTypes) {
		NSMutableString *tmp = [NSMutableString string];
		for (int i = 0; i < pickupTypes.length; ++i) {
			int oc_sym = def_char_to_objclass([pickupTypes characterAtIndex:i]);
			if (![tmp containsChar:oc_sym]) {
				[tmp appendFormat:@"%c", oc_sym];
			}
		}
		[tmp getCString:flags.pickup_types maxLength:MAXOCLASSES encoding:NSASCIIStringEncoding];
	}
#if TARGET_IPHONE_SIMULATOR
	wizard = NO; //akolade YES for sim usually..
#else
	wizard = [defaults boolForKey:kOptionWizard];
#endif
	winiphone_autokick = [defaults boolForKey:kOptionAutokick];
	flags.showexp = [defaults boolForKey:kOptionShowExp];
	flags.time = [defaults boolForKey:kOptionTime];
	flags.autodig = [defaults boolForKey:kOptionAutoDig];
}

void iphone_override_options() {
	// somehow the flags seem to be erased (after restore?)
	// so just call it again
	iphone_init_options();
}

void process_options(int argc, char *argv[]) {
}

#pragma mark main

void iphone_remove_stale_files() {
	NSString *pattern = [NSString stringWithFormat:@"%d%s", getuid(),
						 [NSUserName() cStringUsingEncoding:NSASCIIStringEncoding]];

    NSArray *filelist= [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"." error:nil];
    
	for (NSString *filename in filelist) {
		if ([filename startsWithString:pattern]) {
			int fail = unlink([filename fileSystemRepresentation]);
			if (!fail) {
				NSLog(@"removed %@", filename);
			} else {
				NSLog(@"failure to remove %@", filename);
			}
		}
	}
}

void
getlock(void)
{
	int fd;
	int pid = getpid(); /* Process ID */

	set_levelfile_name(lock, 0);

	const char* fq_lock = fqname(lock, LEVELPREFIX, 1);
	if ((fd = open(lock, O_RDWR | O_EXCL | O_CREAT, 0644)) == -1) {
		char c = yn("There are files from a game in progress. Recover?");
		if (c != 'y' && c != 'Y') {
			int fail = unlink(lock);
			if (!fail) {
				iphone_remove_stale_files();
				fd = open(lock, O_RDWR | O_EXCL | O_CREAT, 0644);
				delete_savefile();
			} else {
				panic("Failed to unlink %s", lock);
			}
		} else {
			// Try to recover
			if(!recover_savefile()) {
				int fail = unlink(lock);
				NSCAssert1(!fail, @"Failed to unlink lock %s", lock);
				panic("Couldn't recover old game.");
			} else {
				set_levelfile_name(lock, 0);
				fd = open(fq_lock, O_RDWR | O_EXCL | O_CREAT, 0644);
			}
		}
	}
	
	if (write(fd, (char *)&pid, sizeof (pid)) != sizeof (pid))  {
		raw_printf("Could not lock the game %s.", lock);
		panic("Disk locked?");
	}
	close (fd);
}

void iphone_test_main() {
	// place for threaded tests
}

void iphone_test_endianness() {
	NSString *filename = @"endianness";
	const char *cFilename = [filename fileSystemRepresentation];
	int someInt = 42;
	[[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
	int fd = open(cFilename, O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR);
	write(fd, &someInt, sizeof(someInt));
	close(fd);
	NSLog(@"wrote %d", someInt);

	char buffer[4];
	fd = open(cFilename, O_RDONLY);
	read(fd, buffer, sizeof(buffer));
	close(fd);
	NSLog(@"read %d %d %d %d", buffer[0], buffer[1], buffer[2], buffer[3]);
	[[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
}

void iphone_will_load_bones(const char *bonesid) {
	//NSLog(@"load bones %s", bonesid);
	NSString *src = [NSString stringWithFormat:@"./bon%s", bonesid]; //iNethack2 prepending with ./
	NSString *dest = [NSString stringWithFormat:@"./bon%s.bad", bonesid]; //iNethack2 prepending with ./
	NSString *md5 = [Hearse md5HexForFile:src];
	NSError *error = nil;
	[md5 writeToFile:dest atomically:YES encoding:NSASCIIStringEncoding error:&error];
}

void iphone_finished_bones(const char *bonesid) {
	//NSLog(@"finished bones %s", bonesid);
	NSString *dest = [NSString stringWithFormat:@"bon%s.bad", bonesid];
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:dest error:&error];
}
//iNethack2: pass along the glyph cache reset
void iphone_reset_glyph_cache() {
	[[MainViewController instance] resetGlyphCache];
}


boolean
check_version_64(version_data, filename, complain)
struct version_info *version_data;
const char *filename;
boolean complain;
{
    unsigned long sanity2;
#if __LP64__
    sanity2=VERSION_SANITY2_64;
#else
    sanity2=VERSION_SANITY2;
#endif
    
    if (
#ifdef VERSION_COMPATIBILITY
        version_data->incarnation < VERSION_COMPATIBILITY ||
        version_data->incarnation > VERSION_NUMBER
#else
        version_data->incarnation != VERSION_NUMBER
#endif
        ) {
        if (complain)
            pline("Version mismatch for file \"%s\".", filename);
        return FALSE;
    } else if (
#ifndef IGNORED_FEATURES
               version_data->feature_set != VERSION_FEATURES ||
#else
               (version_data->feature_set & ~IGNORED_FEATURES) !=
               (VERSION_FEATURES & ~IGNORED_FEATURES) ||
#endif
               version_data->entity_count != VERSION_SANITY1 ||
               version_data->struct_sizes != sanity2) {
        if (complain)
            pline("Configuration incompatibility for file \"%s\".",
                  filename);
        return FALSE;
    }
    return TRUE;
}

/* this used to be based on file date and somewhat OS-dependant,
 but now examines the initial part of the file's contents */
boolean
uptodate_64(fd, name)
int fd;
const char *name;
{
    int rlen;
    struct version_info vers_info;
    boolean verbose = name ? TRUE : FALSE;
    
    rlen = read(fd, (genericptr_t) &vers_info, sizeof vers_info);
    minit();		/* ZEROCOMP */
    if (rlen == 0) {
        if (verbose) {
            pline("File \"%s\" is empty?", name);
            wait_synch();
        }
        return FALSE;
    }
    if (!check_version_64(&vers_info, name, verbose)) {
        if (verbose) wait_synch();
        return FALSE;
    }
    return TRUE;
}

void
store_version_64(fd)
int fd;
{
#if __LP64__
    const static struct version_info version_data = {
        VERSION_NUMBER, VERSION_FEATURES,
        VERSION_SANITY1, VERSION_SANITY2_64
    };
#else
    const static struct version_info version_data = {
        VERSION_NUMBER, VERSION_FEATURES,
        VERSION_SANITY1, VERSION_SANITY2
    };
#endif
    bufoff(fd);
    /* bwrite() before bufon() uses plain write() */
    bwrite(fd,(genericptr_t)&version_data,(unsigned)(sizeof version_data));
    bufon(fd);
    return;
}

void iphone_main() {
	int argc = 0;
	char **argv = NULL;
	
	// from macmain.c, enables special levels like sokoban
	x_maze_max = COLNO-1;
	if (x_maze_max % 2) {
		x_maze_max--;
	}
	y_maze_max = ROWNO-1;
	if (y_maze_max % 2) {
		y_maze_max--;
	}

	hackpid = getpid();
	
	choose_windows(DEFAULT_WINDOW_SYS); /* choose a default window system */
	initoptions();			   /* read the resource file */
	init_nhwindows(&argc, argv);		   /* initialize the window system */
	process_options(argc, argv);	   /* process command line options or equiv */
	iphone_init_options();

    NSString* logFilePath =	[[NSString alloc] initWithCString:LOGFILE encoding:NSASCIIStringEncoding];

    logFilePath = [NSString stringWithFormat:@"./%@", logFilePath]; //iNethack2 -- fix for iOS8.. needs full path
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
		[[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
	}
	[logFilePath release];

	check_recordfile("");

	dlb_init();
	vision_init();
	display_gamewindows();		   /* create & display the game windows */

	Sprintf(lock, "%d%s", getuid(), [NSUserName() cStringUsingEncoding:NSASCIIStringEncoding]);
	getlock();

	register int fd;
	if ((fd = restore_saved_game()) >= 0) {
#ifdef WIZARD
		/* Since wizard is actually flags.debug, restoring might
		 * overwrite it.
		 */
		boolean remember_wiz_mode = wizard;
#endif
		//(void) chmod(fq_save,0);	/* disallow parallel restores */
		(void) signal(SIGINT, (SIG_RET_TYPE) done1);
#ifdef NEWS
		if(iflags.news) {
		    display_file(NEWS, FALSE);
		    iflags.news = FALSE; /* in case dorecover() fails */
		}
#endif
		pline("Restoring save file...");
		mark_synch();	/* flush output */
		if(!dorecover(fd))
			goto not_recovered;
#ifdef WIZARD
		if(!wizard && remember_wiz_mode) wizard = TRUE;
#endif
		check_special_room(FALSE);
		//wd_message();
		
		if (discover || wizard) {
			if(yn("Do you want to keep the save file?") == 'n') {
			    (void) delete_savefile();
			}
			else {
			    //(void) chmod(fq_save,FCMASK); /* back to readable */
				// compress only works in the sim
			    //compress(fq_save);
			}
		}
		flags.move = 0;
	} else {
	not_recovered:
		player_selection();
		newgame();
		//wd_message();
		
		flags.move = 0;
		set_wear();
		(void) pickup(1);
	}
	
	iphone_override_options();
	[[MainViewController instance] setGameInProgress:YES];
	moveloop();
	[[MainViewController instance] setGameInProgress:NO];
	exit(EXIT_SUCCESS);
}