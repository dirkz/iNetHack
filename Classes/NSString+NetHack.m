//
//  NSString+NetHack.m
//  iNetHack
//
//  Created by dirk on 8/22/09.
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

#import "NSString+NetHack.h"
#import "NSString+Regexp.h"

@implementation NSString (NetHack)

- (NSArray *) splitNetHackDetails {
	NSArray *strings;
	NSString *ws = [self substringBetweenDelimiters:@"()"];
	if (ws && ws.length > 1) {
		NSRange r = [self rangeOfString:ws];
		strings = [NSArray arrayWithObjects:[self substringToIndex:r.location-2], ws, nil];
	} else {
		strings = [NSArray arrayWithObjects:self, nil];
	}
	return strings;
}

- (int) parseNetHackAmount {
	int amount = -1;
	NSRange r = [self rangeOfString:@" "];
	if (r.location != NSNotFound) {
		NSString *amountString = [self substringToIndex:r.location];
		if (amountString.length > 0) {
			amount = [amountString intValue];
			if (amount == 0) {
				amount = -1;
			}
		}
	}
	return amount;
}

@end
