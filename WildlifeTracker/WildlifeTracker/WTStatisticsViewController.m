#import "WTStatisticsViewController.h"
#import "WTStatisticsChartView.h"
#import "DataController.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface WTStatisticsViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet WTStatisticsChartView *chartView;
@property (weak, nonatomic) IBOutlet UILabel *daysLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;
@property (weak, nonatomic) IBOutlet UILabel *mooseLabel;
@property (weak, nonatomic) IBOutlet UILabel *mooseDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *mooseRateLabel;
@property (weak, nonatomic) IBOutlet UIButton *regionButton;
@property (weak, nonatomic) IBOutlet UILabel *muLabel;
@property (weak, nonatomic) IBOutlet UIButton *muButton;

@property (strong, nonatomic) NSArray *monthLabels;
@property (nonatomic) NSInteger selectedRegionIndex;
@property (nonatomic) NSInteger selectedMUIndex;
@property (nonatomic) NSInteger savedRegionIndex;
@property (nonatomic) NSInteger savedMUIndex;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UITextField *pickerTextField;
@property (nonatomic) BOOL pickingRegion;
@property (strong, nonatomic) NSArray *regionList;
@property (strong, nonatomic) NSMutableArray *muListByRegion;

@end

@implementation WTStatisticsViewController

- (void)viewDidLoad {
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
    
    self.titleLabel.text = [NSString stringWithFormat:@"%ld Summary", (long)self.year];
    self.monthLabels = @[ @"Jan", @"Feb", @"Mar", @"Apr", @"May", @"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec" ];
    self.selectedRegionIndex = -1;
    self.selectedMUIndex = -1;
    [self setupMUPickerModel];
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
    
    self.chartView.hoursColor = UIColorFromRGB(0xfcb415);
    self.chartView.mooseColor = UIColorFromRGB(0x304fa2);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateButtons];
    [self updateSearchResults];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)regionCodeForIndex:(NSInteger)regionIndex
{
    if (regionIndex < 0)
        return nil;
    NSArray *components = [self.regionList[regionIndex] componentsSeparatedByString:@" "];
    return components[0];
}

- (void)updateButtons
{
    if (self.selectedRegionIndex < 0) {
        self.muLabel.hidden = YES;
        self.muButton.hidden = YES;
        [self.regionButton setTitle:@"All" forState:UIControlStateNormal];
    } else {
        [self.regionButton setTitle:[self regionCodeForIndex:self.selectedRegionIndex] forState:UIControlStateNormal];
        self.muLabel.hidden = NO;
        self.muButton.hidden = NO;
        if (self.selectedMUIndex < 0) {
            [self.muButton setTitle:@"All" forState:UIControlStateNormal];
        } else {
            NSArray *muList = self.muListByRegion[self.selectedRegionIndex];
            [self.muButton setTitle:muList[self.selectedMUIndex] forState:UIControlStateNormal];
        }
    }
}

- (void)updateSearchResults
{
    DataController *dc = [DataController sharedInstance];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"America/Vancouver"];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = self.year;
    components.month = 1;
    components.day = 1; // Leave hour, minute, second etc. == 0 --> midnight (start of day)
    NSDate *yearStart = [calendar dateFromComponents:components];
    NSMutableArray <WTStatisticsChartDataItem *> *data = [NSMutableArray array];
    BOOL gotSomeData = NO;
    int totalDays = 0;
    int totalHours = 0;
    int totalMoose = 0;
    int totalBulls = 0;
    int totalCows = 0;
    int totalCalves = 0;
    int totalUnknown = 0;
    NSInteger lastDay = -1;
    NSString *region = [self regionCodeForIndex:self.selectedRegionIndex];
    NSString *mu = nil;
    if (self.selectedMUIndex >= 0 && self.selectedRegionIndex >= 0) {
        NSArray *muList = self.muListByRegion[self.selectedRegionIndex];
        mu = muList[self.selectedMUIndex];
    }
    for (NSInteger i = 0; i < 12; i++) {
        lastDay = -1;
        NSDateComponents *addComponents = [[NSDateComponents alloc] init];
        addComponents.month = i;
        NSDate *fromDate = [calendar dateByAddingComponents:addComponents toDate:yearStart options:0];
        addComponents.month = i + 1;
        NSDate *toDate = [calendar dateByAddingComponents:addComponents toDate:yearStart options:0];
        NSArray<WTSightingData *> *sightings = [dc queryFromDate:fromDate toDate:toDate region:region mu:mu];
        NSInteger hours = 0;
        NSInteger moose = 0;
        for (WTSightingData *sighting in sightings) {
            NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:sighting.date];
            // Sightings are ordered by date, so to count unique days we just need to check that the date is the same or different
            if (components.day != lastDay) {
                totalDays += 1;
                lastDay = components.day;
            }
            totalHours += sighting.numHours;
            hours += sighting.numHours;
            NSInteger count = (sighting.numBulls + sighting.numCows + sighting.numCalves + sighting.numUnidentified);
            moose += count;
            totalMoose += count;
            totalBulls += sighting.numBulls;
            totalCows += sighting.numCows;
            totalCalves += sighting.numCalves;
            totalUnknown += sighting.numUnidentified;
            gotSomeData = YES;
        }
        // Include all months with data, and aug -> dec always
        if (gotSomeData || i >= 7) {
            WTStatisticsChartDataItem *item = [[WTStatisticsChartDataItem alloc] init];
            item.hours = hours;
            item.moose = moose;
            item.label = self.monthLabels[i];
            [data addObject:item];
        }
    }
    self.chartView.dataItems = data;
    
    NSString *daysStr = (totalDays == 1) ? @"day" : @"days";
    self.daysLabel.text = [NSString stringWithFormat:@"%d %@", totalDays, daysStr];
    
    NSString *hoursStr = (totalHours == 1) ? @"hour" : @"hours";
    self.hoursLabel.text = [NSString stringWithFormat:@"%d %@", totalHours, hoursStr];
    
    self.mooseLabel.text = [NSString stringWithFormat:@"%d moose", totalMoose];
    
    NSMutableString *detailStr = [NSMutableString string];
    if (totalBulls > 0) {
        [detailStr appendFormat:@"%d bull", totalBulls];
        if (totalBulls > 1)
            [detailStr appendString:@"s"];
    }
    if (totalCows > 0) {
        if (detailStr.length > 0)
            [detailStr appendString:@", "];
        [detailStr appendFormat:@"%d cow", totalCows];
        if (totalCows > 1)
            [detailStr appendString:@"s"];
    }
    if (totalCalves > 0) {
        if (detailStr.length > 0)
            [detailStr appendString:@", "];
        [detailStr appendFormat:@"%d cal", totalCalves];
        if (totalCalves > 1)
            [detailStr appendString:@"ves"];
        else
            [detailStr appendString:@"f"];
    }
    if (totalUnknown > 0) {
        if (detailStr.length > 0)
            [detailStr appendString:@", "];
        [detailStr appendFormat:@"%d unknown moose", totalUnknown];
    }
    self.mooseDetailLabel.text = detailStr;
    
    if (totalHours > 0) {
        self.mooseRateLabel.text = [NSString stringWithFormat:@"%.2f moose per hour", (float)totalMoose / (float)totalHours];
    } else {
        self.mooseRateLabel.text = @"";
    }
}

- (void)toolbarDoneAction:(UIButton *)sender
{
    if (self.selectedRegionIndex != self.savedRegionIndex) {
        self.selectedMUIndex = -1;
    }
    [self.pickerTextField resignFirstResponder];
    [self updateButtons];
    [self updateSearchResults];
}

- (void)toolbarCancelAction:(UIButton *)sender
{
    if (self.pickingRegion) {
        self.selectedRegionIndex = self.savedRegionIndex;
    } else {
        self.selectedMUIndex = self.savedMUIndex;
    }
    [self.pickerTextField resignFirstResponder];
}

- (IBAction)regionButtonAction:(id)sender
{
    self.pickingRegion = YES;
    self.savedRegionIndex = self.selectedRegionIndex;
    [self.pickerView selectRow:self.selectedRegionIndex + 1 inComponent:0 animated:NO];
    [self.pickerTextField becomeFirstResponder];
}

- (IBAction)muButtonAction:(id)sender
{
    self.pickingRegion = NO;
    self.savedRegionIndex = self.selectedRegionIndex;
    self.savedMUIndex = self.selectedMUIndex;
    [self.pickerView selectRow:self.selectedMUIndex + 1 inComponent:0 animated:NO];
    [self.pickerTextField becomeFirstResponder];
}

#pragma mark - UIPickerView methods

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
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (self.pickingRegion) {
        return self.regionList.count + 1;
    } else {
        NSArray *muList = self.muListByRegion[self.selectedRegionIndex];
        return muList.count + 1;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (self.pickingRegion) {
        if (row == 0) {
            return @"All Regions";
        } else {
            return self.regionList[row - 1];
        }
    } else {
        NSArray *muList = self.muListByRegion[self.selectedRegionIndex];
        if (row == 0) {
            return @"All MUs";
        } else {
            return muList[row - 1];
        }
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (self.pickingRegion) {
        self.selectedRegionIndex = row - 1;
    } else {
        self.selectedMUIndex = row - 1;
    }
}

@end
