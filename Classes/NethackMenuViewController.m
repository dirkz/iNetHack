//
//  NethackMenuViewController.m
//  iNetHack
//
//  Created by dirk on 6/30/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

//  This file is part of iNetHack.
//
//  iNetHack is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  iNetHack is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with iNetHack.  If not, see <http://www.gnu.org/licenses/>.

#import "NethackMenuViewController.h"
#import "Window.h"
#import "NethackMenuItem.h"
#import "MainViewController.h"

@implementation NethackMenuViewController

@synthesize menuWindow;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
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
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void) setMenuWindow:(Window *)w {
	menuWindow = w;
	menuWindow.menuResult = kMenuCancelled;
	if (w.menuPrompt && w.menuPrompt.length > 0) {
		self.title = w.menuPrompt;
	} else if ([[MainViewController instance] prompt]) {
		self.title = [[MainViewController instance] prompt];
	} else {
		self.title = @"Menu";
	}
	// first time we are here tf is nil, later it gets set, which works fine
	[tf reloadData];
}

- (void) collectSelectedItems:(NSArray *)menuItems into:(NSMutableArray *)items {
	for (NethackMenuItem *i in menuItems) {
		if (i.isTitle) {
			[self collectSelectedItems:i.children into:items];
		} else {
			if (i.isSelected) {
				[items addObject:i];
			}
		}
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if (menuWindow.menuHow == PICK_ANY) {
		NSMutableArray *items = [NSMutableArray array];
		[self collectSelectedItems:menuWindow.menuItems into:items];
		menuWindow.menuResult = items.count;
		menuWindow.menuList = malloc(sizeof(menu_item) * items.count);
		for (int i = 0; i < items.count; ++i) {
			NethackMenuItem *item = [items objectAtIndex:i];
			menuWindow.menuList[i].count = -1;
			menuWindow.menuList[i].item = item.identifier;
		}
	}
	[[MainViewController instance] broadcastUIEvent];
	[[MainViewController instance] setPrompt:nil];
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	int row = [indexPath row];
	int section = [indexPath section];
	NethackMenuItem *i = nil;
	if (menuWindow.isShallowMenu) {
		if (section != 0) {
			NSLog(@"error in %s: section number in shallow menu!", __FUNCTION__);
		}
		i = [menuWindow.menuItems objectAtIndex:row];
	} else {
		i = [menuWindow.menuItems objectAtIndex:section];
		i = [i.children objectAtIndex:row];
	}
	if (menuWindow.menuHow == PICK_ANY) {
		i.isSelected = !i.isSelected;
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		cell.accessoryType = i.isSelected ? UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
	} else {
		menuWindow.menuResult = 1;
		menuWindow.menuList = malloc(sizeof(menu_item));
		menuWindow.menuList->count = -1;
		menuWindow.menuList->item = i.identifier;
		[self.navigationController popToRootViewControllerAnimated:NO];
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark UITableView datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	tf = tableView;
	if (menuWindow.isShallowMenu) {
		return 1;
	} else {
		return menuWindow.menuItems.count;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (menuWindow.isShallowMenu) {
		if (section != 0) {
			NSLog(@"error in %s: section number in shallow menu!", __FUNCTION__);
		}
		return menuWindow.menuItems.count;
	} else {
		NethackMenuItem *i = [menuWindow.menuItems objectAtIndex:section];
		return i.children.count;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NethackMenuItem *i = [menuWindow.menuItems objectAtIndex:section];
	return i.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellId = @"nethackMenuViewControllerCellId";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	if (!cell) {
		cell = [[[ UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellId] autorelease];
	}
	int row = [indexPath row];
	int section = [indexPath section];
	NethackMenuItem *i = nil;
	if (menuWindow.isShallowMenu) {
		if (section != 0) {
			NSLog(@"error in %s: section number in shallow menu!", __FUNCTION__);
		}
		i = [menuWindow.menuItems objectAtIndex:row];
	} else {
		i = [menuWindow.menuItems objectAtIndex:section];
		i = [i.children objectAtIndex:row];
	}
	cell.textLabel.text = i.title;
	cell.accessoryType = UITableViewCellAccessoryNone;
	return cell;
}

- (void)dealloc {
    [super dealloc];
}

@end
