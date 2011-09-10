//
//  NSBitmapImageRep+RIC.h
//  ric2png
//
//  Created by Matt Rajca on 9/10/11.
//  Copyright (c) 2011 Matt Rajca. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSBitmapImageRep (RIC)

- (id)initWithRICData:(NSData *)data;

- (NSData *)RICData;

@end
