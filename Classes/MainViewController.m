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
#import "TextDisplayViewController.h"
#import "TilePosition.h"
#import "TouchInfo.h"
#import "TouchInfoStore.h"
#import "DMath.h"
#import "NSString+Regexp.h"
#import "RoleSelectionController.h"

#define kOptionDoubleTapSensitivity (@"doubleTapSensitivity")
#define kConstThingsThatAreHereTitle (@"Things that are here:")
#define kConstThingsThatYouFeelHereTitle (@"Things that you feel here:")

extern volatile boolean winiphone_clickable_tiles;

static MainViewController *instance;

@interface MainViewController () <RoleSelectionControllerDelegate>

@end

@implementation MainViewController

@synthesize windows, clip, nethackEventQueue;
@synthesize gameInProgress;

+ (MainViewController *) instance {
	return instance;
}

+ (void) message:(NSString *)format, ... {
	va_list arg_list;
	va_start(arg_list, format);
	NSString *msg = [[NSString alloc] initWithFormat:format arguments:arg_list];
	va_end(arg_list);
	[[[self instance] messageWindow] putString:[msg cStringUsingEncoding:NSASCIIStringEncoding]];
	[msg release];
}

- (void) awakeFromNib {
	[super awakeFromNib];
	touchInfoStore = [[TouchInfoStore alloc] init];
	self.title = @"Dungeon";
	//windows = [[NSMutableArray alloc] init];
    windows = [[NSMutableDictionary alloc] init]; //iNethack2 making this a dict
    windowIdCounter=1;
	nethackEventQueue = [[NethackEventQueue alloc] init];
	uiCondition = [[NSCondition alloc] init];
	textInputCondition = [[NSCondition alloc] init];
	tapRect = CGRectMake(-25, -25, 50, 50);
	instance = self;
	lastSingleTapDelta = [[TilePosition alloc] init];
	clip = [[TilePosition alloc] init];
	dmath = [[DMath alloc] init];
	
	// read options
	doubleTapSensitivity = [[NSUserDefaults standardUserDefaults] floatForKey:kOptionDoubleTapSensitivity];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	// the first time you rotate layoutSubivews doesn't get called :(
	// so make sure
	[self.view setNeedsLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
	[self.view becomeFirstResponder];
	[self.view setNeedsDisplay]; // seems necessary for shortcutview
}

- (void) launchNetHack {
	if (!nethackThread) {
		nethackThread = [[NSThread alloc] initWithTarget:self selector:@selector(mainNethackLoop:) object:nil];
		[nethackThread start];
	}
}

- (void) mainNethackLoop:(id)arg {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	iphone_main();
	[pool drain];
}

- (void) mainNethackTestLoop:(id)arg {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	iphone_test_main();
	[pool drain];
}

#pragma mark window properties

- (Window *) mapWindow {
	//for (Window *w in windows) {
    for (NSString* key in windows) {    //iNethack2 now a dict
        Window *w = [windows objectForKey:key];
        if (w.type == NHW_MAP) {
			return w;
		}
	}
	return nil;
}

- (Window *) statusWindow {
//	for (Window *w in windows) {
    for (NSString* key in windows) {    //iNethack2 now a dict
        Window *w = [windows objectForKey:key];
        if (w.type == NHW_STATUS) {
			return w;
		}
	}
	return nil;
}

- (Window *) messageWindow {
//	for (Window *w in windows) {
    for (NSString* key in windows) {    //iNethack2 now a dict
        Window *w = [windows objectForKey:key];
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
	textInputViewController.target = self;
	textInputViewController.action = @selector(nethackSearchCountEntered:);
	textInputViewController.prompt = @"Enter search count";
	textInputViewController.text = @"20";
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
	[self.navigationController pushViewController:textInputViewController animated:YES];
}

- (void) nethackKeyboard:(id)i {
	[self.navigationController popToRootViewControllerAnimated:NO];
	UITextField *tf = ((MainView *) self.view).dummyTextField;
	[tf becomeFirstResponder];
}

//iNethack2: call resetGlyphCache of MainView
- (void) resetGlyphCache {
    [(MainView *) self.view resetGlyphCache];
}

- (void) pushViewControllerOnMainThread:(UIViewController *)viewController
{
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void) displayText:(NSString *)text withCondition:(NSCondition *)condition isLog:(BOOL)l {
	TextDisplayViewController *viewController = [TextDisplayViewController new];
	viewController.log = l;
	viewController.text = text;
	viewController.condition = condition;
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self performSelectorOnMainThread:@selector(pushViewControllerOnMainThread:) withObject:viewController waitUntilDone:YES];
	[viewController release];
}

- (void) displayText:(NSString *)text withCondition:(NSCondition *)condition {
	[self displayText:text withCondition:condition isLog:NO];
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
	[self.messageWindow clearMessages];
	[self displayText:text withCondition:nil isLog:YES];
}

- (void) nethackShowLicense:(id)i {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"license" ofType:@""];
	NSString *text = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:NULL];
	[self displayText:text withCondition:nil];
}

- (void) nethackShowHistory:(id)i {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"history" ofType:@""];
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:NULL];
    [self displayText:text withCondition:nil];
}

- (void) showManual:(id)obj {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"manual" ofType:@"html"];
	TextDisplayViewController *viewController = [TextDisplayViewController new];
	viewController.text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	viewController.HTML = YES;
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}

- (void) showCredits:(id)obj {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"credits" ofType:@"html"];
	TextDisplayViewController *viewController = [TextDisplayViewController new];
	viewController.text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	viewController.HTML = YES;
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}

- (void) hearseShowLog:(id)i {
	NSString *text = [NSString stringWithContentsOfFile:@"hearse.log" encoding:NSASCIIStringEncoding error:NULL];
	[self displayText:text withCondition:nil isLog:YES];
}

- (void) showMainMenu:(id)obj {
	NSMutableArray *menuItems = [NSMutableArray array];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Gear"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"Wear Armor (W)" key:'W' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Take off (T)" key:'T' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Wield Weapon (w)" key:'w' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Switch Weapon (x)" key:'x' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Put on jewelry (P)" key:'P' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Remove jewelry (R)" key:'R' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Take off all armor (A)" key:'A' accessory:YES],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Actions"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"Pickup (,)" key:',' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Open (o)" key:'o' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Close (c)" key:'c' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Kick (^d)" key:C('d') accessory:NO],
													  [MenuItem menuItemWithTitle:@"Teleport (^t)" key:C('t') accessory:NO],
													  [MenuItem menuItemWithTitle:@"Repeat (^a)" key:C('a') accessory:NO],
													  [MenuItem menuItemWithTitle:@"Eat (e)" key:'e' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Drop (d)" key:'d' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Drop Several (D)" key:'D' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Apply (a)" key:'a' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Quaff (q)" key:'q' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Engrave (E)" key:'E' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Ascend (<)" key:'<' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Descend (>)" key:'>' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Quiver (Q)" key:'Q' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Pay (p)" key:'p' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Rest (.)" key:'.' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Search (s)" target:self
																		 action:@selector(nethackSearch:)
																			  accessory:YES],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Magic"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"Read (r)" key:'r' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Zap (z)" key:'z' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Cast (Z)" key:'Z' accessory:YES],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Info"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"What's here (:)" key:':' accessory:NO],
													  [MenuItem menuItemWithTitle:@"What is (;)" key:';' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Discoveries (\\)" key:'\\' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Character Info (^x)" key:C('x') accessory:YES],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Show Log" target:self
											action:@selector(nethackShowLog:) accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"License" target:self
											action:@selector(nethackShowLicense:) accessory:YES]];
    [menuItems addObject:[MenuItem menuItemWithTitle:@"History" target:self
                                              action:@selector(nethackShowHistory:) accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Manual" target:self
											action:@selector(showManual:) accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Credits" target:self
											action:@selector(showCredits:) accessory:YES]];
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
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Hearse"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"View Log" target:self
																		   action:@selector(hearseShowLog:)
																		accessory:YES],
													  nil]]];
	MenuViewController* menuViewController = [MenuViewController new];
	menuViewController.menuItems = menuItems;
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:menuViewController animated:YES];
	[menuViewController release];
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
			NSTimeInterval touchDuration = touch.timestamp - touchInfoStore.singleTapTimestamp;
			if (doubleTapSensitivity >= 1.0f || doubleTapSensitivity == 0 || touchDuration < doubleTapSensitivity) {
				ti.doubleTap = YES;
			}
		} else {
			touchInfoStore.singleTapTimestamp = touch.timestamp;
		}
		//[self.view setNeedsDisplay];
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
				if (!ti.moved && (abs(delta.x)+abs(delta.y) > kMinimumPanDelta)) {
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
			if (blockingMap) {
				blockingMap.blocking = NO;
				blockingMap = nil;
				[(MainView *) self.view resetOffset];
				[self broadcastUIEvent];
			} else {
				UITouch *touch = [touches anyObject];
				CGPoint p = [touch locationInView:self.view];
				TilePosition *tp = [(MainView *) self.view tilePositionFromPoint:p];
				NethackEvent *lastEvent = nethackEventQueue.lastEvent;
				// todo other events to check
				if ([(MainView *) self.view isMoved] || lastEvent.key == ';' || winiphone_clickable_tiles) {
					// tappable tiles
					lastSingleTapDelta.x = tp.x-u.ux;
					lastSingleTapDelta.y = tp.y-u.uy;
					NethackEvent *e = [[NethackEvent alloc] init];
					e.x = tp.x;
					e.y = tp.y;
					e.key = 0;
					[nethackEventQueue addNethackEvent:e];
					[e release];
					[(MainView *) self.view resetOffset];
					//[self.view setNeedsDisplay];
				} else {
					CGPoint viewCenter = [(MainView *) self.view subViewedCenter];
					CGRect middleSquare = CGRectMake(viewCenter.x-kCenterTapWidth/2,
													 viewCenter.y-kCenterTapWidth/2,
													 kCenterTapWidth, kCenterTapWidth);
					if (CGRectContainsPoint(middleSquare, p)) {
						// tap on player (center) tile
						lastSingleTapDelta.x = 0;
						lastSingleTapDelta.y = 0;
						NethackEvent *e = [[NethackEvent alloc] init];
						e.x = u.ux;
						e.y = u.uy;
						e.key = 0;
						[nethackEventQueue addNethackEvent:e];
						[e release];
						[(MainView *) self.view resetOffset];
						//[self.view setNeedsDisplay];
					} else {
						// direction based movement
						CGPoint center = [(MainView *) self.view subViewedCenter];
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
						//[self.view setNeedsDisplay];
					}
				}
			}
		} else if (!ti.pinched && !ti.moved && ti.doubleTap) {
			TilePosition *delta = lastSingleTapDelta;
			if (((abs(delta.x) == 0 || abs(delta.x) == 1) && (abs(delta.y) == 0)) || abs(delta.y) == 1) {
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
	//[windows addObject:w];    //iNethack2 changing to a dict
    [windows setValue:w forKey:[NSString stringWithFormat:@"%d", windowIdCounter]];
    windowIdCounter++;
	[w release];
    return (winid) (windowIdCounter-1); //iNethack2
	//return (winid) w;
}

- (void) destroyWindow:(winid)wid {
	//Window *w = (Window *) wid;
    [windows removeObjectForKey:[NSString stringWithFormat:@"%d",wid]];
}

- (Window *) windowWithId:(winid)wid {
//    NSLog(@"%@",windows);
//	return (Window *) wid;
//    return [windows objectAtIndex:wid]; //iNethack2
    return [windows objectForKey:[NSString stringWithFormat:@"%d",wid]]; //iNethack2
}

- (void) displayWindowId:(winid)wid blocking:(BOOL)blocking {
	BOOL mapBlocked = NO;
	Window *w = [self windowWithId:wid];
	switch (w.type) {
		case NHW_MENU:
		case NHW_TEXT:
			if (w.strings.count > 0) {
				[uiCondition lock];
				[self performSelectorOnMainThread:@selector(displayMessage:) withObject:w waitUntilDone:YES];
				[uiCondition wait];
				[uiCondition unlock];
			}
			break;
		case NHW_MAP:
			if (blocking) {
				w.blocking = YES;
				blockingMap = w;
				mapBlocked = YES;
			}
		case NHW_MESSAGE:
			[self.view performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
			if (mapBlocked) {
				[self waitForUser];
			}
			break;
		default:
			break;
	}
}

- (void) displayMessage:(Window *)w {
	[w lock];
	NSString *message = [w.text copy];
	[w clearMessages];
	[w unlock];
	UIAlertView *alert = nil;

    if ([message containsString:kConstThingsThatAreHereTitle] || [message containsString:kConstThingsThatYouFeelHereTitle]) {
		NSRange r = [message rangeOfString:@"\n"];
		NSString *title = [message substringToIndex:r.location];
		NSString *toReplaced = [NSString stringWithFormat:@"%@\n", title];
		NSString *text = [message stringByReplacingOccurrencesOfString:toReplaced withString:@""];
        alert = [[UIAlertView alloc] initWithTitle:title message:text delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Pickup", nil];
        [alert show];
	} else {
        
        if (![UIAlertController class]) {
           UIAlertView *alert2 = [[UIAlertView alloc] initWithTitle:@"Message" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert2 show];
            return;
        
        } else {
            UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:@"Message" message:message
                                                                     preferredStyle:UIAlertControllerStyleAlert];

            [alert2.view setTranslatesAutoresizingMaskIntoConstraints:NO];

            alert2.view.frame = CGRectMake([[UIScreen mainScreen] applicationFrame].origin.x,
                                           [[UIScreen mainScreen] applicationFrame].origin.y,
                                           [[UIScreen mainScreen] applicationFrame].size.width+1,
                                           [[UIScreen mainScreen] applicationFrame].size.height+1);// iNethack2 - fix for no scrolling on initial story text popup (ios8 bug?)

            UIAlertAction* ok = [UIAlertAction
                                 actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     [alert2 dismissViewControllerAnimated:YES completion:nil];
                                     [self broadcastUIEvent];
                                 }];

            [alert2 addAction:ok];
            
            [self presentViewController:alert2 animated:YES completion:nil];
            return;
        }
	}
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
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:nethackMenuViewController animated:YES];
}

//iNethack2 -- trying this function instead of clickedButtonAtIndex as clickedButtonAtIndex was occasionally hanging
-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    //NSLog(@"alert finished");
    if (alertView.numberOfButtons == 2) {
        if (buttonIndex == 1) {
            [nethackEventQueue addKeyEvent:','];
        }
    }
    [alertView release];
    [self broadcastUIEvent];
}

//iNethack2 -- trying this function instead of clickedButtonAtIndex as clickedButtonAtIndex was occasionally hanging
- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    currentYnFunction.chosen = (int) buttonIndex;
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

//iNethack2: screenSize that works with both iOS7 + 8
+ (CGSize)screenSize {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return CGSizeMake(screenSize.height, screenSize.width);
    }
    return screenSize;
}


- (void) displayYnQuestionOnUIThread:(NethackYnFunction *)yn {
	currentYnFunction = yn;
	UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:[NSString stringWithCString:yn.question
																				  encoding:NSASCIIStringEncoding]
													  delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil
											 otherButtonTitles:nil];
	const char *p = yn.choices;
	char c;

    while ((c = *p++)) {
		char str[] = {c,0};
		[menu addButtonWithTitle:[NSString stringWithCString:str encoding:NSASCIIStringEncoding]];
		//NSLog(@"added button %d %s", i, str);
	}
    /*
     iNethack2: on iPad iOS8, actionsheet not displaying in center because of self view bounds not matching screen size. 
        So this hack sets bounds to match screen size, displays actionsheet, then sets them back. 
        TODO: replace ActionSheet with proper UIAlertController. Will require several changes to accepting the user input.
        Also there are issues with rotation while displayed, but may be unfixable (or not worth the effort).
    */
    CGRect oldViewBounds = CGRectFromString(NSStringFromCGRect(self.view.bounds));
    self.view.bounds = CGRectMake(0, 0, [MainViewController screenSize].width, [MainViewController screenSize].height);
    [menu showInView:self.view];
    self.view.bounds=oldViewBounds;
}

- (void) getLine:(char *)line prompt:(const char *)p {
	NSString *s = [NSString stringWithCString:p encoding:NSASCIIStringEncoding];
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
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
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
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:extendedCommandViewController animated:YES];
}

- (int) getExtendedCommand {
	[self performSelectorOnMainThread:@selector(showExtendedCommandMenu:) withObject:nil waitUntilDone:YES];
	[self waitForCondition:uiCondition];
	return extendedCommandViewController.result;
}

- (void)didCompleteRoleSelection:(id)sender {
	NSAssert(flags.initalign != -1, @"Alignment was not set");
	NSAssert(flags.initrace  != -1, @"Race was not set");
	NSAssert(flags.initgend  != -1, @"Gender was not set");
	NSAssert(flags.initrole  != -1, @"Role was not set");
	[self broadcastUIEvent];
}

- (void) doPlayerSelectionOnUIThread:(id)obj {
	RoleSelectionController* roleSelector = [RoleSelectionController roleSelectorWithNavigationController:self.navigationController];
	roleSelector.delegate = self;
	[roleSelector start];
}

- (void) doPlayerSelection {
	[self performSelectorOnMainThread:@selector(doPlayerSelectionOnUIThread:) withObject:nil waitUntilDone:NO];
	[self waitForCondition:uiCondition];
}

- (void) displayFile:(NSString *)filename mustExist:(BOOL)e {
	if (![filename isEqualToString:@"news"]) {
		NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@""];
		if (path) {
			NSCondition *textDisplayCondition = [[NSCondition alloc] init];
			NSString *t = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:NULL];
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

- (void) updateScreen {
	[self.view performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
}

- (void) showKeyboard:(BOOL)d {
	if (d) {
		keyboardReturnShouldQueueEscape = YES;
		[self performSelectorOnMainThread:@selector(nethackKeyboard:) withObject:nil waitUntilDone:YES];
	} else {
		// todo find a save way to let keyboard disappear
		keyboardReturnShouldQueueEscape = NO;
	}
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
	if (keyboardReturnShouldQueueEscape) {
		[nethackEventQueue addKeyEvent:27];
	}
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
