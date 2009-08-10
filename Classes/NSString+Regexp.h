//
//  NSString+Regexp.h
//  iNetHack
//
//  Created by dirk on 8/6/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

#import <Foundation/Foundation.h>

// WARNING: no actual Regexp code!
@interface NSString (Regexp)

- (BOOL) containsString:(NSString *)s;
- (BOOL) containsChar:(char)c;
- (NSString *) substringFromString:(NSString *)src betweenDelimiters:(NSString *)del;
- (NSString *) stringWithTrimmedWhitespaces;

@end
