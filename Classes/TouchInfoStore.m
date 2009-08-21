//
//  TouchInfoStore.m
//  iNetHack
//
//  Created by dirk on 8/6/09.
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

#import "TouchInfoStore.h"
#import "TouchInfo.h"

@implementation TouchInfoStore

@synthesize singleTapTimestamp;

- (id) init {
	if (self = [super init]) {
		currentTouchInfos = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (int) count {
	return currentTouchInfos.count;
}

- (void) storeTouches:(NSSet *)touches {
	for (UITouch *t in touches) {
		TouchInfo *ti = [[TouchInfo alloc] initWithTouch:t];
		NSValue *k = [NSValue valueWithPointer:t];
		[currentTouchInfos setObject:ti forKey:k];
		[ti release];
	}
}

- (TouchInfo *) touchInfoForTouch:(UITouch *)t {
	NSValue *k = [NSValue valueWithPointer:t];
	TouchInfo *ti = [currentTouchInfos objectForKey:k];
	return ti;
}

- (void) removeTouches:(NSSet *)touches {
	for (UITouch *t in touches) {
		NSValue *k = [NSValue valueWithPointer:t];
		[currentTouchInfos removeObjectForKey:k];
	}
}

- (void) dealloc {
	[currentTouchInfos release];
	[super dealloc];
}

@end
