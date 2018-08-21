#import "SettingsViewController.h"
#import "AlarmController.h"

@interface SettingsViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UISwitch *remindersSwitch;
@property (weak, nonatomic) IBOutlet UILabel *soundLabel;
@property (weak, nonatomic) IBOutlet UISwitch *soundSwitch;

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (@available(iOS 11, *)) {
        // Dumb. Can't do "if not available"
    } else {
        // Bit of a hack. Add 20 points for status bar on iOS < 11, assuming the automatic inset adjustment doesn't happen.
        UIEdgeInsets insets = UIEdgeInsetsZero;
        insets.top = 20.0;
        insets.bottom = self.tabBarController.tabBar.frame.size.height;
        self.scrollView.contentInset = insets;
        self.scrollView.scrollIndicatorInsets = insets;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    AlarmController *alarmController = [AlarmController sharedInstance];
    self.remindersSwitch.on = alarmController.remindersEnabled;
    self.soundSwitch.on = alarmController.soundEnabled;
    self.soundLabel.enabled = alarmController.remindersEnabled;
    self.soundSwitch.enabled = alarmController.remindersEnabled;
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
