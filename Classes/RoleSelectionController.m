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

#import "RoleSelectionController.h"
#import "RoleSelectionViewController.h"
#import "hack.h"
#import "MainViewController.h"

@interface RoleSelectionController ()
@property (retain) UINavigationController *navigationController;
- (id)initWithNavigationController:(UINavigationController *)navController;
- (void)moveToNextStep:(id)sender;
@end

@implementation RoleSelectionController
- (void)showRoleSelectionController:(RoleSelectionViewController *)controller {
	if (controller.numberOfItems > 1) {
		[self.navigationController pushViewController:controller animated:self.navigationController.viewControllers.count > 1];
	} else {
		[self performSelector:controller.action withObject:controller];
	}
}

// ===================
// = Selection steps =
// ===================

- (void)didSelectAlignment:(id)sender
{
	NSAssert([sender respondsToSelector:@selector(tag)], @"sender has no tag");
	flags.initalign = [sender tag];

	[self moveToNextStep:nil];
}

- (void)selectAlignment
{
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

- (void)didSelectGender:(id)sender
{
	NSAssert([sender respondsToSelector:@selector(tag)], @"sender has no tag");
	flags.initgend = [sender tag];

	[self moveToNextStep:nil];
}

- (void)selectGender
{
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

- (void)didSelectRace:(id)sender
{
	NSAssert([sender respondsToSelector:@selector(tag)], @"sender has no tag");
	pl_race = [sender tag];
	flags.initrace = [sender tag];

	[self moveToNextStep:nil];
}

- (void)selectRace
{
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

- (void)didSelectRole:(id)sender
{
	NSAssert([sender respondsToSelector:@selector(tag)], @"sender has no tag");
	flags.initrole = [sender tag];
	strcpy(pl_character, roles[flags.initrole].filecode);

	[self moveToNextStep:nil];
}

- (void)selectRole
{
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

// ==================
// = Setup/Teardown =
// ==================

@synthesize delegate, navigationController;

+ (id)roleSelectorWithNavigationController:(UINavigationController *)navController;
{
	// Object is self-retained until the process is completed
	return [[RoleSelectionController alloc] initWithNavigationController:navController];
}

- (id)initWithNavigationController:(UINavigationController *)navController
{
	if (self = [super init]) {
		self.navigationController = navController;
	}
	return self;
}

- (void)dealloc
{
	self.navigationController = nil;
	[super dealloc];
}

- (void)moveToNextStep:(id)sender
{
	if (flags.initrole == -1)  return [self selectRole];
	if (flags.initrace == -1)  return [self selectRace];
	if (flags.initgend == -1)  return [self selectGender];
	if (flags.initalign == -1) return [self selectAlignment];

	// Done
	[self.navigationController popToRootViewControllerAnimated:NO];
	[self.delegate didCompleteRoleSelection:self];
	[self autorelease];
	
	[[MainViewController instance] setRoleSelectionInProgress:NO];
}

- (void)start
{
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self moveToNextStep:nil];
}
@end
