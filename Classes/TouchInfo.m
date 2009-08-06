//
//  TouchInfo.m
//  iNetHack
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import "TouchInfo.h"

@implementation TouchInfo

@synthesize pinched, moved, initialLocation;

- (id) initWithTouch:(UITouch *)t {
	if (self = [super init]) {
		self.initialLocation = [t locationInView:t.view];
	}
	return self;
}

@end
