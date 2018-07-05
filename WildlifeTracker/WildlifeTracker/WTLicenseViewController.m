//
//  WTLicenseViewController.m
//  WildlifeTracker
//
//  Created by John Griffith on 2015-09-12.
//  Copyright (c) 2015 John Griffith. All rights reserved.
//

#import "WTLicenseViewController.h"

@interface WTLicenseViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewContentWidthConstraint;
@property (weak, nonatomic) IBOutlet UITextView *licenseTextView;

@property (strong, nonatomic) NSLayoutConstraint *textViewHeightConstraint;
@property (nonatomic) BOOL hasAppeared;

@end

@implementation WTLicenseViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_7_0) {
        self.textViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.licenseTextView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:0.0];
        [self.licenseTextView addConstraint:self.textViewHeightConstraint];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.scrollViewContentWidthConstraint.constant = self.view.bounds.size.width;
    [self.view layoutIfNeeded];
    if (self.textViewHeightConstraint) {
        self.textViewHeightConstraint.constant = [self.licenseTextView sizeThatFits:CGSizeMake(self.licenseTextView.frame.size.width, CGFLOAT_MAX)].height;
        [self.view layoutIfNeeded];
    }
    
    // Seems to be an iOS 7/8 bug where auto sizing the scroll content with the UITextView seems to reset the content
    // offset the first time. So here's a hack to reset it before first appearance if necessary.
    if (!self.hasAppeared && [self respondsToSelector:@selector(topLayoutGuide)]) {
        self.scrollView.contentOffset = CGPointMake(0.0, -self.topLayoutGuide.length);
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.hasAppeared = YES;
}

- (IBAction)acceptButtonAction:(id)sender
{
    [self.delegate didAcceptLicense];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
