//
//  WBOSCSenderViewController.m
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 8 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import "WBOSCSenderViewController.h"
#import "WildBunch.h"
#import "WBOSCSenderPlugIn.h"

static BOOL shouldAddPortForType(NSString* type) {
    BOOL status = NO;
    if ([type isEqualToString:PEOSCMessageTypeTagInteger] || [type isEqualToString:PEOSCMessageTypeTagFloat] || [type isEqualToString:PEOSCMessageTypeTagString] || [type isEqualToString:PEOSCMessageTypeTagBlob])
        status = YES;
    return status;
}

@interface WBOSCSenderViewController()
@property (nonatomic, strong) NSArray* types;
@end

@implementation WBOSCSenderViewController

@synthesize elements, typeTagPopUpBotton, types;

- (void)awakeFromNib {
    self.types = [NSArray arrayWithObjects:PEOSCMessageTypeTagInteger, PEOSCMessageTypeTagFloat, PEOSCMessageTypeTagString, PEOSCMessageTypeTagTrue, PEOSCMessageTypeTagFalse, PEOSCMessageTypeTagNull, PEOSCMessageTypeTagImpulse, nil];

    [self.typeTagPopUpBotton removeAllItems];
    [self.typeTagPopUpBotton addItemsWithTitles:self.types];
}

#pragma mark -

- (IBAction)addMessageElement:(id)sender {
    CCDebugLogSelector();

    NSString* type = [self.types objectAtIndex:self.typeTagPopUpBotton.indexOfSelectedItem];
    BOOL shouldAddPort = shouldAddPortForType(type);
    NSString* portKey = shouldAddPort ? [NSString stringWithFormat:@"argument-%d.d", (long)[[NSDate date] timeIntervalSince1970], [(NSArray*)self.elements.content count]] : nil;

    WBMessageElement* element = [WBMessageElement messageElementWithType:type portKey:portKey];
    [self.plugIn performSelector:@selector(_addMessageElement:) withObject:element];
}

- (IBAction)removeMessageElement:(id)sender {
    CCDebugLogSelector();

    NSUInteger selectionIndex = [self.elements selectionIndex];
    if (selectionIndex == NSNotFound)
        return;

    id element = [(NSArray*)self.elements.content objectAtIndex:selectionIndex];
    [self.plugIn performSelector:@selector(_removeMessageElement:) withObject:element];
}

@end
