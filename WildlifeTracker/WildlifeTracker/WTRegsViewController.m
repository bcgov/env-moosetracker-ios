#import <QuickLook/QuickLook.h>
#import "WTRegsViewController.h"

@interface WTRegsPDFPreviewItem : NSObject <QLPreviewItem>

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *title;

@end

@implementation WTRegsPDFPreviewItem

- (NSURL *)previewItemURL
{
    return self.url;
}

- (NSString *)previewItemTitle
{
    return self.title;
}
@end


@interface WTRegsViewController () <QLPreviewControllerDataSource, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) QLPreviewController *previewController;
@property (nonatomic, strong) NSArray *sectionNames;
@property (nonatomic, strong) NSArray *sectionTitles;
@property (nonatomic, strong) UIView *indexView;
@property (nonatomic, strong) UIButton *indexButton;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UITextField *pickerTextField;

@end

@implementation WTRegsViewController

static BOOL didShowDisclaimer = NO;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.sectionNames = @[@"general", @"region_1", @"region_2", @"region_3", @"region_4", @"region_5", @"region_6", @"region_7a", @"region_7b", @"region_8", @"trapping"];
        self.sectionTitles = @[@"General",
                               @"Region 1 - Vancouver Island",
                               @"Region 2 - Lower Mainland",
                               @"Region 3 - Thompson",
                               @"Region 4 - Kootenay",
                               @"Region 5 - Cariboo",
                               @"Region 6 - Skeena",
                               @"Region 7A - Omineca",
                               @"Region 7B - Peace",
                               @"Region 8 - Okanagan",
                               @"Trapping"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.previewController = [[QLPreviewController alloc] init];
    self.previewController.dataSource = self;
    [self addChildViewController:self.previewController];
    self.previewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.previewController.view];
    NSMutableDictionary *views = [NSMutableDictionary dictionary];
    views[@"preview"] = self.previewController.view;
    NSLayoutAnchor *topLayoutAnchor;
    NSLayoutAnchor *bottomLayoutAnchor;
    if (@available(iOS 11, *)) {
        topLayoutAnchor = self.view.safeAreaLayoutGuide.topAnchor;
        bottomLayoutAnchor = self.view.safeAreaLayoutGuide.bottomAnchor;
    } else {
        topLayoutAnchor = self.topLayoutGuide.bottomAnchor;
        bottomLayoutAnchor = self.bottomLayoutGuide.topAnchor;
    }
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[preview]|" options:0 metrics:nil views:views]];
    // For the top, always extend all the way under status bar / safe area
    [self.view.topAnchor constraintEqualToAnchor:self.previewController.view.topAnchor].active = YES;
    // On the bottom we can stop at the tab bar
    [bottomLayoutAnchor constraintEqualToAnchor:self.previewController.view.bottomAnchor].active = YES;
    [self.previewController didMoveToParentViewController:self];
    self.previewController.currentPreviewItemIndex = 0;
    
    
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.indexView = blurView;
    UIView *buttonContainer = blurView.contentView;
    self.indexView.layer.cornerRadius = 8.0;
    self.indexView.clipsToBounds = YES;
    self.indexView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.indexView];
    views[@"index"] = self.indexView;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[index(70)]-|" options:0 metrics:nil views:views]];
    // Place the index button below the safe area / top layout guide
    [self.indexView.topAnchor constraintEqualToAnchor:topLayoutAnchor constant:8.0].active = YES;
    [self.indexView.heightAnchor constraintEqualToConstant:31.0].active = YES;
    
    self.indexButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.indexButton setTitle:@"Index" forState:UIControlStateNormal];
    [self.indexButton addTarget:self action:@selector(indexButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.indexButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonContainer addSubview:self.indexButton];
    [buttonContainer.centerXAnchor constraintEqualToAnchor:self.indexButton.centerXAnchor].active = YES;
    [buttonContainer.centerYAnchor constraintEqualToAnchor:self.indexButton.centerYAnchor].active = YES;
    
    self.pickerTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.pickerTextField];
    
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
    self.pickerView.showsSelectionIndicator = YES;
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    self.pickerTextField.inputView = self.pickerView;
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toolbarDoneAction:)];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(toolbarCancelAction:)];
    toolBar.items = @[cancelButton, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], doneButton];
    self.pickerTextField.inputAccessoryView = toolBar;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!didShowDisclaimer) {
        didShowDisclaimer = YES;
        NSString *title = @"Warning";
        NSString *message = @"The British Columbia Hunting and Trapping Regulations Synopsis is intended for general information purposes only. Where there is a discrepancy between this synopsis and the Regulations, the Regulations are the final authority. Regulations are subject to change from time to time, and it is the responsibility of an individual to be informed of the current Regulations.\n\nTo ensure you have the most up to date hunting regulations please refer to the online version.";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *onlineAction = [UIAlertAction actionWithTitle:@"View Online"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www2.gov.bc.ca/gov/content/sports-culture/recreation/fishing-hunting/hunting/regulations-synopsis"]];
                                                             }];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            [alert addAction:onlineAction];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)indexButtonAction:(UIButton *)sender
{
    self.indexButton.enabled = NO;
    [self.pickerView selectRow:self.previewController.currentPreviewItemIndex inComponent:0 animated:NO];
    [self.pickerTextField becomeFirstResponder];
}

#pragma mark - UIPickerView methods

- (void)toolbarDoneAction:(UIButton *)sender
{
    self.previewController.currentPreviewItemIndex = [self.pickerView selectedRowInComponent:0];
    [self.pickerTextField resignFirstResponder];
    self.indexButton.enabled = YES;
}

- (void)toolbarCancelAction:(UIButton *)sender
{
    [self.pickerTextField resignFirstResponder];
    self.indexButton.enabled = YES;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 11;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.sectionTitles[row];
}

#pragma mark - QLPreviewControllerDataSource methods

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return 11;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    NSLog(@"%s index=%ld", __PRETTY_FUNCTION__, (long)index);
    NSURL *url = [[NSBundle mainBundle] URLForResource:self.sectionNames[index] withExtension:@"pdf"];
    if (url) {
        WTRegsPDFPreviewItem *item = [[WTRegsPDFPreviewItem alloc] init];
        item.url = url;
        item.title = self.sectionTitles[index];
        return item;
    }
    return nil;
}

@end
