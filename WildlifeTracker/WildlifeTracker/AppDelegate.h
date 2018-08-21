#import <UIKit/UIKit.h>

// NSUserDefaults keys
#define INSTALLATION_ID_DEFAULTS_KEY @"installId"
#define DID_ACCEPT_LICENSE_DEFAULTS_KEY @"WTUserDidAcceptLicense"

// NSNotification names
#define DID_ACCEPT_LICENSE_NOTIFICATION @"WTUserDidAcceptLicenseNotification"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

