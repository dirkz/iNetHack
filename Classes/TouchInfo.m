//
//  TouchInfo.m
//  iNetHack
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import "TouchInfo.h"

@implementation TouchInfo

@synthesize pinched, moved;

- (id) initWithTouch:(UITouch *)t {
	if (self = [super init]) {
	}
	return self;
}

@end
