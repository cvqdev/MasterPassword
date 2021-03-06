/**
 * Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
 *
 * See the enclosed file LICENSE for license information (LGPLv3). If you did
 * not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
 *
 * @author   Maarten Billemont <lhunath@lyndir.com>
 * @license  http://www.gnu.org/licenses/lgpl-3.0.txt
 */

//
//  MPLogsViewController.h
//  MPLogsViewController
//
//  Created by lhunath on 2013-04-29.
//  Copyright, lhunath (Maarten Billemont) 2013. All rights reserved.
//

#import "MPLogsViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPAppDelegate_Key.h"

@implementation MPLogsViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
            ^(NSNotification *note) {
                self.levelControl.selectedSegmentIndex = [[MPiOSConfig get].traceMode boolValue]? 1: 0;
            }];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self refresh:nil];

    self.levelControl.selectedSegmentIndex = [[MPiOSConfig get].traceMode boolValue]? 1: 0;
}

- (IBAction)action:(id)sender {

    [PearlSheet showSheetWithTitle:@"Advanced Actions" viewStyle:UIActionSheetStyleAutomatic
                         initSheet:nil tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex == sheet.cancelButtonIndex)
            return;

        if (buttonIndex == sheet.firstOtherButtonIndex) {
            [PearlAlert showAlertWithTitle:@"Switching iCloud Store" message:
                    @"WARNING: This is an advanced operation and should only be done if you're having trouble with iCloud."
                                 viewStyle:UIAlertViewStyleDefault initAlert:nil
                         tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex_) {
                             if (buttonIndex_ == alert.cancelButtonIndex)
                                 return;

                             [self switchCloudStore];
                         }     cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonContinue, nil];
        }
    }                  cancelTitle:[PearlStrings get].commonButtonCancel
                  destructiveTitle:nil otherTitles:@"Switch iCloud Store", nil];
}

- (void)switchCloudStore {

    NSError *error = nil;
    NSURL *cloudContentDirectory = [[MPiOSAppDelegate get].storeManager URLForCloudContentDirectory];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:cloudContentDirectory includingPropertiesForKeys:nil
                                                     options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    if (!contents)
    err(@"While enumerating cloud contents: %@", error);

    NSMutableArray *contentNames = [NSMutableArray arrayWithCapacity:[contents count]];
    BOOL directory = NO;
    for (NSURL *content in contents)
        if ([[NSFileManager defaultManager] fileExistsAtPath:content.path isDirectory:&directory] && directory)
            [contentNames addObject:[content lastPathComponent]];

    [PearlSheet showSheetWithTitle:[[MPiOSAppDelegate get].storeManager valueForKey:@"storeUUID_ThreadSafe"]
                         viewStyle:UIActionSheetStyleAutomatic
                         initSheet:^(UIActionSheet *sheet) {
                             for (NSString *contentName in contentNames) {
                                [sheet addButtonWithTitle:contentName];
                             }
                         }
                 tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
                     if (buttonIndex == sheet.cancelButtonIndex)
                         return;

                     [[MPiOSAppDelegate get].storeManager setValue:[contentNames objectAtIndex:(unsigned)buttonIndex] forKey:@"storeUUID"];
                     [[MPiOSAppDelegate get].storeManager reloadStore];
                     [[MPiOSAppDelegate get] signOutAnimated:YES];
                 }
                       cancelTitle:[PearlStrings get].commonButtonCancel destructiveTitle:nil otherTitles:nil];
}

- (IBAction)toggleLevelControl:(UISegmentedControl *)sender {

    BOOL traceEnabled = (BOOL)self.levelControl.selectedSegmentIndex;
    if (traceEnabled) {
        [PearlAlert showAlertWithTitle:@"Enable Trace Mode?" message:
                @"Trace mode will log the internal operation of the application.\n"
                        @"Unless you're looking for the cause of a problem, you should leave this off to save memory."
                             viewStyle:UIAlertViewStyleDefault initAlert:nil
                     tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                         if (buttonIndex == [alert cancelButtonIndex])
                             return;

                         [MPiOSConfig get].traceMode = @YES;
                     }     cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Enable Trace", nil];
    }
    else
        [MPiOSConfig get].traceMode = @NO;
}

- (IBAction)refresh:(UIBarButtonItem *)sender {

    self.logView.text = [[PearlLogger get] formatMessagesWithLevel:PearlLogLevelTrace];
}

- (IBAction)mail:(UIBarButtonItem *)sender {

    if ([[MPiOSConfig get].traceMode boolValue]) {
        [PearlAlert showAlertWithTitle:@"Hiding Trace Messages" message:
                @"Trace-level log messages will not be mailed. "
                        @"These messages contain sensitive and personal information."
                             viewStyle:UIAlertViewStyleDefault initAlert:nil
                     tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                         [[MPiOSAppDelegate get] openFeedbackWithLogs:YES forVC:self];
                     }     cancelTitle:[PearlStrings get].commonButtonOkay otherTitles:nil];
    }
    else
        [[MPiOSAppDelegate get] openFeedbackWithLogs:YES forVC:self];
}

@end
