//
//  NethackEventQueue.m
//  iNetHack
//
//  Created by dirk on 7/3/09.
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

#import "NethackEventQueue.h"
#import "NethackEvent.h"

@implementation NethackEventQueue

- (id) init {
	if (self = [super init]) {
		mutex = [[NSCondition alloc] init];
		events = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) addNethackEvent:(NethackEvent *)e {
	[mutex lock];
	[events addObject:e];
	[mutex signal];
	[mutex unlock];
}

- (void) addKeyEvent:(int)k {
	NethackEvent *e = [[NethackEvent alloc] init];
	e.key = k;
	[self addNethackEvent:e];
	[e release];
}

- (NethackEvent *) waitForNextEvent {
	[mutex lock];
	while (events.count < 1) {
		[mutex wait];
	}
	NethackEvent *e = [events objectAtIndex:0];
	[[e retain] autorelease];
	[events removeObjectAtIndex:0];
	[mutex unlock];
	return e;
}

- (void) dealloc {
	[mutex release];
	[events release];
	[super dealloc];
}

@end
