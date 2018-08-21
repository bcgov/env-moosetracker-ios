#import "WTLicenseViewController.h"

@interface WTLicenseViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewContentWidthConstraint;

@end

@implementation WTLicenseViewController

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.scrollViewContentWidthConstraint.constant = self.view.bounds.size.width;
    [self.view layoutIfNeeded];
}

- (IBAction)acceptButtonAction:(id)sender
{
    [self.delegate didAcceptLicense];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
