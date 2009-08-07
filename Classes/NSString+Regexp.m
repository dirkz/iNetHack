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

@end
