//
//  PrefController.m
//  Coccinellida
//  
//  Licensed under GPL v3 Terms
//
//  Created by Dmitry Geurkov on 10/5/09.
//  Copyright 2009-2011. All rights reserved.
//

#import "PrefController.h"

@implementation PrefController

- (void) awakeFromNib {
	
	[toolbar setSelectedItemIdentifier: [generalToolbarItem itemIdentifier]];
	[tabView selectTabViewItem:[tabView tabViewItemAtIndex: 0]];
	[self selectGeneral: nil];
	
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"sound"] == nil){
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"sound"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"notification"] == nil){
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"notification"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"update"] == nil){
		[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"update"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	[soundEffectsButton setState: [[NSUserDefaults standardUserDefaults] boolForKey: @"sound"] ? NSOnState : NSOffState];
	[notificationsButton setState: [[NSUserDefaults standardUserDefaults] boolForKey: @"notification"] ? NSOnState : NSOffState];
	[checkForUpdatesButton setState: [[NSUserDefaults standardUserDefaults] boolForKey: @"update"] ? NSOnState : NSOffState];
	
	// Check for updates
	[updater setAutomaticallyChecksForUpdates: [checkForUpdatesButton state] == NSOnState ? YES : NO];
	[updater resetUpdateCycle];
	
	// Check startup on login
    if ([self isLaunchAtStartup]) {
		[lanchOnStartupButton setState: NSOnState];
	}else{
		[lanchOnStartupButton setState: NSOffState];
	}
}

- (IBAction) enableSoundEffects: (id) sender {
	[[NSUserDefaults standardUserDefaults] setBool: [soundEffectsButton state] == NSOnState forKey: @"sound"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) enableNotifications: (id) sender {
	[[NSUserDefaults standardUserDefaults] setBool: [notificationsButton state] == NSOnState forKey: @"notification"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) checkForUpdates: (id) sender {
	[[NSUserDefaults standardUserDefaults] setBool: [checkForUpdatesButton state] == NSOnState forKey: @"update"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[updater setAutomaticallyChecksForUpdates: [checkForUpdatesButton state] == NSOnState ? YES : NO];
	[updater resetUpdateCycle];
}

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar {	
    return [NSArray arrayWithObjects: [generalToolbarItem itemIdentifier], [tunnelsToolbarItem itemIdentifier], nil];
}

- (IBAction) showPrefWindow: (id) sender {
	[toolbar setSelectedItemIdentifier: [generalToolbarItem itemIdentifier]];
	if(![prefWindow isVisible]){
		[prefWindow center];
	}
	[prefWindow orderFrontRegardless];
	[self selectGeneral: sender];
}

- (IBAction) selectGeneral: (id) sender {
	[tabView selectTabViewItem:[tabView tabViewItemAtIndex: 0]];
	NSRect r = [prefWindow frame];
	r.origin.x = [prefWindow frame].origin.x - (350 - [prefWindow frame].size.width);
    r.origin.y = [prefWindow frame].origin.y - (230 - [prefWindow frame].size.height);
    r.size.width = 350;
	r.size.height = 230;
	[prefWindow setFrame: r display: YES animate: YES];
}

- (IBAction) selectTunnels: (id) sender {
	[tabView selectTabViewItem:[tabView tabViewItemAtIndex: 1]];
	NSRect r = [prefWindow frame];
	r.origin.x = [prefWindow frame].origin.x - (480 - [prefWindow frame].size.width);
    r.origin.y = [prefWindow frame].origin.y - (380 - [prefWindow frame].size.height);
    r.size.width = 480;
	r.size.height = 380;
    [prefWindow setFrame: r display: YES animate: YES];
}

- (IBAction) launchOnStartup: (id) sender {
	if([lanchOnStartupButton state] == NSOnState){
        if (![self isLaunchAtStartup]) {
            [self toggleLaunchAtStartup];
        }
	}else{
        if ([self isLaunchAtStartup]) {
            [self toggleLaunchAtStartup];
        }
	}
}

- (BOOL)isLaunchAtStartup {
    // See if the app is currently in LoginItems.
    LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
    // Store away that boolean.
    BOOL isInList = itemRef != nil;
    // Release the reference if it exists.
    if (itemRef != nil) CFRelease(itemRef);
    
    return isInList;
}

- (void)toggleLaunchAtStartup {
    // Toggle the state.
    BOOL shouldBeToggled = ![self isLaunchAtStartup];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return;
    if (shouldBeToggled) {
        // Add the app to the LoginItems list.
        CFURLRef appUrl = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
        if (itemRef) CFRelease(itemRef);
    }
    else {
        // Remove the app from the LoginItems list.
        LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
        LSSharedFileListItemRemove(loginItemsRef,itemRef);
        if (itemRef != nil) CFRelease(itemRef);
    }
    CFRelease(loginItemsRef);
}

- (LSSharedFileListItemRef)itemRefInLoginItems {
    LSSharedFileListItemRef res = nil;
    
    // Get the app's URL.
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return nil;
    // Iterate over the LoginItems.
    NSArray *loginItems = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, nil);
    for (id item in loginItems) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)(item);
        CFURLRef itemURLRef;
        if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
            // Again, use toll-free bridging.
            NSURL *itemURL = (__bridge NSURL *)itemURLRef;
            if ([itemURL isEqual:bundleURL]) {
                res = itemRef;
                break;
            }
        }
    }
    // Retain the LoginItem reference.
    if (res != nil) CFRetain(res);
    CFRelease(loginItemsRef);
    CFRelease((__bridge CFTypeRef)(loginItems));
    
    return res;
}

@end
