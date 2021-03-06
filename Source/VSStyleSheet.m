//
//  VSStyleSheet.m
//  VSStyleMac
//
//  Created by Steve Streza on 11/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VSStyleSheet.h"
#import <objc/runtime.h>

@interface VSStyleSheet (Private)
+ (NSArray*)_subclassesOfClass:(Class)superclass fromCArray:(Class[])classes withCount:(int)count;
@end

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static NSArray *gAllStyleSheets;
static VSStyleSheet* gStyleSheet = nil;
const NSString *VSStyleSheetChangedNotification = @"VSStyleSheetChangedNotification";

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation VSStyleSheet

///////////////////////////////////////////////////////////////////////////////////////////////////
// class public

+(NSArray *)allStyleSheets{
	if(!gAllStyleSheets){
		int count = objc_getClassList(NULL, 0);
		
		Class classes[count];
		objc_getClassList(classes, count);
		
		NSArray *styleSheetClasses = [self _subclassesOfClass:self fromCArray:classes withCount:count];
		
		NSMutableArray *allSheets = [NSMutableArray arrayWithCapacity:[styleSheetClasses count]];
		for(Class sheetClass in styleSheetClasses){
			[allSheets addObject:[sheetClass styleSheet]];
		}
		
		gAllStyleSheets = [allSheets copy];
	}
	return [[gAllStyleSheets copy] autorelease];
}


+ (VSStyleSheet*)globalStyleSheet {
/*
 TODO Implement a default style sheet for Aqua
 Perhaps make alternatives for other common UI styles
 
	if (!gStyleSheet) {
		gStyleSheet = [[VSDefaultStyleSheet alloc] init];
	}
 */
	if (!gStyleSheet){
		gStyleSheet = [[[self allStyleSheets] lastObject] retain];
	}
	
	return gStyleSheet;
}

+ (void)setGlobalStyleSheet:(VSStyleSheet*)styleSheet {
	[gStyleSheet autorelease];
	gStyleSheet = [styleSheet retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: (NSString *)VSStyleSheetChangedNotification
														object: (id)gStyleSheet ];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)init {
	if (self = [super init]) {
		_styles = nil;
	}
	return self;
}

- (void)dealloc {
	[_styles release];
	_styles = nil;
	
	[super dealloc];
}

+ (id) styleSheet{
	return [[[self alloc] init] autorelease];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (BOOL)isGlobalStyleSheet{
	return [[[self class] globalStyleSheet] class] == [self class];
}

- (VSStyle*)styleWithSelector:(NSString*)selector {
	if(!selector) return nil;
	
	VSStyle* style = [_styles objectForKey:selector];
	if (YES || !style) {
		SEL sel = NSSelectorFromString(selector);
		if ([self respondsToSelector:sel]) {
			style = [self performSelector:sel withObject:nil];
			if (style) {
				if (!_styles) {
					_styles = [[NSMutableDictionary alloc] init];
				}
				[_styles setObject:style forKey:selector];
			}
		}
	}
	return style;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

+ (NSArray*)_subclassesOfClass:(Class)superclass fromCArray:(Class[])classes withCount:(int)count {
	NSMutableArray *array = [NSMutableArray array];
	
	for (int i = 0; i < count; i++) {
		Class subclass = classes[i];
		if (class_getSuperclass(subclass) == superclass
			&& [NSStringFromClass(subclass) hasPrefix:@"NSKVONotifying"] == NO
			/* avoid the autogenerated KVO classes if they ever come up in the future */)
		{
			[array addObject:subclass];
			[array addObjectsFromArray:[self _subclassesOfClass:subclass fromCArray:classes withCount:count]];
		}
	}
	
	return array;
}

@end
