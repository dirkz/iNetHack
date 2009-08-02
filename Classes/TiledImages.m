//
//  TiledImages.m
//  iNetHack
//
//  Created by dirk on 7/12/09.
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

#import "TiledImages.h"


@implementation TiledImages

- (id) initWithImage:(UIImage *)image tileSize:(CGSize)ts {
	if (self = [super init]) {
		tileSize = ts;
		CGImageRef base = image.CGImage;
		int x = CGImageGetWidth(base) / tileSize.width;
		int y = CGImageGetHeight(base) / tileSize.height;
		numImages = x*y;
		images = malloc(numImages * sizeof(CGImageRef));
		int index = 0;
		for (int j = 0; j < y; ++j) {
			for (int i = 0; i < x; ++i) {
				CGRect r = CGRectMake(i * tileSize.width, j * tileSize.height, tileSize.width, tileSize.height);
				images[index++] = CGImageRetain(CGImageCreateWithImageInRect(base, r));
			}
		}
	}
	return self;
}

- (CGImageRef) imageAt:(int)i {
	return images[i];
}

- (void) dealloc {
	for (int i = 0; i < numImages; ++i) {
		CGImageRelease(images[i]);
	}
	free(images);
	[super dealloc];
}

@end
