//
//  NethackYnFunction.m
//  iNetHack
//
//  Created by dirk on 7/1/09.
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

#import "NethackYnFunction.h"

@implementation NethackYnFunction

@synthesize question, choices, defaultChoice, chosen;

- (id) initWithQuestion:(const char *)q choices:(const char *)ch defaultChoice:(const char)c {
	if (self = [super init]) {
		question = q;
		choices = ch;
		defaultChoice = c;
	}
	return self;
}

- (char) choice {
	return choices[chosen];
}

@end
