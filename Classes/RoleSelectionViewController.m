//
//  RoleSelectionViewController.m
//  iNetHack
//
//  Created by dirk on 7/7/09.
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

#import "RoleSelectionViewController.h"

@implementation RoleSelectionViewController
@synthesize target, action, tag;

- (id)init
{
	if(self = [super initWithStyle:UITableViewStylePlain])
	{
		options = [NSMutableArray new];
		tag = -1;
	}
	return self;
}

- (void)addItemWithTitle:(NSString *)title tag:(NSInteger)itemTag
{
	[options addObject:[NSDictionary dictionaryWithObjectsAndKeys:title, @"title", [NSNumber numberWithInt:itemTag], @"tag", nil]];
}

- (void)dealloc
{
	[options release];
	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	tag = [[[options objectAtIndex:indexPath.row] objectForKey:@"tag"] intValue];

	if(self.target && self.action)
		[[UIApplication sharedApplication] sendAction:self.action to:self.target from:self forEvent:nil];
}

#pragma mark UITableView datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellId = @"playerSelectionViewControllerCellId";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellId] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	cell.textLabel.text = [[options objectAtIndex:indexPath.row] objectForKey:@"title"];
	return cell;
}
@end
