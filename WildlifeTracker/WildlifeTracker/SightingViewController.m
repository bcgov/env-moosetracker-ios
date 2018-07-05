//
//  FirstViewController.m
//  WildlifeTracker
//
//  Created by John Griffith on 2015-09-03.
//  Copyright (c) 2015 John Griffith. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SightingViewController.h"
#import "DataController.h"
#import "WTMUManager.h"
#import "AppDelegate.h"

@interface SightingViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UIAlertViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *scrollContentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollContentWidthConstraint;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIButton *dateButton;
@property (weak, nonatomic) IBOutlet UIView *datePickerView;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UILabel *muLabel;
@property (weak, nonatomic) IBOutlet UIButton *muButton;
@property (weak, nonatomic) IBOutlet UIView *muPickerView;
@property (weak, nonatomic) IBOutlet UIPickerView *muPicker;
@property (weak, nonatomic) IBOutlet UILabel *bullsCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *cowsCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *calvesCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *unidentifiedCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;
@property (weak, nonatomic) IBOutlet UIStepper *bullsStepper;
@property (weak, nonatomic) IBOutlet UIStepper *cowsStepper;
@property (weak, nonatomic) IBOutlet UIStepper *calvesStepper;
@property (weak, nonatomic) IBOutlet UIStepper *unidentifiedStepper;
@property (weak, nonatomic) IBOutlet UIStepper *hoursStepper;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSLayoutConstraint *hideDatePickerConstraint;
@property (strong, nonatomic) NSLayoutConstraint *hideMuPickerConstraint;
@property (nonatomic) NSInteger bullsCount;
@property (nonatomic) NSInteger cowsCount;
@property (nonatomic) NSInteger calvesCount;
@property (nonatomic) NSInteger unidentifiedCount;
@property (nonatomic) NSInteger hoursCount;
@property (strong, nonatomic) NSArray *regionList;
@property (strong, nonatomic) NSMutableArray *muListByRegion;
@property (strong, nonatomic) NSString *selectedMU;
@property (nonatomic) NSInteger selectedRegionIndex;
@property (nonatomic) NSInteger selectedMUIndex;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, copy) void (^alertCompletionBlock)(void);
@property (nonatomic, copy) void (^alertCancelBlock)(void);
@property (nonatomic) BOOL hasAppeared;
@property (nonatomic, weak) UIButton *dateDoneButton;
@property (nonatomic, weak) UIButton *muDoneButton;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic) BOOL didManuallyChangeMU;

@end

#define SELECTED_MU_DEFAULTS_KEY @"selectedMU"

@implementation SightingViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSubmitNotification:) name:SUBMIT_SUCCESSFUL_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSubmitNotification:) name:SUBMIT_FAILED_NOTIFICATION object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self showDatePicker:NO animated:NO];
    [self showMUPicker:NO animated:NO];
    
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"America/Vancouver"];
    self.datePicker.timeZone = timeZone;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
    self.dateFormatter.timeZone = timeZone;
    
    [self updateSelectedDate];
    
    [self setupMUPickerModel];
    self.muPicker.dataSource = self;
    self.muPicker.delegate = self;
    self.selectedMU = [[NSUserDefaults standardUserDefaults] stringForKey:SELECTED_MU_DEFAULTS_KEY];
    BOOL found = NO;
    self.selectedRegionIndex = 0;
    self.selectedMUIndex = 0;
    // Try and find old selected MU to preselect it in the picker
    if (self.selectedMU) {
        found = [self findIndexForMU:self.selectedMU];
    }
    if (!found) {
        self.selectedMU = @"1-1"; // We know that's the first MU in the first region
    }
    
    [self.muButton setTitle:self.selectedMU forState:UIControlStateNormal];
    
    if (floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_7_0) {
        self.dateButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        self.muButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    }
    
    [self updateUI];
}

- (BOOL)findIndexForMU:(NSString *)mu
{
    BOOL found = NO;
    for (NSInteger region = 0; region < [self.muListByRegion count]; region++) {
        NSArray *array = self.muListByRegion[region];
        for (NSInteger muIndex = 0; muIndex < [array count]; muIndex++) {
            if ([mu isEqualToString:array[muIndex]]) {
                found = YES;
                self.selectedRegionIndex = region;
                self.selectedMUIndex = muIndex;
                break;
            }
        }
        if (found)
            break;
    }
    return found;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSDate *now = [NSDate date];
    self.datePicker.maximumDate = now;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = -1;
    NSDate *lastYear = [calendar dateByAddingComponents:components toDate:now options:0];
    self.datePicker.minimumDate = lastYear;
    
    // Seems to be an iOS 6 bug where switching tabs when the scroll view is scrolled up messes with the
    // content offset when you switch back. Punt and just reset it to 0 always.
    if (![self respondsToSelector:@selector(topLayoutGuide)]) {
        [self.scrollView setContentOffset:CGPointZero animated:NO];
    }
    
    // Defer asking for location until the user has accepted the licence agreement.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:DID_ACCEPT_LICENSE_DEFAULTS_KEY]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidAcceptLicenseNotification:)
                                                     name:DID_ACCEPT_LICENSE_NOTIFICATION
                                                   object:nil];
    } else {
        [self startLocationMonitoring];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.muPicker selectRow:self.selectedRegionIndex inComponent:0 animated:(self.hideMuPickerConstraint == nil)];
    [self.muPicker selectRow:self.selectedMUIndex inComponent:1 animated:(self.hideMuPickerConstraint == nil)];
    self.hasAppeared = YES;
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollContentWidthConstraint.constant = self.view.bounds.size.width;
    [self.view layoutIfNeeded];
    
    // Seems to be an iOS 7/8 bug where auto sizing the scroll content seems to reset the content
    // offset the first time. So here's a hack to reset it before first appearance if necessary.
    if (!self.hasAppeared && [self respondsToSelector:@selector(topLayoutGuide)]) {
        self.scrollView.contentOffset = CGPointMake(0.0, -self.topLayoutGuide.length);
    }
}

- (void)handleDidAcceptLicenseNotification:(NSNotification *)notification
{
    [self startLocationMonitoring];
}

- (void)startLocationMonitoring {
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [self.locationManager requestWhenInUseAuthorization];
            }
        }
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    }
    if (!self.didManuallyChangeMU) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)updateSelectedDate
{
    // Extract year/month/day in local time from the date picker
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self.datePicker.date];
    
    // Compute noon on the same year/month/day, making sure it's in Vancouver time
    calendar.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"America/Vancouver"];
    components.hour = 12;
    self.selectedDate = [calendar dateFromComponents:components];
    
    // Update date button
    [self.dateButton setTitle:[self.dateFormatter stringFromDate:self.selectedDate] forState:UIControlStateNormal];
}

- (void)handleSubmitNotification:(NSNotification *)notification
{
    NSString *title;
    NSString *message;
    if ([notification.name isEqualToString:SUBMIT_FAILED_NOTIFICATION]) {
        title = @"Submit Deferred";
        message = @"There was a problem submitting your data. BC Moose Tracker will try again later.";
        // This could be a little white lie. If the data was refused by the server (valid response with
        // failure error code from JSON) it will not be retried. But that's really an internal error and
        // it's probably better to just reassure the user. It shouldn't happen in real life.
    } else {
        // Submit successful
        title = @"Thank You";
        message = @"Your data was successfully submitted to the server.";
    }
    if ([UIAlertController class]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)dateButtonAction:(id)sender
{
    [self showDatePicker:(self.hideDatePickerConstraint != nil) animated:YES];
}

- (IBAction)datePickerValueChanged:(UIDatePicker *)sender
{
    [self updateSelectedDate];
}

- (IBAction)muButtonAction:(id)sender
{
    [self showMUPicker:(self.hideMuPickerConstraint != nil) animated:YES];
}

- (IBAction)resetButtonAction:(id)sender
{
    if (sender) {
        // Only reset the pickers if the user actually hit the "Reset All" button. In particular, don't reset
        // the date or MU after submitting some sighting data.
        self.datePicker.date = [NSDate date];
        [self updateSelectedDate];
        
        self.didManuallyChangeMU = NO;
        self.location = nil;
        [self startLocationMonitoring];
    }
    
    self.bullsCount = 0;
    self.cowsCount = 0;
    self.calvesCount = 0;
    self.unidentifiedCount = 0;
    self.hoursCount = 0;
    [self updateUI];
}

- (IBAction)submitButtonAction:(id)sender
{
    if (self.hoursCount == 0) {
        NSString *errTitle = @"Hours Out";
        NSString *errMsg = @"Please enter the number of hours you were out watching for moose.";
        if ([UIAlertController class]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:errTitle
                                                                           message:errMsg
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errTitle
                                                            message:errMsg
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        return;
    }
    
    WTSightingData *sightingData = [[WTSightingData alloc] init];
    sightingData.date = self.selectedDate;
    sightingData.mu = self.selectedMU;
    sightingData.numBulls = self.bullsCount;
    sightingData.numCows = self.cowsCount;
    sightingData.numCalves = self.calvesCount;
    sightingData.numUnidentified = self.unidentifiedCount;
    sightingData.numHours = self.hoursCount;
    
    sightingData.sendNotification = YES;
    
    // Present alert to confirm submit
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    NSString *dateStr = [self.dateFormatter stringFromDate:self.selectedDate];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    NSMutableString *message = [NSMutableString stringWithFormat:@"%@, MU %@, %ld hour", dateStr, self.selectedMU, (long)self.hoursCount];
    if (self.hoursCount > 1)
        [message appendString:@"s"];
    [message appendString:@" out.\n"];
    if ((self.bullsCount + self.cowsCount + self.calvesCount + self.unidentifiedCount) == 0) {
        [message appendString:@"No moose sighted."];
    } else {
        BOOL first = YES;
        [message appendString:@"Sighted "];
        if (self.bullsCount > 0) {
            first = NO;
            [message appendFormat:@"%ld bull", (long)self.bullsCount];
            if (self.bullsCount > 1)
                [message appendString:@"s"];
        }
        if (self.cowsCount > 0) {
            if (first)
                first = NO;
            else
                [message appendString:@", "];
            [message appendFormat:@"%ld cow", (long)self.cowsCount];
            if (self.cowsCount > 1)
                [message appendString:@"s"];
        }
        if (self.calvesCount > 0) {
            if (first)
                first = NO;
            else
                [message appendString:@", "];
            [message appendFormat:@"%ld cal", (long)self.calvesCount];
            if (self.calvesCount > 1)
                [message appendString:@"ves"];
            else
                [message appendString:@"f"];
        }
        if (self.unidentifiedCount > 0) {
            if (!first)
                [message appendString:@", "];
            [message appendFormat:@"%ld unknown moose", (long)self.unidentifiedCount];
        }
        [message appendString:@"."];
    }
    NSString *title = @"Confirm Submit";
    if ([UIAlertController class]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *submitAction = [UIAlertAction actionWithTitle:@"Submit"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 [[DataController sharedInstance] submitData:sightingData];
                                                                 [self resetButtonAction:nil];
                                                             }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        [alert addAction:submitAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        __weak SightingViewController *weakSelf = self;
        self.alertCompletionBlock = ^(void) {
            [[DataController sharedInstance] submitData:sightingData];
            [weakSelf resetButtonAction:nil];
        };
        self.alertCancelBlock = nil;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Submit", nil];
        [alert show];
    }
}

- (IBAction)bullsStepperValueChanged:(UIStepper *)sender
{
    self.bullsCount = (NSInteger) sender.value;
    [self updateUI];
}

- (IBAction)cowsStepperValueChanged:(UIStepper *)sender
{
    self.cowsCount = (NSInteger) sender.value;
    [self updateUI];
}

- (IBAction)calvesStepperValueChanged:(UIStepper *)sender
{
    self.calvesCount = (NSInteger) sender.value;
    [self updateUI];
}

- (IBAction)unidentifiedStepperValueChanged:(UIStepper *)sender
{
    self.unidentifiedCount = (NSInteger) sender.value;
    [self updateUI];
}

- (IBAction)hoursStepperValueChanged:(UIStepper *)sender
{
    self.hoursCount = (NSInteger) sender.value;
    [self updateUI];
}

- (void)updateUI
{
    self.bullsCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.bullsCount];
    self.bullsStepper.value = (double) self.bullsCount;
    self.cowsCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.cowsCount];
    self.cowsStepper.value = (double) self.cowsCount;
    self.calvesCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.calvesCount];
    self.calvesStepper.value = (double) self.calvesCount;
    self.unidentifiedCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.unidentifiedCount];
    self.unidentifiedStepper.value = (double) self.unidentifiedCount;
    self.hoursLabel.text = [NSString stringWithFormat:@"%ld", (long)self.hoursCount];
    self.hoursStepper.value = (double) self.hoursCount;
}

- (UIButton *)addDoneButtonAnimated:(BOOL)animated action:(SEL)action label:(UILabel *)label labelText:(NSString *)labelText button:(UIButton *)button picker:(UIView *)picker
{
    UIButtonType buttonType;
    if (floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_7_0) {
        buttonType = UIButtonTypeRoundedRect;
    } else {
        buttonType = UIButtonTypeSystem;
    }
    UIButton *newButton = [UIButton buttonWithType:buttonType];
    [newButton setTitle:@"Done" forState:UIControlStateNormal];
    newButton.titleLabel.font = button.titleLabel.font;
    [newButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    newButton.alpha = 0.0;
    newButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollContentView addSubview:newButton];
    [self.scrollContentView addConstraint:[NSLayoutConstraint constraintWithItem:newButton
                                                                       attribute:NSLayoutAttributeCenterY
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:button
                                                                       attribute:NSLayoutAttributeCenterY
                                                                      multiplier:1.0
                                                                        constant:0.0]];
    [self.scrollContentView addConstraint:[NSLayoutConstraint constraintWithItem:newButton
                                                                       attribute:NSLayoutAttributeLeading
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:button
                                                                       attribute:NSLayoutAttributeLeading
                                                                      multiplier:1.0
                                                                        constant:0.0]];
    [self.scrollContentView addConstraint:[NSLayoutConstraint constraintWithItem:newButton
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:picker
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:-20.0]];
    [self.scrollContentView layoutIfNeeded];
    if (animated) {
        [UIView transitionWithView:label duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            label.text = labelText;
        } completion:nil];
        [UIView animateWithDuration:0.3 animations:^{
            button.alpha = 0.0;
            newButton.alpha = 1.0;
        } completion:nil];
    } else {
        label.text = labelText;
        button.alpha = 0.0;
        newButton.alpha = 1.0;
    }
    return newButton;
}

- (void)removeDoneButton:(UIButton *)doneButton animated:(BOOL)animated button:(UIButton *)button label:(UILabel *)label labelText:(NSString *)labelText
{
    if (animated) {
        [UIView transitionWithView:label duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            label.text = labelText;
        } completion:nil];
        [UIView animateWithDuration:0.3 animations:^{
            button.alpha = 1.0;
            doneButton.alpha = 0.0;
        } completion:^(BOOL finished) {
            [doneButton removeFromSuperview];
        }];
    } else {
        label.text = labelText;
        button.alpha = 1.0;
        [doneButton removeFromSuperview];
    }
}

- (void)showDatePicker:(BOOL)show animated:(BOOL)animated
{
    if (show && self.hideDatePickerConstraint) {
        self.dateDoneButton = [self addDoneButtonAnimated:animated action:@selector(dateButtonAction:) label:self.dateLabel labelText:@"Choose Date" button:self.dateButton picker:self.datePicker];
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                [self.datePickerView removeConstraint:self.hideDatePickerConstraint];
                [self.view layoutIfNeeded];
            } completion:nil];
        } else {
            [self.datePickerView removeConstraint:self.hideDatePickerConstraint];
        }
        self.hideDatePickerConstraint = nil;
    } else if (!show && !self.hideDatePickerConstraint) {
        [self removeDoneButton:self.dateDoneButton animated:animated button:self.dateButton label:self.dateLabel labelText:@"Date:"];
        self.hideDatePickerConstraint = [NSLayoutConstraint constraintWithItem:self.datePickerView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:0.0];
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                [self.datePickerView addConstraint:self.hideDatePickerConstraint];
                [self.view layoutIfNeeded];
            } completion:nil];
        } else {
            [self.datePickerView addConstraint:self.hideDatePickerConstraint];
        }
    }
}

- (void)showMUPicker:(BOOL)show animated:(BOOL)animated
{
    if (show && self.hideMuPickerConstraint) {
        self.muDoneButton = [self addDoneButtonAnimated:animated action:@selector(muButtonAction:) label:self.muLabel labelText:@"Choose MU" button:self.muButton picker:self.muPicker];
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                [self.muPickerView removeConstraint:self.hideMuPickerConstraint];
                [self.view layoutIfNeeded];
            } completion:nil];
        } else {
            [self.muPickerView removeConstraint:self.hideMuPickerConstraint];
        }
        self.hideMuPickerConstraint = nil;
    } else if (!show && !self.hideMuPickerConstraint) {
        [self removeDoneButton:self.muDoneButton animated:animated button:self.muButton label:self.muLabel labelText:@"MU:"];
        self.hideMuPickerConstraint = [NSLayoutConstraint constraintWithItem:self.muPickerView
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1.0
                                                                    constant:0.0];
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                [self.muPickerView addConstraint:self.hideMuPickerConstraint];
                [self.view layoutIfNeeded];
            } completion:nil];
        } else {
            [self.muPickerView addConstraint:self.hideMuPickerConstraint];
        }
    }
}

- (void)updatePickerFromSelectedMU
{
    [self.muButton setTitle:self.selectedMU forState:UIControlStateNormal];
    [[NSUserDefaults standardUserDefaults] setObject:self.selectedMU forKey:SELECTED_MU_DEFAULTS_KEY];
    [self.muPicker selectRow:self.selectedRegionIndex inComponent:0 animated:(self.hideMuPickerConstraint == nil)];
    [self.muPicker selectRow:self.selectedMUIndex inComponent:1 animated:(self.hideMuPickerConstraint == nil)];
}

#pragma mark - UIPickerView data source and delegate

- (void)setupMUPickerModel
{
    self.regionList = @[@"1 - Vancouver Island", @"2 - Lower Mainland", @"3 - Thompson", @"4 - Kootenay", @"5 - Cariboo", @"6 - Skeena", @"7A - Omineca", @"7B - Peace", @"8 - Okanagan"];
    self.muListByRegion = [NSMutableArray arrayWithCapacity:9];
    [self.muListByRegion addObject:[self createMUsForRegion:1 muRanges:@[@1, @15]]];
    [self.muListByRegion addObject:[self createMUsForRegion:2 muRanges:@[@1, @19]]];
    [self.muListByRegion addObject:[self createMUsForRegion:3 muRanges:@[@12, @20, @26, @46]]];
    [self.muListByRegion addObject:[self createMUsForRegion:4 muRanges:@[@1, @9, @14, @40]]];
    [self.muListByRegion addObject:[self createMUsForRegion:5 muRanges:@[@1, @16]]];
    [self.muListByRegion addObject:[self createMUsForRegion:6 muRanges:@[@1, @30]]];
    [self.muListByRegion addObject:[self createMUsForRegion:7 muRanges:@[@1, @18, @23, @30, @37, @41]]];  // 7A
    [self.muListByRegion addObject:[self createMUsForRegion:7 muRanges:@[@19, @22, @31, @36, @42, @58]]]; // 7B
    [self.muListByRegion addObject:[self createMUsForRegion:8 muRanges:@[@1, @15, @21, @26]]];
}

- (NSArray *)createMUsForRegion:(int)region muRanges:(NSArray *)muRanges
{
    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < (muRanges.count); i += 2) {
        for (int mu = [muRanges[i] intValue]; mu <= [muRanges[i + 1] intValue]; mu++) {
            [result addObject:[NSString stringWithFormat:@"%d-%d", region, mu]];
        }
    }
    return result;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    if (component == 0)
        return 240.0;
    else
        return 70.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) {
        return self.regionList.count;
    } else {
        return [self.muListByRegion[self.selectedRegionIndex] count];
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        return self.regionList[row];
    } else {
        return self.muListByRegion[self.selectedRegionIndex][row];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.didManuallyChangeMU = YES;
    // Save old sub-MU number to try and find closest one in new region
    NSInteger oldMU = 0;
    if (self.selectedMU.length > 2) { // Should always be true
        NSString *oldMUStr = [self.selectedMU substringFromIndex:2]; // e.g. "12"
        oldMU = [oldMUStr integerValue];
    }
    NSArray *array = self.muListByRegion[self.selectedRegionIndex];
    if ((component == 0) && (row != self.selectedRegionIndex)) {
        self.selectedRegionIndex = row;
        array = self.muListByRegion[row];
        [pickerView reloadComponent:1];
        NSInteger newIndex = NSNotFound;
        for (NSInteger i = 0; i < array.count; i++) {
            NSString *testMUStr = [array[i] substringFromIndex:2];
            if ([testMUStr integerValue] >= oldMU) {
                newIndex = i;
                break;
            }
        }
        if (newIndex == NSNotFound)
            newIndex = array.count - 1;
        [pickerView selectRow:newIndex inComponent:1 animated:YES];
    }
    self.selectedMUIndex = [pickerView selectedRowInComponent:1];
    self.selectedMU = [array objectAtIndex:self.selectedMUIndex];
    [self updatePickerFromSelectedMU];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        if (self.alertCancelBlock)
            self.alertCancelBlock();
    } else {
        if (self.alertCompletionBlock)
            self.alertCompletionBlock();
    }
    self.alertCompletionBlock = nil;
    self.alertCancelBlock = nil;
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    if (self.location) {
        NSLog(@"Got a location already. Ignoring didUpdateLocations call.");
        [self.locationManager stopUpdatingLocation];
        return;
    }

    NSUInteger numChecked = 0;
    for (CLLocation *loc in locations) {
        numChecked++;
        if (loc.horizontalAccuracy < 100.0) {
            // Accuracy OK - good to go.
            NSLog(@"Got valid location %@", loc);
            [self.locationManager stopUpdatingLocation];
            self.location = loc;
            break;
        } else {
            NSLog(@"CLLocation invalid accuracy %@", loc);
        }
    }
    
    if (self.location) {
        BOOL doUpdate = YES;
        if (self.didManuallyChangeMU) {
            NSLog(@"MU was manually selected. Ignoring location");
            doUpdate = NO;
        }
        if (![[WTMUManager sharedInstance] managementUnitsLoaded]) {
            NSLog(@"MUs not yet loaded. Register for notification to process later.");
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleMUsLoadedNotification:)
                                                         name:MUS_LOADED_NOTIFICATION
                                                       object:nil];
            doUpdate = NO;
        }
        if (doUpdate) {
            [self updateFromLocation:self.location];
        }
    }
    
    if (numChecked < locations.count) {
        NSLog(@"Ignoring %lu extra CLLocations", (unsigned long)(locations.count - numChecked));
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}

- (void)updateFromLocation:(CLLocation *)loc
{
    NSString *mu = [[WTMUManager sharedInstance] muFromLocation:loc.coordinate];
    if (mu) {
        if ([self findIndexForMU:mu]) {
            NSLog(@"Updating MU picker default to %@", mu);
            self.selectedMU = mu;
            [self updatePickerFromSelectedMU];
        } else {
            NSLog(@"Error: Failed to find MU %@ in picker view model", mu);
        }
    } else {
        NSLog(@"Failed to determine MU from location");
    }
}

#pragma mark - Notification callback

- (void)handleMUsLoadedNotification:(NSNotification *)notification
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.location && !self.didManuallyChangeMU) {
        [self updateFromLocation:self.location];
    }
}

@end




