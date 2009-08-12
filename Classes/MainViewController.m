//
//  MainViewController.m
//  iNetHack
//
//  Created by dirk on 6/26/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

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

#import "MainViewController.h"
#import "MainView.h"
#import "winiphone.h"
#import "Window.h"
#import "MenuViewController.h"
#import "MenuItem.h"
#import "NethackMenuViewController.h"
#import "NethackYnFunction.h"
#import "TextInputViewController.h"
#import "NethackEvent.h"
#import "NethackEventQueue.h"
#import "DirectionInputViewController.h"
#import "ExtendedCommandViewController.h"
#import "RoleSelectionViewController.h"
#import "TextDisplayViewController.h"
#import "TilePosition.h"
#import "TouchInfo.h"
#import "TouchInfoStore.h"
#import "NetHackMenuInfo.h"
#import "DMath.h"
#import "NSString+Regexp.h"

static MainViewController *_instance;

@implementation MainViewController

@synthesize windows, clip, nethackEventQueue;
@synthesize nethackMenuInfo;

+ (id) instance {
	return _instance;
}

+ (void) message:(NSString *)format, ... {
	va_list arg_list;
	va_start(arg_list, format);
	NSString *msg = [[NSString alloc] initWithFormat:format arguments:arg_list];
	va_end(arg_list);
	[[[self instance] messageWindow] putString:[msg cStringUsingEncoding:NSASCIIStringEncoding]];
	[msg release];
}

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	touchInfoStore = [[TouchInfoStore alloc] init];
	self.title = @"Dungeon";
	windows = [[NSMutableArray alloc] init];
	nethackEventQueue = [[NethackEventQueue alloc] init];
	uiCondition = [[NSCondition alloc] init];
	textInputCondition = [[NSCondition alloc] init];
	tapRect = CGRectMake(-25, -25, 50, 50);
	_instance = self;
	lastSingleTapDelta = [[TilePosition alloc] init];
	clip = [[TilePosition alloc] init];
	dmath = [[DMath alloc] init];

	NSThread *nethackThread = [[NSThread alloc] initWithTarget:self selector:@selector(mainNethackLoop:) object:nil];
	[nethackThread start];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
	[self.view setNeedsDisplay];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.view setNeedsLayout];
}

- (void) mainNethackLoop:(id)arg {
	NSLog(@"starting nethack thread");
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	iphone_main();
	[pool release];
}

#pragma mark window properties

- (Window *) mapWindow {
	for (Window *w in windows) {
		if (w.type == NHW_MAP) {
			return w;
		}
	}
	return nil;
}

- (Window *) statusWindow {
	for (Window *w in windows) {
		if (w.type == NHW_STATUS) {
			return w;
		}
	}
	return nil;
}

- (Window *) messageWindow {
	for (Window *w in windows) {
		if (w.type == NHW_MESSAGE) {
			return w;
		}
	}
	return nil;
}

#pragma mark commands

- (void) nethackSearchCountEntered:(id)tf {
	NSString *s = ((UITextField *) tf).text;
	for (int i = 0; i < s.length; ++i) {
		char c = [s characterAtIndex:i];
		[nethackEventQueue addKeyEvent:c];
	}
	[nethackEventQueue addKeyEvent:'s'];
}

- (void) nethackSearch:(id)i {
	SEL sel = @selector(nethackSearchCountEntered:);
	NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:sel]];
	inv.selector = sel;
	inv.target = self;
	textInputViewController.callOnSuccess = inv;
	textInputViewController.prompt = @"Enter search count";
	textInputViewController.text = @"20";
	[self.navigationController pushViewController:textInputViewController animated:YES];
}

- (void) nethackKeyboard:(id)i {
	[self.navigationController popToRootViewControllerAnimated:NO];
	UITextField *tf = ((MainView *) self.view).dummyTextField;
	[tf becomeFirstResponder];
}

- (void) pushViewControllerOnMainThread:(UIViewController *)viewController
{
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.navigationController pushViewController:viewController animated:YES];
}

- (void) displayText:(NSString *)text withCondition:(NSCondition *)condition {
	TextDisplayViewController* viewController = [TextDisplayViewController new];
	viewController.text = text;
	viewController.condition = condition;
	[self performSelectorOnMainThread:@selector(pushViewControllerOnMainThread:) withObject:viewController waitUntilDone:YES];
	[viewController release];
}

- (void) nethackShowLog:(id)i {
	NSString *text = @"";
	for (NSString *l in self.messageWindow.log) {
		NSString *s = nil;
		if (text.length > 0) {
			s = [NSString stringWithFormat:@"\n%@", l];
		} else {
			s = l;
		}
		text = [NSString stringWithFormat:@"%@%@", text, s];
	}
	[self displayText:text withCondition:nil];
}

- (void) nethackShowLicense:(id)i {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"license" ofType:@""];
	NSString *text = [NSString stringWithContentsOfFile:path];
	[self displayText:text withCondition:nil];
}

- (void) showCredits:(id)obj {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"credits" ofType:@"html"];
	TextDisplayViewController* viewController = [TextDisplayViewController new];
	viewController.text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	viewController.isHTML = YES;
	[self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}

- (void) showMainMenu:(id)obj {
	NSMutableArray *menuItems = [NSMutableArray array];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Show Log" target:self
											selector:@selector(nethackShowLog:) arg:nil accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"License" target:self
											selector:@selector(nethackShowLicense:) arg:nil accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"History" key:'V' accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Credits" target:self
											selector:@selector(showCredits:) arg:nil accessory:YES]];
#ifdef WIZARD
	if (wizard) {
		[menuItems addObject:[MenuItem menuItemWithTitle:@"Wizard"
												children:[NSArray arrayWithObjects:
														  [MenuItem menuItemWithTitle:@"Detect Secrets"
																				  key:C('e') accessory:NO],
														  [MenuItem menuItemWithTitle:@"Magic Mapping"
																				  key:C('f') accessory:NO],
														  [MenuItem menuItemWithTitle:@"Create Monster"
																				  key:C('g') accessory:NO],
														  [MenuItem menuItemWithTitle:@"Identify"
																				  key:C('i') accessory:NO],
														  [MenuItem menuItemWithTitle:@"Special Levels"
																				  key:C('o') accessory:NO],
														  [MenuItem menuItemWithTitle:@"Intra-Level Teleport"
																				  key:C('t') accessory:YES],
														  [MenuItem menuItemWithTitle:@"Trans-Level Teleport"
																				  key:C('v') accessory:YES],
														  [MenuItem menuItemWithTitle:@"Wish"
																				  key:C('w') accessory:YES],
														  nil]]];
	}
#endif
	menuViewController.menuItems = menuItems;
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.navigationController pushViewController:menuViewController animated:YES];
}

#pragma mark touch handling

- (char) directionFromTilePositionDelta:(TilePosition *)d {
	char direction = 0;
	if (d.x > 0 && d.y > 0) {
		// bottom right
		direction = 'n';
	} else if (d.x < 0 && d.y > 0) {
		// bottom left
		direction = 'b';
	} else if (d.x > 0 && d.y == 0) {
		// right
		direction = 'l';
	} else if (d.x < 0 && d.y == 0) {
		// left
		direction = 'h';
	} else if (d.x == 0 && d.y > 0) {
		// down
		direction = 'j';
	} else if (d.x == 0 && d.y < 0) {
		// up
		direction = 'k';
	} else if (d.x < 0 && d.y < 0) {
		// top left
		direction = 'y';
	} else if (d.x > 0 && d.y < 0) {
		// top right
		direction = 'u';
	}
	return direction;
}

// obsolete
- (char) directionFromDMathDirection:(dmathdirection)dmdir {
	char direction = 0;
	switch (dmdir) {
		case kUp:
			direction = 'k';
			break;
		case kUpRight:
			direction = 'u';
			break;
		case kRight:
			direction = 'l';
			break;
		case kDownRight:
			direction = 'n';
			break;
		case kDown:
			direction = 'j';
			break;
		case kDownLeft:
			direction = 'b';
			break;
		case kLeft:
			direction = 'h';
			break;
		case kUpLeft:
			direction = 'y';
			break;
	}
	return direction;
}

- (void) moveTilePosition:(TilePosition *)tp intoDMathDirection:(dmathdirection)dmdir {
	// dmdir is cartesian, tp is not ...
	switch (dmdir) {
		case kUp:
			tp.y--;
			break;
		case kUpRight:
			tp.x++;
			tp.y--;
			break;
		case kRight:
			tp.x++;
			break;
		case kDownRight:
			tp.x++;
			tp.y++;
			break;
		case kDown:
			tp.y++;
			break;
		case kDownLeft:
			tp.x--;
			tp.y++;
			break;
		case kLeft:
			tp.x--;
			break;
		case kUpLeft:
			tp.x--;
			tp.y--;
			break;
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[touchInfoStore storeTouches:touches];
	if (touches.count == 1) {
		UITouch *touch = [touches anyObject];
		if (touch.tapCount == 2) {
			TouchInfo *ti = [touchInfoStore touchInfoForTouch:touch];
			ti.doubleTap = YES;
		}
		[self.view setNeedsDisplay];
	} else if (touches.count == 2) {
		NSArray *allTouches = [touches allObjects];
		UITouch *t1 = [allTouches objectAtIndex:0];
		UITouch *t2 = [allTouches objectAtIndex:1];
		CGPoint p1 = [t1 locationInView:self.view];
		CGPoint p2 = [t2 locationInView:self.view];
		CGPoint d = CGPointMake(p2.x-p1.x, p2.y-p1.y);
		initialDistance = sqrt(d.x*d.x + d.y*d.y);
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (touchInfoStore.count == touches.count) {
		if (touches.count == 1) {
			UITouch *touch = [touches anyObject];
			TouchInfo *ti = [touchInfoStore touchInfoForTouch:[touches anyObject]];
			if (!ti.pinched) {
				CGPoint p = [touch locationInView:self.view];
				CGPoint delta = CGPointMake(p.x-ti.currentLocation.x, p.y-ti.currentLocation.y);
				BOOL move = NO;
				if (!ti.moved && (abs(delta.x)+abs(delta.y) > 10)) {
					ti.moved = YES;
					move = YES;
				} else if (ti.moved) {
					move = YES;
				}
				if (move) {
					[(MainView *) self.view moveAlongVector:delta];
					ti.currentLocation = p;
					[self.view setNeedsDisplay];
				}
			}
		} else if (touches.count == 2) {
			for (UITouch *t in touches) {
				TouchInfo *ti = [touchInfoStore touchInfoForTouch:t];
				ti.pinched = YES;
			}
			NSArray *allTouches = [touches allObjects];
			UITouch *t1 = [allTouches objectAtIndex:0];
			UITouch *t2 = [allTouches objectAtIndex:1];
			CGPoint p1 = [t1 locationInView:self.view];
			CGPoint p2 = [t2 locationInView:self.view];
			CGPoint d = CGPointMake(p2.x-p1.x, p2.y-p1.y);
			CGFloat currentDistance = sqrt(d.x*d.x + d.y*d.y);
			if (initialDistance == 0) {
				initialDistance = currentDistance;
			} else if (currentDistance-initialDistance > kMinimumPinchDelta) {
				// zoom (in)
				CGFloat zoom = currentDistance-initialDistance;
				[(MainView *) self.view zoom:zoom];
				initialDistance = currentDistance;
			} else if (initialDistance-currentDistance > kMinimumPinchDelta) {
				// zoom (out)
				CGFloat zoom = currentDistance-initialDistance;
				[(MainView *) self.view zoom:zoom];
				initialDistance = currentDistance;
			}
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[touchInfoStore removeTouches:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (touches.count == 1) {
		TouchInfo *ti = [touchInfoStore touchInfoForTouch:[touches anyObject]];
		if (!ti.pinched && !ti.moved && !ti.doubleTap) {
			UITouch *touch = [touches anyObject];
			if (touch.tapCount == 1) {
				CGPoint p = [touch locationInView:self.view];
				TilePosition *tp = [(MainView *) self.view tilePositionFromPoint:p];
				NethackEvent *lastEvent = nethackEventQueue.lastEvent;
				// todo other events to check
				if ([(MainView *) self.view isMoved] || lastEvent.key == ';') {
					// tappable tiles if view is being panned
					// ignore clicks into the dark
					lastSingleTapDelta.x = tp.x-u.ux;
					lastSingleTapDelta.y = tp.y-u.uy;
					NethackEvent *e = [[NethackEvent alloc] init];
					e.x = tp.x;
					e.y = tp.y;
					e.key = 0;
					[nethackEventQueue addNethackEvent:e];
					[e release];
					[(MainView *) self.view resetOffset];
					[self.view setNeedsDisplay];
				} else {
					CGSize tileSize = CGSizeMake(40,40);
					CGRect middleSquare = CGRectMake(self.view.bounds.size.width/2-tileSize.width/2,
													 self.view.bounds.size.height/2-tileSize.height/2, 40, 40);
					if (CGRectContainsPoint(middleSquare, p)) {
						// tap on player (center) tile
						lastSingleTapDelta.x = 0;
						lastSingleTapDelta.y = 0;
						NethackEvent *e = [[NethackEvent alloc] init];
						e.x = tp.x;
						e.y = tp.y;
						e.key = 0;
						[nethackEventQueue addNethackEvent:e];
						[e release];
						[(MainView *) self.view resetOffset];
						[self.view setNeedsDisplay];
					} else {
						// direction based movement
						CGPoint center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
						CGPoint pointDelta = CGPointMake(p.x-center.x, p.y-center.y);
						pointDelta.y *= -1;
						pointDelta = [DMath normalizedPoint:pointDelta];
						dmathdirection dmdir = [dmath directionFromVector:pointDelta];
						TilePosition *tp = [TilePosition tilePositionWithX:u.ux y:u.uy];
						[self moveTilePosition:tp intoDMathDirection:dmdir];
						lastSingleTapDelta.x = tp.x-u.ux;
						lastSingleTapDelta.y = tp.y-u.uy;
						NethackEvent *e = [[NethackEvent alloc] init];
						e.x = tp.x;
						e.y = tp.y;
						e.key = 0;
						[nethackEventQueue addNethackEvent:e];
						[e release];
						[(MainView *) self.view resetOffset];
						[self.view setNeedsDisplay];
					}
				}
			}
		} else if (!ti.pinched && !ti.moved && ti.doubleTap) {
			TilePosition *delta = lastSingleTapDelta;
			if ((abs(delta.x) == 0 || abs(delta.x) == 1) && (abs(delta.y) == 0) || abs(delta.y) == 1) {
				char direction = [self directionFromTilePositionDelta:delta];
				if (direction) {
					[nethackEventQueue addKeyEvent:'g'];
					[nethackEventQueue addKeyEvent:direction];
				}
			}
		}
	}
	initialDistance = 0;
	[touchInfoStore removeTouches:touches];
}

#pragma mark windowing

- (winid) createWindow:(int)type {
	Window *w = [[Window alloc] initWithType:type];
	[windows addObject:w];
	[w release];
	return (winid) w;
}

- (void) destroyWindow:(winid)wid {
	Window *w = (Window *) wid;
	[windows removeObject:w];
}

- (Window *) windowWithId:(winid)wid {
	return (Window *) wid;
}

- (void) displayWindowId:(winid)wid blocking:(BOOL)blocking {
	Window *w = [self windowWithId:wid];
	if (w.type == NHW_MENU || w.type == NHW_TEXT && blocking) {
		if ((w.type == NHW_TEXT || w.type == NHW_MENU) && w.strings.count > 0) {
			[uiCondition lock];
			[self performSelectorOnMainThread:@selector(displayMessage:) withObject:w waitUntilDone:YES];
			[uiCondition wait];
			[uiCondition unlock];
		}
	} else if (w.type == NHW_MAP) {
		[self.view performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
	}
}

- (void) displayMessage:(Window *)w {
	NSString *text = w.text;
	//NSLog(@"displaying text %@", text);
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:text
												   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

- (void) displayMenuWindow:(Window *)w {
	[uiCondition lock];
	[self performSelectorOnMainThread:@selector(displayMenuWindowOnUIThread:) withObject:w waitUntilDone:YES];
	[uiCondition wait];
	[uiCondition unlock];
}

- (void) displayMenuWindowOnUIThread:(Window *)w {
	nethackMenuViewController.menuWindow = w;
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.navigationController pushViewController:nethackMenuViewController animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//NSLog(@"alert finished");
	[alertView release];
	[self broadcastUIEvent];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	currentYnFunction.chosen = buttonIndex;
	[self broadcastUIEvent];
	[actionSheet release];
	currentYnFunction = nil;
}

- (void) displayYnQuestion:(NethackYnFunction *)yn {
	[uiCondition lock];
	[self performSelectorOnMainThread:@selector(displayYnQuestionOnUIThread:) withObject:yn waitUntilDone:YES];
	[uiCondition wait];
	[uiCondition unlock];
}

- (void) displayYnQuestionOnUIThread:(NethackYnFunction *)yn {
	currentYnFunction = yn;
	UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:[NSString stringWithCString:yn.question]
													  delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil
											 otherButtonTitles:nil];
	const char *p = yn.choices;
	char c;
	while (c = *p++) {
		char str[] = {c,0};
		[menu addButtonWithTitle:[NSString stringWithCString:str]];
		//NSLog(@"added button %d %s", i, str);
	}
	[menu showInView:self.view];
}

- (void) getLine:(char *)line prompt:(const char *)p {
	NSString *s = [NSString stringWithCString:p];
	[self performSelectorOnMainThread:@selector(getLineOnUIThread:) withObject:s waitUntilDone:YES];
	[self waitForCondition:textInputCondition];
	s = textInputViewController.text;
	[s getCString:line maxLength:BUFSZ encoding:NSASCIIStringEncoding];
}

- (void) getLineOnUIThread:(NSString *)s {
	textInputCondition = [[NSCondition alloc] init];
	textInputViewController.condition = textInputCondition;
	textInputViewController.prompt = s;
	textInputViewController.text = @"Elbereth";
	[self.navigationController pushViewController:textInputViewController animated:YES];
}

- (char) getDirectionInput {
	[self performSelectorOnMainThread:@selector(showDirectionInputView:) withObject:nil waitUntilDone:YES];
	[self waitForCondition:uiCondition];
	[directionInputViewController.view removeFromSuperview];
	return directionInputViewController.direction;
}

- (void) showDirectionInputView:(id)obj {
	[self.view addSubview:directionInputViewController.view];
	directionInputViewController.view.frame = self.view.frame;
}

- (void) showExtendedCommandMenu:(id)obj {
	extendedCommandViewController.title = @"Extended Command";
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.navigationController pushViewController:extendedCommandViewController animated:YES];
}

- (int) getExtendedCommand {
	[self performSelectorOnMainThread:@selector(showExtendedCommandMenu:) withObject:nil waitUntilDone:YES];
	[self waitForCondition:uiCondition];
	return extendedCommandViewController.result;
}

- (void)didSelectAlignment:(id)sender {
	NSAssert([sender respondsToSelector:@selector(tag)], @"sender has no tag");
	flags.initalign = [sender tag];
	[self.navigationController popToRootViewControllerAnimated:NO];
	[[MainViewController instance] broadcastUIEvent];
}

- (void)showRoleSelectionController:(RoleSelectionViewController *)controller {
	if (controller.numberOfItems > 1) {
		[self.navigationController pushViewController:controller animated:self.navigationController.viewControllers.count > 1];
	} else {
		[self performSelector:controller.action withObject:controller];
	}
}

- (void)didSelectGender:(id)sender {
	NSAssert([sender respondsToSelector:@selector(tag)], @"sender has no tag");
	flags.initgend = [sender tag];

	// Set up alignment selection list
	RoleSelectionViewController* selectionController = [RoleSelectionViewController new];

	selectionController.title = @"Your Alignment?";
	selectionController.target = self;
	selectionController.action = @selector(didSelectAlignment:);
	for (int i = 0; i < ROLE_ALIGNS; i++) {
		if (validalign(flags.initrole, flags.initrace, i)) {
			[selectionController addItemWithTitle:[[NSString stringWithCString:aligns[i].adj] capitalizedString] tag:i];
		}
	}
	[self showRoleSelectionController:selectionController];

	[selectionController release];
}

- (void)didSelectRace:(id)sender {
	NSAssert([sender respondsToSelector:@selector(tag)], @"sender has no tag");
	pl_race = [sender tag];
	flags.initrace = [sender tag];

	// Set up gender selection list
	RoleSelectionViewController* selectionController = [RoleSelectionViewController new];

	selectionController.title = @"Your Gender?";
	selectionController.target = self;
	selectionController.action = @selector(didSelectGender:);
	for (int i = 0; i < ROLE_GENDERS; i++) {
		if (validgend(flags.initrole, flags.initrace, i)) {
			[selectionController addItemWithTitle:[[NSString stringWithCString:genders[i].adj] capitalizedString] tag:i];
		}
	}
	[self showRoleSelectionController:selectionController];

	[selectionController release];
}

- (void)didSelectRole:(id)sender {
	NSAssert([sender respondsToSelector:@selector(tag)], @"sender has no tag");
	flags.initrole = [sender tag];
	strcpy(pl_character, roles[flags.initrole].filecode);

	// Set up race selection list
	RoleSelectionViewController* selectionController = [RoleSelectionViewController new];

	selectionController.title = @"Your Race?";
	selectionController.target = self;
	selectionController.action = @selector(didSelectRace:);
	for (int i = 0; races[i].noun; i++) {
		if (validrace(flags.initrole, i)) {
			[selectionController addItemWithTitle:[[NSString stringWithCString:races[i].noun] capitalizedString] tag:i];
		}
	}
	[self showRoleSelectionController:selectionController];

	[selectionController release];
}

- (void) doPlayerSelectionOnUIThread:(id)obj {
	[self.navigationController setNavigationBarHidden:NO animated:YES];

	RoleSelectionViewController* selectionController = [RoleSelectionViewController new];

	selectionController.title = @"Your Role?";
	selectionController.target = self;
	selectionController.action = @selector(didSelectRole:);
	for (int i = 0; roles[i].name.m; ++i) {
		[selectionController addItemWithTitle:[NSString stringWithCString:roles[i].name.m] tag:i];
	}
	[self showRoleSelectionController:selectionController];
	[self.navigationController.navigationBar.topItem setHidesBackButton:YES animated:YES];

	[selectionController release];
}

- (void) doPlayerSelection {
	[self performSelectorOnMainThread:@selector(doPlayerSelectionOnUIThread:) withObject:nil waitUntilDone:YES];
	[self waitForCondition:uiCondition];
}

- (NSString *) askName {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *username = [defaults objectForKey:kOptionUsername];
	if (!username || username.length == 0) {
		username = [NSFullUserName() capitalizedString];
		[defaults setObject:username forKey:kOptionUsername];
	}
	return username;
}

- (void) displayFile:(NSString *)filename mustExist:(BOOL)e {
	if (![filename isEqualToString:@"news"]) {
		NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@""];
		if (path) {
			NSCondition *textDisplayCondition = [[NSCondition alloc] init];
			NSString *t = [NSString stringWithContentsOfFile:path];
			[self displayText:t withCondition:textDisplayCondition];
			[self waitForCondition:textDisplayCondition];
			[textDisplayCondition release];
		} else {
			if (e) {
				NSLog(@"error: could not find file %@ for display", filename);
			}
		}
	}
}

#pragma mark options

- (void) initOptions {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL autopickup = [defaults boolForKey:kOptionAutopickup];
	flags.pickup = autopickup ? TRUE:FALSE;
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
}

- (void) overrideOptions {
}

#pragma mark condition utilities

- (void) waitForUser {
	[uiCondition lock];
	[uiCondition wait];
	[uiCondition unlock];
}

- (void) broadcastUIEvent {
	[self broadcastCondition:uiCondition];
}

- (void) broadcastCondition:(NSCondition *)condition {
	[condition lock];
	[condition broadcast];
	[condition unlock];
}

- (void) waitForCondition:(NSCondition *)condition {
	[condition lock];
	[condition wait];
	[condition unlock];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

-  (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	for (int i = 0; i < string.length; ++i) {
		[nethackEventQueue addKeyEvent:[string characterAtIndex:i]];
	}
	[self broadcastUIEvent];
	return YES;
}

#pragma mark UINavigationControllerDelegate

/*
- (void)navigationController:(UINavigationController *)navigationController
	   didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	NSLog(@"did show %@", viewController);
}
 */

#pragma mark dealloc

- (void)dealloc {
	[touchInfoStore release];
	[uiCondition release];
	[textInputCondition release];
	[windows release];
	[lastSingleTapDelta release];
	[clip release];
	[dmath release];
    [super dealloc];
}

@end
