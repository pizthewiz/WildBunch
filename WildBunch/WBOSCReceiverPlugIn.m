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
@property (nonatomic, strong) PEOSCReceiver* receiver;
@property (nonatomic) BOOL messageReceived;
@property (nonatomic) BOOL messageReceivedSignalDidChange;
- (void)_buildUpReceiver;
- (void)_tearDownReceiver;
@end

@implementation WBOSCReceiverPlugIn

@dynamic inputPort, outputMessageReceived;
@synthesize port, receiver, messageReceived, messageReceivedSignalDidChange;

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
    else if ([key isEqualToString:@"outputMessageReceived"])
        return [NSDictionary dictionaryWithObject:@"Message Received" forKey:QCPortAttributeNameKey];
	return nil;
}

+ (QCPlugInExecutionMode)executionMode {
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode)timeMode {
	return kQCPlugInTimeModeIdle;
}

#pragma mark -

- (void)dealloc {
    [self _tearDownReceiver];
}

#pragma mark - EXECUTION

- (BOOL)startExecution:(id <QCPlugInContext>)context {
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context {
    // setup receiver when possible
    if (self.port) {
        [self _buildUpReceiver];
    }
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {
    // update outputs when appropriate
    if (self.messageReceivedSignalDidChange) {
        self.outputMessageReceived = self.messageReceived;
        self.messageReceivedSignalDidChange = self.messageReceived;
        self.messageReceived = NO;
    }
    
    // negotiate new connection
    if ([self didValueForInputKeyChange:@"inputPort"]) {
        CCDebugLog(@"port changed, will negotiate new connection");

        // store for safe keeping, may be needed stop/start
        self.port = self.inputPort;

        [self _buildUpReceiver];
    }

	return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context {
    [self _tearDownReceiver];
}

- (void)stopExecution:(id <QCPlugInContext>)context {
}

#pragma mark - RECEIVER DELEGATE

- (void)didReceiveMessage:(PEOSCMessage*)message {
    CCDebugLog(@"got %@", message);
    self.messageReceived = YES;
    self.messageReceivedSignalDidChange = YES;
}

#pragma mark - PRIVATE

- (void)_buildUpReceiver {
    CCDebugLogSelector();
    if (self.receiver) {
        [self _tearDownReceiver];
    }

    PEOSCReceiver* r = [[PEOSCReceiver alloc] initWithPort:self.port];
    self.receiver = r;
    self.receiver.delegate = self;
    [self.receiver connect];
}

- (void)_tearDownReceiver {
    CCDebugLogSelector();
    if (self.receiver.isConnected)
        [self.receiver disconnect];
    self.receiver = nil;
}

@end