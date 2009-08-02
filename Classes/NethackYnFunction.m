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
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
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
	if (!chosen) {
		const char *p = choices;
		char c;
		while (c = *p++) {
			switch (c) {
				case 'q':
				case 'n':
					return c;
					break;
			}
		}
		return defaultChoice;
	} else {
		return choices[chosen-1];
	}
}

@end
