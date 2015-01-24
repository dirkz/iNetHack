//
//  MenuViewController.m
//  iNetHack
//
//  Created by dirk on 6/29/09.
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

#import "MenuViewController.h"
#import "MenuItem.h"
#import "MainViewController.h"
#import "NethackEventQueue.h"

@implementation MenuViewController

@synthesize menuItems;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	tv = (UITableView *) self.view;
	tv.backgroundColor = [UIColor blackColor];

    //iNethack2: fix for not scrolling all the way to bottom for iphone5+
    long bottom;
    bottom= (self.view.frame.size.height + self.view.frame.origin.y) - [UIScreen mainScreen].bounds.size.height;
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, bottom, 0)];
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	int row = (int) [indexPath row];
	MenuItem *menuItem = [menuItems objectAtIndex:row];
	if (menuItem.children) {
		MenuViewController* submenuController = [MenuViewController new];
		submenuController.title = menuItem.title;
		submenuController.menuItems = menuItem.children;
		[self.navigationController pushViewController:submenuController animated:YES];
		[submenuController release];
	} else if (menuItem.key) {
		[[[MainViewController instance] nethackEventQueue] addKeyEvent:menuItem.key];
		[self.navigationController popToRootViewControllerAnimated:NO];
	} else {
		[menuItem invoke];
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark UITableView datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellId = @"menuViewControllerCellId";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	if (!cell) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
		cell.textLabel.textColor = [UIColor whiteColor];
	}
	int row = (int) [indexPath row];
	MenuItem *menuItem = [menuItems objectAtIndex:row];
	cell.textLabel.text = menuItem.title;
    cell.backgroundColor = [UIColor clearColor];

	if (menuItem.accessory) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	return cell;
}

- (void)dealloc {
	[menuItems release];
    [super dealloc];
}

@end
