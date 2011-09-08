//
//  WBOSCSenderPlugIn.m
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 6 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import "WBOSCSenderPlugIn.h"
#import "WildBunch.h"

static NSString* const WBSenderExampleCompositionName = @"";

@interface WBOSCSenderPlugIn()
@property (nonatomic, strong) NSString* host;
@property (nonatomic) NSUInteger port;
@property (nonatomic, strong) NSArray* types;
@property (nonatomic, strong) NSArray* argumentPortKeys;
@property (nonatomic, strong) PEOSCSender* sender;
- (void)_buildUpSender;
- (void)_tearDownSender;
- (void)_setupInputs:(NSString*)typesString;
- (NSArray*)_arguments;
@end

@implementation WBOSCSenderPlugIn

@dynamic inputHost, inputPort, inputSendSignal, inputAddress, inputTypes;
@synthesize host, port, types, argumentPortKeys, sender;

+ (NSDictionary*)attributes {
    NSMutableDictionary* attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
        CCLocalizedString(@"WBOSCSenderName", NULL), QCPlugInAttributeNameKey, 
        CCLocalizedString(@"WBOSCSenderDescription", NULL), QCPlugInAttributeDescriptionKey, 
        nil];

#if defined(MAC_OS_X_VERSION_10_7) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_7)
    if (&QCPlugInAttributeCategoriesKey != NULL) {
        // array with category strings
        NSArray* categories = [NSArray arrayWithObjects:@"Network", nil];
        [attributes setObject:categories forKey:QCPlugInAttributeCategoriesKey];
    }
    if (&QCPlugInAttributeExamplesKey != NULL) {
        // array of file paths or urls relative to plugin resources
        NSArray* examples = [NSArray arrayWithObjects:[[NSBundle bundleForClass:[self class]] URLForResource:WBSenderExampleCompositionName withExtension:@"qtz"], nil];
        [attributes setObject:examples forKey:QCPlugInAttributeExamplesKey];
    }
#endif

    return (NSDictionary*)attributes;
}

+ (NSDictionary*)attributesForPropertyPortWithKey:(NSString*)key {
    if ([key isEqualToString:@"inputHost"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Host", QCPortAttributeNameKey, QCPortTypeString, QCPortAttributeTypeKey, @"0.0.0.0", QCPortAttributeDefaultValueKey, nil];
    else if ([key isEqualToString:@"inputPort"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Port", QCPortAttributeNameKey, 
            [NSNumber numberWithUnsignedInteger:0], QCPortAttributeMinimumValueKey, 
            [NSNumber numberWithUnsignedInteger:65536], QCPortAttributeMaximumValueKey, 
            [NSNumber numberWithUnsignedInteger:7777], QCPortAttributeDefaultValueKey, nil];
    else if ([key isEqualToString:@"inputSendSignal"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Send Signal", QCPortAttributeNameKey, nil];
    else if ([key isEqualToString:@"inputAddress"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Address", QCPortAttributeNameKey, QCPortTypeString, QCPortAttributeTypeKey, @"/oscillator/3/frequency", QCPortAttributeDefaultValueKey, nil];
    if ([key isEqualToString:@"inputTypes"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Types", QCPortAttributeNameKey, QCPortTypeString, QCPortAttributeTypeKey, @"ifsTFNI", QCPortAttributeDefaultValueKey, nil];
	return nil;
}

+ (QCPlugInExecutionMode)executionMode {
	return kQCPlugInExecutionModeConsumer;
}

+ (QCPlugInTimeMode)timeMode {
	return kQCPlugInTimeModeIdle;
}

#pragma mark -

- (QCPlugInViewController*)createViewController {
	return [[QCPlugInViewController alloc] initWithPlugIn:self viewNibName:@"Settings"];
}

#pragma mark - EXECUTION

- (BOOL)startExecution:(id <QCPlugInContext>)context {
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context {
    if (self.host && self.port)
        [self _buildUpSender];
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments {
    // negotiate new connection
    if ([self didValueForInputKeyChange:@"inputHost"] || [self didValueForInputKeyChange:@"inputPort"]) {
        CCDebugLog(@"host or port changed, will negotiate new connection");

        // store for safe keeping, may be needed stop/start
        self.host = self.inputHost;
        self.port = self.inputPort;

        [self _buildUpSender];
    }

    // MEGA UGLY DYNAMIC PORT SHIT
    if ([self didValueForInputKeyChange:@"inputTypes"]) {
        [self performSelector:@selector(_setupInputs:) withObject:self.inputTypes afterDelay:0.0];
    }

    if ([self didValueForInputKeyChange:@"inputSendSignal"] && self.inputSendSignal) {
        PEOSCMessage* message = [[PEOSCMessage alloc] initWithAddress:self.inputAddress typeTags:self.types arguments:[self _arguments]];
        CCDebugLog(@"will send: %@", message);
        [self.sender sendMessage:message];
    }

	return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context {
    [self _tearDownSender];
}

- (void)stopExecution:(id <QCPlugInContext>)context {
}

#pragma mark - PRIVATE

- (void)_buildUpSender {
    PEOSCSender* s = [[PEOSCSender alloc] initWithHost:self.host port:self.port];
    self.sender = s;
}

- (void)_tearDownSender {
    self.sender = nil;
}

- (void)_setupInputs:(NSString*)typesString {
    // remove ports
    // TODO - only remove deltas?
    if (self.argumentPortKeys.count) {
        for (NSString* portKey in self.argumentPortKeys) {
            [self removeInputPortForKey:portKey];
        }
    }

    NSMutableArray* messageTypes = [[NSMutableArray alloc] init];
    NSMutableArray* portKeys = [[NSMutableArray alloc] init];

    // TODO - validate types
    for (NSUInteger idx = 0; idx < typesString.length; idx++) {
        NSString* type = [typesString substringWithRange:NSMakeRange(idx, 1)];
        NSString* portKey = [NSString stringWithFormat:@"argument-%d.%d", (long)[[NSDate date] timeIntervalSince1970], idx];
        BOOL didAddPort = NO;
        if ([type isEqualToString:@"i"]) {
            [messageTypes addObject:PEOSCMessageTypeTagInteger];
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC Integer", QCPortAttributeNameKey, [NSNumber numberWithInt:INT_MIN], QCPortAttributeMinimumValueKey, [NSNumber numberWithInt:INT_MAX], QCPortAttributeMaximumValueKey, [NSNumber numberWithInt:0], QCPortAttributeDefaultValueKey, nil];
            [self addInputPortWithType:QCPortTypeNumber forKey:portKey withAttributes:attributes];
            didAddPort = YES;
        } else if ([type isEqualToString:@"f"]) {
            [messageTypes addObject:PEOSCMessageTypeTagFloat];
            // NB - setting min and max seemes to mess up the 0 value to 1.175e-38
//            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC Float", QCPortAttributeNameKey, [NSNumber numberWithFloat:FLT_MIN], QCPortAttributeMinimumValueKey, [NSNumber numberWithFloat:FLT_MAX], QCPortAttributeMaximumValueKey, [NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey, nil];
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC Float", QCPortAttributeNameKey, [NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey, nil];
            [self addInputPortWithType:QCPortTypeNumber forKey:portKey withAttributes:attributes];
            didAddPort = YES;
        } else if ([type isEqualToString:@"s"]) {
            [messageTypes addObject:PEOSCMessageTypeTagString];
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC String", QCPortAttributeNameKey, @"Log Lady", QCPortAttributeDefaultValueKey, nil];
            [self addInputPortWithType:QCPortTypeString forKey:portKey withAttributes:attributes];
            didAddPort = YES;
        } else if ([type isEqualToString:@"T"]) {
            [messageTypes addObject:PEOSCMessageTypeTagTrue];
        } else if ([type isEqualToString:@"F"]) {
            [messageTypes addObject:PEOSCMessageTypeTagFalse];
        } else if ([type isEqualToString:@"N"]) {
            [messageTypes addObject:PEOSCMessageTypeTagNull];
        } else if ([type isEqualToString:@"I"]) {
            [messageTypes addObject:PEOSCMessageTypeTagImpulse];
        }

        // NB - for now, only add ports to types that require arguments
        if (didAddPort) {
            [portKeys addObject:portKey];
        }
    }

    self.types = messageTypes;
    self.argumentPortKeys = portKeys;
}

- (NSArray*)_arguments {
    NSMutableArray* args = [[NSMutableArray alloc] init];
    for (NSString* portKey in self.argumentPortKeys) {
        id value = [self valueForInputKey:portKey];
        [args addObject:value];
    }
    return (NSArray*)args;
}

@end
