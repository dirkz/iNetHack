//
//  NSString+Regexp.m
//  iNetHack
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import "NSString+Regexp.h"

@implementation NSString (Regexp)

- (BOOL) containsString:(NSString *)s {
	NSRange r = [self rangeOfString:s];
	if (r.location != NSNotFound) {
		return YES;
	}
	return NO;
}

@end
