#import "WTTabBarController.h"
#import "WTLicenseViewController.h"
#import "AppDelegate.h"

@interface WTTabBarController () <WTLicenseViewControllerDelegate>

@end


@implementation WTTabBarController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:DID_ACCEPT_LICENSE_DEFAULTS_KEY]) {
        WTLicenseViewController *licenseVC = [self.storyboard instantiateViewControllerWithIdentifier:@"LicenseVC"];
        licenseVC.delegate = self;
        [self presentViewController:licenseVC animated:YES completion:nil];
    }
}

- (void)didAcceptLicense
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:DID_ACCEPT_LICENSE_DEFAULTS_KEY];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DID_ACCEPT_LICENSE_NOTIFICATION object:self];
}

@end
