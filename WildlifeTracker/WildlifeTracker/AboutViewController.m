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

@property (weak, nonatomic) IBOutlet UITextView *aboutTextView;
@property (weak, nonatomic) IBOutlet UIButton *emailButton;
@property (weak, nonatomic) IBOutlet UITextView *lowerTextView;
@property (weak, nonatomic) IBOutlet UIImageView *mooseImageView;

@end

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.mooseImageView.leadingAnchor constraintEqualToAnchor:self.lowerTextView.leadingAnchor constant:8.0].active = YES;
    [self.mooseImageView.topAnchor constraintEqualToAnchor:self.lowerTextView.topAnchor constant:12.0].active = YES;
    CGSize imageSize = self.mooseImageView.image.size;
    UIEdgeInsets textInsets = self.lowerTextView.textContainerInset;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(textInsets.left, textInsets.top, imageSize.width + 16.0, imageSize.height)];
    self.lowerTextView.textContainer.exclusionPaths = @[path];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.emailButton.enabled = [MFMailComposeViewController canSendMail];
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
