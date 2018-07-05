//
//  AboutViewController.m
//  WildlifeTracker
//
//  Created by John Griffith on 2015-09-06.
//  Copyright (c) 2015 John Griffith. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "AboutViewController.h"
#import "AppDelegate.h"

@interface AboutViewController () <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *scrollContentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewContentWidthConstraint;
@property (weak, nonatomic) IBOutlet UITextView *aboutTextView;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UITextView *lowerTextView;
@property (weak, nonatomic) IBOutlet UIImageView *mooseImageView;

@property (strong, nonatomic) NSLayoutConstraint *textViewHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *lowerTextViewHeightConstraint;
@property (nonatomic) BOOL hasAppeared;

@end

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (floor(NSFoundationVersionNumber) < floor(NSFoundationVersionNumber_iOS_7_0)) {
        self.textViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.aboutTextView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:0.0];
        [self.aboutTextView addConstraint:self.textViewHeightConstraint];
        self.lowerTextViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.lowerTextView
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:0.0];
        [self.lowerTextView addConstraint:self.lowerTextViewHeightConstraint];
    } else {
        [self.scrollContentView addConstraint:[NSLayoutConstraint constraintWithItem:self.mooseImageView
                                                                           attribute:NSLayoutAttributeLeading
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.lowerTextView
                                                                           attribute:NSLayoutAttributeLeading
                                                                          multiplier:1.0
                                                                            constant:8.0]];
        [self.scrollContentView addConstraint:[NSLayoutConstraint constraintWithItem:self.mooseImageView
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.lowerTextView
                                                                           attribute:NSLayoutAttributeTop
                                                                          multiplier:1.0
                                                                            constant:12.0]];
        CGSize imageSize = self.mooseImageView.image.size;
        UIEdgeInsets textInsets = self.lowerTextView.textContainerInset;
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(textInsets.left, textInsets.top, imageSize.width + 16.0, imageSize.height)];
        self.lowerTextView.textContainer.exclusionPaths = @[path];
    }
}

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
    self.scrollViewContentWidthConstraint.constant = self.view.bounds.size.width;
    [self.view layoutIfNeeded];
    if (self.textViewHeightConstraint) {
        self.textViewHeightConstraint.constant = [self.aboutTextView sizeThatFits:CGSizeMake(self.aboutTextView.frame.size.width, CGFLOAT_MAX)].height;
        self.lowerTextViewHeightConstraint.constant = [self.lowerTextView sizeThatFits:CGSizeMake(self.lowerTextView.frame.size.width, CGFLOAT_MAX)].height;
        [self.view layoutIfNeeded];
    }
    
    // Seems to be an iOS 7/8 bug where auto sizing the scroll content with the UITextView seems to reset the content
    // offset the first time. So here's a hack to reset it before first appearance if necessary.
    if (!self.hasAppeared && [self respondsToSelector:@selector(topLayoutGuide)]) {
        self.scrollView.contentOffset = CGPointMake(0.0, -self.topLayoutGuide.length);
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Seems to be an iOS 6 bug where switching tabs when the scroll view is scrolled up messes with the
    // content offset when you switch back. Punt and just reset it to 0 always.
    if (![self respondsToSelector:@selector(topLayoutGuide)]) {
        [self.scrollView setContentOffset:CGPointZero animated:NO];
    }
    
    self.emailButton.enabled = [MFMailComposeViewController canSendMail];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.hasAppeared = YES;
}

- (IBAction)doneButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)bcButtonAction:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.gov.bc.ca/wildlifehealth/moosetracker"]];
}

- (IBAction)hctfButtonAction:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.hctf.ca"]];
}

- (IBAction)bcwfButtonAction:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bcwf.net"]];
}

- (IBAction)infoButtonAction:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.gov.bc.ca/wildlifehealth/moosetracker"]];
}

- (IBAction)emailButtonAction:(id)sender
{
    MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
    [mailVC setSubject:@"App Question"];
    [mailVC setToRecipients:@[@"moosetracker@gov.bc.ca"]];
    UIDevice *device = [UIDevice currentDevice];
    NSString *installationId = [[NSUserDefaults standardUserDefaults] stringForKey:INSTALLATION_ID_DEFAULTS_KEY];
    [mailVC setMessageBody:[NSString stringWithFormat:@"\n\n\nModel: %@\nOS: %@ %@\nInstallation: %@", [device localizedModel], [device systemName], [device systemVersion], installationId] isHTML:NO];
    mailVC.mailComposeDelegate = self;
    [self presentViewController:mailVC animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
