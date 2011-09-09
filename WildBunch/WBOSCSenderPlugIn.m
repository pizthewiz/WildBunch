//
//  WBOSCSenderPlugIn.m
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 6 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import "WBOSCSenderPlugIn.h"
#import "WildBunch.h"
#import "WBOSCSenderViewController.h"

@interface NSDictionary(WBAdditions)
- (BOOL)hasKey:(NSString*)key;
@end
@implementation NSDictionary(WBAdditions)
- (BOOL)hasKey:(NSString*)key {
    return [self objectForKey:key] != nil;
}
@end

#pragma mark - PLUGIN

static NSString* const WBSenderExampleCompositionName = @"";

@interface WBOSCSenderPlugIn()
@property (nonatomic, strong) NSString* host;
@property (nonatomic) NSUInteger port;
@property (nonatomic, strong) NSMutableArray* messageParameters;
@property (nonatomic, strong) PEOSCSender* sender;
- (void)_buildUpSender;
- (void)_tearDownSender;
- (void)_addMessageParameter:(NSDictionary*)param;
- (void)_removeMessageParameter:(NSDictionary*)param;
- (void)_addPortForMessageParameter:(NSDictionary*)param;
- (NSArray*)_types;
- (NSArray*)_arguments;
@end

@implementation WBOSCSenderPlugIn

@dynamic inputHost, inputPort, inputSendSignal, inputAddress;
@synthesize host, port, messageParameters, sender;

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
	return nil;
}

+ (QCPlugInExecutionMode)executionMode {
	return kQCPlugInExecutionModeConsumer;
}

+ (QCPlugInTimeMode)timeMode {
	return kQCPlugInTimeModeNone;
}

+ (NSArray*)plugInKeys {
    return [NSArray arrayWithObjects:@"messageParameters", nil];
}

#pragma mark -

- (QCPlugInViewController*)createViewController {
	return [[WBOSCSenderViewController alloc] initWithPlugIn:self viewNibName:@"Settings"];
}

#pragma mark -

- (id)init {
    self = [super init];
    if (self) {
        self.messageParameters = [NSMutableArray array];
    }
    return self;
}

#pragma mark -

- (void)setSerializedValue:(id)serializedValue forKey:(NSString*)key {
    // setup params and ports
    if ([key isEqualToString:@"messageParameters"]) {
        self.messageParameters = [serializedValue mutableCopy];
        for (id param in self.messageParameters) {
            [self _addPortForMessageParameter:param];
        }
    } else {
        [super setSerializedValue:serializedValue forKey:key];
    }
}

#pragma mark - EXECUTION

- (BOOL)startExecution:(id <QCPlugInContext>)context {
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context {
    if (self.host && ![self.host isEqualToString:@""] && self.port)
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

    if ([self didValueForInputKeyChange:@"inputSendSignal"] && self.inputSendSignal) {
        NSArray* types = [self _types];
        if (!types.count) {
            CCErrorLog(@"ERROR - cannot send type-less message, consider using an Impulse instead");
            return YES;
        }
        PEOSCMessage* message = [[PEOSCMessage alloc] initWithAddress:self.inputAddress typeTags:types arguments:[self _arguments]];
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
    // NB - perhaps reconnect when possible
    PEOSCSender* s = [[PEOSCSender alloc] initWithHost:self.host port:self.port];
    self.sender = s;
}

- (void)_tearDownSender {
    // NB - disconnect is probably more appropriate
//    self.sender = nil;
}

- (void)_addMessageParameter:(NSDictionary*)param {
    [self _addPortForMessageParameter:param];

    [self willChangeValueForKey:@"messageParameters"];
    [self.messageParameters addObject:param];
    [self didChangeValueForKey:@"messageParameters"];
}

- (void)_removeMessageParameter:(NSDictionary*)param {
    if ([param hasKey:WBOSCMessageParameterPortKey]) {
        [self removeInputPortForKey:[param objectForKey:WBOSCMessageParameterPortKey]];
    }

    [self willChangeValueForKey:@"messageParameters"];
    [self.messageParameters removeObject:param];
    [self didChangeValueForKey:@"messageParameters"];
}

- (void)_addPortForMessageParameter:(NSDictionary*)param {
    if ([param hasKey:WBOSCMessageParameterPortKey]) {
        NSString* type = [param objectForKey:WBOSCMessageParameterTypeKey];
        NSString* portKey = [param objectForKey:WBOSCMessageParameterPortKey];
        if ([type isEqualToString:PEOSCMessageTypeTagInteger]) {
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC Integer", QCPortAttributeNameKey, [NSNumber numberWithInt:INT_MIN], QCPortAttributeMinimumValueKey, [NSNumber numberWithInt:INT_MAX], QCPortAttributeMaximumValueKey, [NSNumber numberWithInt:0], QCPortAttributeDefaultValueKey, nil];
            [self addInputPortWithType:QCPortTypeNumber forKey:portKey withAttributes:attributes];
        } else if ([type isEqualToString:PEOSCMessageTypeTagFloat]) {
            // NB - setting min and max seemes to mess up the 0.0 value to 1.175e-38
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC Float", QCPortAttributeNameKey, /*[NSNumber numberWithFloat:FLT_MIN], QCPortAttributeMinimumValueKey, [NSNumber numberWithFloat:FLT_MAX], QCPortAttributeMaximumValueKey,*/ [NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey, nil];
            [self addInputPortWithType:QCPortTypeNumber forKey:portKey withAttributes:attributes];
        } else if ([type isEqualToString:PEOSCMessageTypeTagString]) {
            NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"OSC String", QCPortAttributeNameKey, @"Log Lady", QCPortAttributeDefaultValueKey, nil];
            [self addInputPortWithType:QCPortTypeString forKey:portKey withAttributes:attributes];
        }
    }
}

- (NSArray*)_types {
    NSMutableArray* types = [NSMutableArray array];
    for (NSDictionary* param in self.messageParameters) {
        [types addObject:[param objectForKey:WBOSCMessageParameterTypeKey]];
    }
    return (NSArray*)types;
}

- (NSArray*)_arguments {
    NSMutableArray* args = [[NSMutableArray alloc] init];
    for (NSDictionary* param in self.messageParameters) {
        if (![param hasKey:WBOSCMessageParameterPortKey])
            continue;
        id value = [self valueForInputKey:[param objectForKey:WBOSCMessageParameterPortKey]];
        [args addObject:value];
    }
    return (NSArray*)args;
}

@end
