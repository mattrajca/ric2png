//
//  NSBitmapImageRep+RIC.m
//  ric2png
//
//  Created by Matt Rajca on 9/10/11.
//  Copyright (c) 2011 Matt Rajca. All rights reserved.
//

#import "NSBitmapImageRep+RIC.h"

@implementation NSBitmapImageRep (RIC)

// Adapted from https://github.com/jgraef/aNXT/blob/master/libanxt_file/ric.c due to the
// lack of documentation for the RIC image format

#define RIC_OPCODE_DESCRIPTION 0
#define RIC_OPCODE_SPRITE      1
#define RIC_OPCODE_COPYBITS    3

#define MAKE_EVEN(x) ((x)+((x)%2))

enum {
	RIC_COPY = 0,
	RIC_COPYNOT = 1,
	RIC_OR = 2,
	RIC_BITCLEAR = 3
};

struct ric_opcode {
	uint16_t len;
	uint16_t opcode;
} __attribute__ ((packed));

struct ric_description {
	struct ric_opcode header;
	uint16_t options;
	uint16_t width;
	uint16_t height;
} __attribute__ ((packed));

struct ric_sprite {
	struct ric_opcode header;
	uint16_t dataaddr;
	uint16_t rows;
	uint16_t rowbytes;
	uint8_t data[0];
} __attribute__ ((packed));

struct ric_point {
	int16_t x;
	int16_t y;
} __attribute__ ((packed));

struct ric_rect {
	struct ric_point point;
	int16_t width;
	int16_t height;
} __attribute__ ((packed));

struct ric_copybits {
	struct ric_opcode header;
	uint16_t options;
	uint16_t dataaddr;
	struct ric_rect src;
	struct ric_point dest;
} __attribute__ ((packed));

- (id)initWithRICData:(NSData *)data {
	struct ric_sprite *sprite = NULL;
	struct ric_copybits *copybits = NULL;
	
	NSUInteger n = 0;
	
	while (n < [data length]) {
		struct ric_opcode *opcode = (struct ric_opcode *) ([data bytes] + n);
		
		if (opcode->opcode == RIC_OPCODE_SPRITE) {
			sprite = (struct ric_sprite *) opcode;
		}
		else if (opcode->opcode == RIC_OPCODE_COPYBITS) {
			copybits = (struct ric_copybits *) opcode;
		}
		
		if (sprite != NULL && copybits != NULL)
			break;
		
		n += opcode->len + 2;
	}
	
	if (sprite == NULL || copybits == NULL)
		return nil;
	
	self = [self initWithBitmapDataPlanes:NULL
							   pixelsWide:copybits->src.width
							   pixelsHigh:copybits->src.height
							bitsPerSample:8
						  samplesPerPixel:3
								 hasAlpha:NO
								 isPlanar:NO
						   colorSpaceName:NSCalibratedRGBColorSpace
							  bytesPerRow:0
							 bitsPerPixel:24];
	
	const uint8_t *bytes = (const uint8_t *) sprite->data;
	
	for (uint16_t y = 0; y < copybits->src.height; y++) {
		for (uint16_t x = 0; x < copybits->src.width; x++) {
			if (bytes[x/8] & (1 << (7 - (x % 8)))) {
				[self setColor:[[NSColor blackColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]
						   atX:x y:y];
			}
			else {
				[self setColor:[[NSColor whiteColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]
						   atX:x y:y];
			}
		}
		
		bytes += sprite->rowbytes;
	}
	
	return self;
}

- (NSData *)RICData {
	uint16_t width = (uint16_t) [self size].width;
	uint16_t height = (uint16_t) [self size].height;
	
	unsigned int rowbytes = (width - 1) / 8 + 1;
	size_t bitmap_size = MAKE_EVEN(rowbytes*height);
	NSUInteger bufsize = sizeof(struct ric_description) + sizeof(struct ric_sprite) + bitmap_size + sizeof(struct ric_copybits);
	
	NSMutableData *data = [[NSMutableData alloc] initWithCapacity:bufsize];
	
	struct ric_description desc;
	bzero(&desc, sizeof(desc));
	
	desc.header.len = sizeof(struct ric_description) - 2;
	desc.header.opcode = RIC_OPCODE_DESCRIPTION;
	desc.width = width;
	desc.height = height;
	
	[data appendBytes:&desc length:sizeof(desc)];
	
	struct ric_sprite *sprite = malloc(sizeof(struct ric_sprite) + bitmap_size);
	bzero(sprite, sizeof(struct ric_sprite) + bitmap_size);
	
	sprite->header.len = sizeof(struct ric_sprite) - 2 + bitmap_size;
	sprite->header.opcode = RIC_OPCODE_SPRITE;
	sprite->dataaddr = 1;
	sprite->rows = height;
	sprite->rowbytes = rowbytes;
	
	uint8_t *bytes = (uint8_t *) sprite->data;
	
	for (uint16_t y = 0; y < height; y++) {
		for (uint16_t x = 0; x < width; x++) {
			if ([[self colorAtX:x y:y] isEqual:[[NSColor blackColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace]]) {
				bytes[x/8] |= 1 << (7 - (x % 8));
			}
		}
		
		bytes += rowbytes;
	}
	
	[data appendBytes:sprite length:sizeof(struct ric_sprite) + bitmap_size];
	
	struct ric_copybits copy;
	bzero(&copy, sizeof(copy));
	
	copy.header.len = sizeof(struct ric_copybits) - 2;
	copy.header.opcode = RIC_OPCODE_COPYBITS;
	copy.options = RIC_COPY;
	copy.dataaddr = 1;
	copy.src.point.x = 0;
	copy.src.point.y = 0;
	copy.src.width = width;
	copy.src.height = height;
	copy.dest.x = 0;
	copy.dest.y = 0;
	
	[data appendBytes:&copy length:sizeof(copy)];
	
	return [data autorelease];
}

@end
