//
//  WBOSCSenderViewController.m
//  WildBunch
//
//  Created by Jean-Pierre Mouilleseaux on 8 Sept 2011.
//  Copyright (c) 2011 Chorded Constructions. All rights reserved.
//

#import "WBOSCSenderViewController.h"
#import "WildBunch.h"

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

//    [self.plugIn performSelector:@selector(_addMessageElement:) withObject:];
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
