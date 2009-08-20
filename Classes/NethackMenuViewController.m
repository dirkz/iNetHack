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
//  the Free Software Foundation, version 2 of the License only.
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
#import "MainView.h"
#import "TiledImages.h"
#import "NSString+Regexp.h"

extern short glyph2tile[];

@implementation NethackMenuViewController

@synthesize menuWindow;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void) selectAllItems:(NSArray *)items select:(BOOL)s {
	for (NethackMenuItem *i in items) {
		if (i.isTitle) {
			[self selectAllItems:i.children select:s];
		} else {
			i.isSelected = s;
		}
	}
}

- (void) selectAll:(id)sender {
	UIBarButtonItem *bi = sender;

	if (selectAll) {
		bi.title = @"None";
	} else {
		bi.title = @"All";
	}
	[self selectAllItems:menuWindow.menuItems select:selectAll];
	selectAll = !selectAll;
	[self.tableView reloadData];
}

- (void) setMenuWindow:(Window *)w {
	menuWindow = w;
	menuWindow.menuResult = kMenuCancelled;
	self.title = (w.menuPrompt && w.menuPrompt.length > 0) ? menuWindow.menuPrompt : @"Menu";

	// extend menu items
	if (menuWindow.acceptBareHanded || menuWindow.acceptMoney || menuWindow.acceptMore) {
		anything any;
		any.a_int = 0;
		NethackMenuItem *miParent = [[NethackMenuItem alloc] initWithId:&any title:"Meta" glyph:kNoGlyph preselected:NO];
		[menuWindow addMenuItem:miParent];
		[miParent release];
		if (menuWindow.acceptBareHanded) {
			any.a_int = '-';
			NethackMenuItem *mi = [[NethackMenuItem alloc] initWithId:&any title:"Hands (-)" glyph:kNoGlyph preselected:NO];
			[menuWindow addMenuItem:mi];
			[mi release];
		}
		if (menuWindow.acceptMore) {
			any.a_int = '*';
			NethackMenuItem *mi = [[NethackMenuItem alloc] initWithId:&any title:"More (*)" glyph:kNoGlyph preselected:NO];
			[menuWindow addMenuItem:mi];
			[mi release];
		}
		if (menuWindow.acceptMoney) {
			any.a_int = '$';
			NethackMenuItem *mi = [[NethackMenuItem alloc] initWithId:&any title:"Gold ($)" glyph:kNoGlyph preselected:NO];
			[menuWindow addMenuItem:mi];
			[mi release];
		}
	}

	selectAll = YES;
	if (w.menuHow == PICK_ANY) {
		UIBarButtonItem *bi = [[UIBarButtonItem alloc] initWithTitle:@"All" style:UIBarButtonItemStylePlain
															  target:self action:@selector(selectAll:)];
		self.navigationItem.rightBarButtonItem = bi;
		[bi release];
	} else {
		self.navigationItem.rightBarButtonItem = nil;
	}

	[self.tableView reloadData];
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
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId] autorelease];
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

	if (i.glyph != NO_GLYPH && i.glyph != kNoGlyph) {
		MainView *view = (MainView *) [[MainViewController instance] view];
		int t = glyph2tile[i.glyph];
		CGImageRef img = [view.images imageAt:t];
		UIImage *uiImg = [UIImage imageWithCGImage:img];
		cell.imageView.image = uiImg;
	} else {
		cell.imageView.image = nil;
	}
	
	NSArray *strings;
	NSString *ws = [i.title substringBetweenDelimiters:@"()"];
	if (ws && ws.length > 1) {
		NSRange r = [i.title rangeOfString:ws];
		strings = [NSArray arrayWithObjects:[i.title substringToIndex:r.location-2], ws, nil];
	} else {
		strings = [NSArray arrayWithObjects:i.title, nil];
	}
	
	cell.textLabel.text = [strings objectAtIndex:0];
	if (strings.count == 2) {
		cell.detailTextLabel.text = [strings objectAtIndex:1];
	} else {
		cell.detailTextLabel.text = nil;
	}
	
	cell.accessoryType = i.isSelected ? UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
	return cell;
}

@end
