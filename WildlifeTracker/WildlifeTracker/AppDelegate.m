#import "AppDelegate.h"
#import "DataController.h"
#import "AlarmController.h"
#import "SettingsViewController.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [Fabric with:@[[Crashlytics class]]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *installationId = [defaults stringForKey:INSTALLATION_ID_DEFAULTS_KEY];
    if (!installationId) {
        installationId = [[NSUUID UUID] UUIDString];
        [defaults setObject:installationId forKey:INSTALLATION_ID_DEFAULTS_KEY];
        [defaults synchronize];
    }
    
    // Defer asking for notifications until the user has accepted the licence agreement.
    if (![defaults boolForKey:DID_ACCEPT_LICENSE_DEFAULTS_KEY]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidAcceptLicenseNotification:)
                                                     name:DID_ACCEPT_LICENSE_NOTIFICATION
                                                   object:nil];
    } else {
        [self setupNotifications];
    }
    
    return YES;
}

- (void)handleDidAcceptLicenseNotification:(NSNotification *)notification
{
    [self setupNotifications];
}

- (void)setupNotifications
{
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        [self setupLocalNotifications];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self setupLocalNotifications];
}

- (void)setupLocalNotifications
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSLog (@"Cancelling any pre-existing notifications");
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    if ([[AlarmController sharedInstance] remindersEnabled]) {
        [[AlarmController sharedInstance] addAlertsForNext2Weeks];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if (![[AlarmController sharedInstance] remindersEnabled]) {
        NSLog (@"Disabling all notifications");
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
    else {
        NSLog (@"Alarms are still on");
    }
    
    // Whenever application becomes active, try submitting that data again
    [[DataController sharedInstance] resubmitUnsentData];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
