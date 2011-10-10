//
//  WBOSCReceiverPlugIn.m
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 09 Oct 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import "WBOSCReceiverPlugIn.h"
#import "WildBunch.h"

static NSString* const WBReceiverExampleCompositionName = @"";

@interface WBOSCReceiverPlugIn()
@property (nonatomic) NSUInteger port;
@end

@implementation WBOSCReceiverPlugIn

@dynamic inputPort;
@synthesize port;

+ (NSDictionary*)attributes {
    NSMutableDictionary* attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
        CCLocalizedString(@"WBOSCReceiverName", NULL), QCPlugInAttributeNameKey, 
        CCLocalizedString(@"WBOSCReceiverDescription", NULL), QCPlugInAttributeDescriptionKey, 
        nil];

#if defined(MAC_OS_X_VERSION_10_7) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_7)
    if (&QCPlugInAttributeCategoriesKey != NULL) {
        // array with category strings
        NSArray* categories = [NSArray arrayWithObjects:@"Network", nil];
        [attributes setObject:categories forKey:QCPlugInAttributeCategoriesKey];
    }
    if (&QCPlugInAttributeExamplesKey != NULL) {
        // array of file paths or urls relative to plugin resources
        NSArray* examples = [NSArray arrayWithObjects:[[NSBundle bundleForClass:[self class]] URLForResource:WBReceiverExampleCompositionName withExtension:@"qtz"], nil];
        [attributes setObject:examples forKey:QCPlugInAttributeExamplesKey];
    }
#endif

    return (NSDictionary*)attributes;
}

+ (NSDictionary*)attributesForPropertyPortWithKey:(NSString*)key {
    if ([key isEqualToString:@"inputPort"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Port", QCPortAttributeNameKey, 
            [NSNumber numberWithUnsignedInteger:0], QCPortAttributeMinimumValueKey, 
            [NSNumber numberWithUnsignedInteger:65536], QCPortAttributeMaximumValueKey, 
            [NSNumber numberWithUnsignedInteger:7777], QCPortAttributeDefaultValueKey, nil];
	return nil;
}

+ (QCPlugInExecutionMode)executionMode {
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode)timeMode {
	return kQCPlugInTimeModeIdle;
}

#pragma mark - EXECUTION

- (BOOL)startExecution:(id <QCPlugInContext>)context {
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context {
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {
	return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context {
}

- (void)stopExecution:(id <QCPlugInContext>)context {
}

@end
