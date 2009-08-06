//
//  TouchInfoStore.m
//  iNetHack
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import "TouchInfoStore.h"
#import "TouchInfo.h"

@implementation TouchInfoStore

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
