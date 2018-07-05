//
//  SettingsViewController.m
//  WildlifeTracker
//
//  Created by John Griffith on 2015-09-03.
//  Copyright (c) 2015 John Griffith. All rights reserved.
//

#import "SettingsViewController.h"
#import "AlarmController.h"

@interface SettingsViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollContentWidthConstraint;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UISwitch *remindersSwitch;
@property (weak, nonatomic) IBOutlet UILabel *soundLabel;
@property (weak, nonatomic) IBOutlet UISwitch *soundSwitch;

@end

@implementation SettingsViewController

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if ([self respondsToSelector:@selector(bottomLayoutGuide)]) {
        CGFloat bottom = self.bottomLayoutGuide.length;
        // HACK - iOS 7 often returns wrong value; use tab bar height
        if ((bottom == 0) && self.tabBarController) {
            bottom = 49.0; // Would need different value for iPad
        }
        UIEdgeInsets insets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, bottom, 0);
        self.scrollView.contentInset = insets;
        self.scrollView.scrollIndicatorInsets = insets;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.scrollContentWidthConstraint.constant = self.view.bounds.size.width;
    [self.view layoutIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    AlarmController *alarmController = [AlarmController sharedInstance];
    self.remindersSwitch.on = alarmController.remindersEnabled;
    self.soundSwitch.on = alarmController.soundEnabled;
    self.soundLabel.enabled = alarmController.remindersEnabled;
    self.soundSwitch.enabled = alarmController.remindersEnabled;
    
    // Seems to be an iOS 6 bug where switching tabs when the scroll view is scrolled up messes with the
    // content offset when you switch back. Punt and just reset it to 0 always.
    if (![self respondsToSelector:@selector(topLayoutGuide)]) {
        [self.scrollView setContentOffset:CGPointZero animated:NO];
    }
}

- (IBAction)remindersSwitchValueChanged:(UISwitch *)sender
{
    self.soundLabel.enabled = sender.on;
    self.soundSwitch.enabled = sender.on;
    [[AlarmController sharedInstance] setRemindersEnabled:sender.on];
}

- (IBAction)soundSwitchValueChanged:(UISwitch *)sender
{
    [[AlarmController sharedInstance] setSoundEnabled:sender.on];
}

@end
