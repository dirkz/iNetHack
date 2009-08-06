//
//  TouchInfo.m
//  iNetHack
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import "TouchInfo.h"

@implementation TouchInfo

@synthesize pinched, moved, initialLocation, currentLocation, doubleTap;

- (id) initWithTouch:(UITouch *)t {
	if (self = [super init]) {
		self.initialLocation = self.currentLocation = [t locationInView:t.view];
	}
	return self;
}

@end
