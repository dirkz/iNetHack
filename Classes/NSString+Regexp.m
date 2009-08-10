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

- (NSString *) substringFromString:(NSString *)src betweenDelimiters:(NSString *)del {
	char c = [del characterAtIndex:0];
	NSString *s = [NSString stringWithFormat:@"%c", c];
	NSRange r1 = [self rangeOfString:s];
	if (r1.location == NSNotFound) {
		return nil;
	}
	c = [del characterAtIndex:1];
	s = [NSString stringWithFormat:@"%c", c];
	NSRange r2 = [self rangeOfString:s];
	if (r2.location == NSNotFound) {
		return nil;
	}
	NSRange r = NSMakeRange(r1.location+1, r2.location-r1.location-1);
	NSString *sub = [src substringWithRange:r];
	return sub;
}

- (NSString *) stringWithTrimmedWhitespaces {
	NSMutableString *s1 = [NSMutableString stringWithCapacity:1];
	BOOL wasSpace = NO;
	for (int i = 0; i < self.length; ++i) {
		char c = [self characterAtIndex:i];
		if (!wasSpace) {
			[s1 appendFormat:@"%c", c];
			if (c == ' ') {
				wasSpace = YES;
			}
		} else {
			if (c != ' ') {
				wasSpace = NO;
				[s1 appendFormat:@"%c", c];
			}
		}
	}
	return s1;
}

@end
