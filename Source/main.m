//
//  main.m
//  ric2png
//
//  Created by Matt Rajca on 9/10/11.
//  Copyright (c) 2011 Matt Rajca. All rights reserved.
//

#import "NSBitmapImageRep+RIC.h"

int main (int argc, const char *argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (argc != 2) {
		fprintf(stderr, "Usage: ric2png <image to convert.ric> (outputs a PNG file of the same name)\n");
		fprintf(stderr, "Usage: ric2png <image to convert.png> (outputs a RIC file of the same name)\n");
		
		return 1;
	}
	
	NSString *path = [NSString stringWithUTF8String:argv[1]];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		fprintf(stderr, "Cannot locate the file at the specified path\n");
		return 1;
	}
	
	BOOL inputPNG = NO;
	
	if ([[path pathExtension] isEqualToString:@"ric"]) { }
	else if ([[path pathExtension] isEqualToString:@"png"]) {
		inputPNG = YES;
	}
	else {
		fprintf(stderr, "ric2png can only convert RIC and PNG files\n");
		return 1;
	}
	
	NSError *error = nil;
	NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
	
	if (!data) {
		fprintf(stderr, "Cannot load the file at the specified path (%ld)\n", [error code]);
		return 1;
	}
	
	if (inputPNG) {
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:data];
		
		if (!rep) {
			fprintf(stderr, "Cannot parse the given PNG file\n");
			return 1;
		}
		
		NSData *outData = [rep RICData];
		[rep release];
		
		if (!outData) {
			fprintf(stderr, "Cannot output a RIC file\n");
			return 1;
		}
		
		path = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"ric"];
		
		if (![outData writeToFile:path options:0 error:&error]) {
			fprintf(stderr, "Cannot output a RIC file (%ld)\n", [error code]);
			return 1;
		}
	}
	else {
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithRICData:data];
		
		if (!rep) {
			fprintf(stderr, "Cannot parse the given RIC file\n");
			return 1;
		}
		
		NSData *pngData = [rep representationUsingType:NSPNGFileType properties:nil];
		[rep release];
		
		if (!pngData) {
			fprintf(stderr, "Cannot output a PNG file\n");
			return 1;
		}
		
		path = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
		
		if (![pngData writeToFile:path options:0 error:&error]) {
			fprintf(stderr, "Cannot output a PNG file (%ld)\n", [error code]);
			return 1;
		}
	}
	
	[pool drain];
	
    return 0;
}
