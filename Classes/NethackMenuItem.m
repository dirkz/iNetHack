//
//  NethackMenuItem.m
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

#import "NethackMenuItem.h"

@implementation NethackMenuItem

@synthesize identifier, title, isTitle, children, isSelected;

- (id) initWithId:(const anything *)i title:(const char *)t preselected:(BOOL)p {
	if (self = [super init]) {
		identifier = *i;
		if (!i->a_int) {
			isTitle = YES;
			children = [[NSMutableArray alloc] init];
		}
		title = [[NSString alloc] initWithCString:t];
		isSelected = p;
	}
	return self;
}

- (void) dealloc {
	[title release];
	[children release];
	[super dealloc];
}

@end
