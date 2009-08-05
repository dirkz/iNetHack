//
//  NethackEvent.m
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

#import "NethackEvent.h"

@implementation NethackEvent

@synthesize key, x, y, mod;

- (id) init {
	return [self initWithKey:0 x:0 y:0 mod:0];
}

- (id) initWithKey:(int)k x:(int)i y:(int)j mod:(int)m {
	if (self = [super init]) {
	}
	return self;
}

@end
