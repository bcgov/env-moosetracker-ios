#import <UIKit/UIKit.h>

@protocol WTLicenseViewControllerDelegate <NSObject>

- (void)didAcceptLicense;

@end

@interface WTLicenseViewController : UIViewController

@property (nonatomic, weak) id<WTLicenseViewControllerDelegate> delegate;

@end
