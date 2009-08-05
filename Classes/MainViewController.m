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
#import "CreditsViewController.h"

static MainViewController *_instance;

@implementation MainViewController

@synthesize windows, clipx, clipy, prompt, nethackEventQueue, moving;

+ (id) instance {
	return _instance;
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
	self.title = @"Dungeon";
	windows = [[NSMutableArray alloc] init];
	nethackEventQueue = [[NethackEventQueue alloc] init];
	uiCondition = [[NSCondition alloc] init];
	textInputCondition = [[NSCondition alloc] init];
	textDisplayCondition = [[NSCondition alloc] init];
	tapRect = CGRectMake(-25, -25, 50, 50);
	_instance = self;

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
	[alert release];
}

- (void) waitForUser {
	[uiCondition lock];
	[uiCondition wait];
	[uiCondition unlock];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//NSLog(@"alert finished");
	[self broadcastUIEvent];
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
	textDisplayViewController.text = text;
	[self.navigationController pushViewController:textDisplayViewController animated:YES];
}

- (void) nethackShowLicense:(id)i {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"license" ofType:@""];
	NSString *text = [NSString stringWithContentsOfFile:path];
	textDisplayViewController.text = text;
	[self.navigationController pushViewController:textDisplayViewController animated:YES];
}

- (void) showCredits:(id)obj {
	[self.navigationController pushViewController:creditsViewController animated:YES];
}

- (void) showMainMenu:(id)obj {
	NSMutableArray *menuItems = [NSMutableArray array];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Gear"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"Wear Armor" key:'W'],
													  [MenuItem menuItemWithTitle:@"Take off (armor ...)" key:'T'],
													  [MenuItem menuItemWithTitle:@"Wield Weapon" key:'w'],
													  [MenuItem menuItemWithTitle:@"Switch Weapon" key:'x'],
													  [MenuItem menuItemWithTitle:@"Remove (rings ...)" key:'R'],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Actions"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"Eat" key:'e' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Drop" key:'d' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Apply" key:'a' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Quaff" key:'q' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Engrave" key:'E' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Ascend (<)" key:'<' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Descend (>)" key:'>' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Quiver" key:'Q' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Pay" key:'p' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Search" target:self
																		 selector:@selector(nethackSearch:)
																			  arg:nil accessory:YES],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Magic"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"Read" key:'r' accessory:YES],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Inventory" key:'i' accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"What's here" key:':' accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Show Log" target:self
											selector:@selector(nethackShowLog:) arg:nil accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"License" target:self
											selector:@selector(nethackShowLicense:) arg:nil accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"History" key:'V' accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Credits" target:self
											selector:@selector(showCredits:) arg:nil accessory:YES]];
	menuViewController.menuItems = menuItems;
	lastSingleTouch = nil;
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.navigationController pushViewController:menuViewController animated:YES];
}

#pragma mark touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	numberOfCurrentTouches += touches.count;
	touchesMoved = NO;
	if (touches.count == 1) {
		UITouch *touch = [touches anyObject];
		lastSingleTouch = touch;
		CGPoint p = [touch locationInView:self.view];
		currentTouchLocation = p;
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
	if (touches.count == numberOfCurrentTouches) {
		if (touches.count == 1) {
			UITouch *touch = [touches anyObject];
			CGPoint p = [touch locationInView:self.view];
			CGPoint delta = CGPointMake(p.x-currentTouchLocation.x, p.y-currentTouchLocation.y);
			if (moving || (abs(delta.x)+abs(delta.y) > 10)) {
				moving = YES;
				touchesMoved = YES;
				[(MainView *) self.view moveAlongVector:delta];
				currentTouchLocation = p;
				[self.view setNeedsDisplay];
			}
		} else if (touches.count == 2) {
			touchesMoved = YES;
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
			} else if (initialDistance-currentDistance > kMinimumPinchDelta) {
				// zoom (out)
				CGFloat zoom = currentDistance-initialDistance;
				[(MainView *) self.view zoom:zoom];
			}
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	touchesMoved = NO;
	if (touches.count == 1) {
		lastSingleTouch = nil;
	}
	numberOfCurrentTouches -= touches.count;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (touches.count == 1 && lastSingleTouch && !touchesMoved && numberOfCurrentTouches == 1) {
		UITouch *touch = [touches anyObject];
		CGPoint p = [touch locationInView:self.view];
		TilePosition *tp = [(MainView *) self.view tilePositionFromPoint:p];
		NethackEvent *e = [[NethackEvent alloc] init];
		e.x = tp.x;
		e.y = tp.y;
		e.key = 0;
		[nethackEventQueue addNethackEvent:e];
		[e release];
		if (moving) {
			moving = NO;
			[(MainView *) self.view resetOffset];
			[self.view setNeedsDisplay];
		}
	}
	initialDistance = 0;
	numberOfCurrentTouches -= touches.count;
}

#pragma mark windowing

- (void) displayMenuWindow:(Window *)w {
	[uiCondition lock];
	[self performSelectorOnMainThread:@selector(displayMenuWindowOnUIThread:) withObject:w waitUntilDone:YES];
	[uiCondition wait];
	[uiCondition unlock];
}

- (void) displayMenuWindowOnUIThread:(Window *)w {
	lastSingleTouch = nil;
	nethackMenuViewController.menuWindow = w;
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.navigationController pushViewController:nethackMenuViewController animated:YES];
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
													  delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
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

- (void) doPlayerSelectionOnUIThread:(id)obj {
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.navigationController pushViewController:roleSelectionViewController animated:YES];
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

- (void) displayTextOnUIThread:(NSString *)text {
	textDisplayViewController.text = text;
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.navigationController pushViewController:textDisplayViewController animated:YES];
}

- (void) displayFile:(NSString *)filename mustExist:(BOOL)e {
	if (![filename isEqualToString:@"news"]) {
		textDisplayViewController.condition = textDisplayCondition;
		NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@""];
		if (path) {
			NSString *t = [NSString stringWithContentsOfFile:path];
			[self performSelectorOnMainThread:@selector(displayTextOnUIThread:) withObject:t waitUntilDone:YES];
			[self waitForCondition:textDisplayCondition];
		} else {
			if (e) {
				NSLog(@"error: could not find file %@ for display", filename);
			}
		}
	}
}

- (void) initOptions {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL autopickup = [defaults boolForKey:kOptionAutopickup];
	flags.pickup = autopickup ? TRUE:FALSE;
	NSString *pickupTypes = [defaults objectForKey:kOptionPickupTypes];
	if (pickupTypes) {
		[pickupTypes getCString:flags.pickup_types maxLength:MAXOCLASSES encoding:NSASCIIStringEncoding];
	}
	NSLog(@"autopickup %d", flags.pickup);
	NSLog(@"pickup_types %s", flags.pickup_types);
}

- (void) overrideOptions {
}

#pragma mark condition utilities

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
	[uiCondition release];
	[textInputCondition release];
	[textDisplayCondition release];
	[windows release];
    [super dealloc];
}

@end
