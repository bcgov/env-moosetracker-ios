#import <MapKit/MapKit.h>
#import "WTMapViewController.h"
#import "WTMUOverlay.h"
#import "WTMUManager.h"
#import "HBCLabelOverlay.h"
#import "HBCLabelOverlayRenderer.h"

@interface WTMapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *mapTypeControl;
@property (strong, nonatomic) UIView *mapTypeBackgroundView;
@property (strong, nonatomic) CLLocationManager *locationManager;

// For manual entry of MU labels
@property (strong, nonatomic) NSMutableArray *labelOverlays;
@property (strong, nonatomic) HBCLabelOverlay *lastOverlay;

@end

@implementation WTMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        self.locationManager = [[CLLocationManager alloc] init];
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
    }
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
    WTMUManager *muManager = [WTMUManager sharedInstance];
    NSArray <WTManagementUnit *> *allMUs = [muManager allManagementUnits];
    if (allMUs) {
        [self addMUOverlays:allMUs];
    } else {
        // Not loaded yet. Register for the notification and add the overlays later.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMUsLoadedNotification:)
                                                     name:MUS_LOADED_NOTIFICATION
                                                   object:nil];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double spanLat = [defaults doubleForKey:@"mapSpanLatitude"];
    double spanLon = [defaults doubleForKey:@"mapSpanLongitude"];
    double centerLat = [defaults doubleForKey:@"mapCenterLatitude"];
    double centerLon = [defaults doubleForKey:@"mapCenterLongitude"];
    if ((centerLat != 0.0) && (centerLon != 0.0) && (spanLat != 0.0) && (spanLon != 0.0)) {
        [self.mapView setRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake(centerLat, centerLon), MKCoordinateSpanMake(spanLat, spanLon)) animated:NO];
    }
    
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.mapTypeBackgroundView = blurView;
    UIView *controlContainer = [blurView contentView];

    self.mapTypeBackgroundView.layer.cornerRadius = 5.0;
    self.mapTypeBackgroundView.clipsToBounds = YES;
    self.mapTypeBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mapTypeBackgroundView];
    
    self.mapTypeControl.translatesAutoresizingMaskIntoConstraints = NO;
    [controlContainer addSubview:self.mapTypeControl];
    NSDictionary *views = @{ @"control": self.mapTypeControl };
    [controlContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-1-[control]-1-|" options:0 metrics:nil views:views]];
    [controlContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-1-[control]-2-|" options:0 metrics:nil views:views]];
    
    [self.mapTypeBackgroundView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    if (@available(iOS 11, *)) {
        [self.mapTypeBackgroundView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:6.0].active = YES;
    } else {
        [self.mapTypeBackgroundView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:6.0].active = YES;
    }
    
    // Code for manual entry of MU label locations
    /*
    UIButton *undoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [undoButton setTitle:@"Undo" forState:UIControlStateNormal];
    undoButton.frame = CGRectMake(40.0, 40.0, 100.0, 40.0);
    undoButton.translatesAutoresizingMaskIntoConstraints = YES;
    [undoButton addTarget:self action:@selector(undoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:undoButton];
    
    UIButton *dumpButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [dumpButton setTitle:@"Dump" forState:UIControlStateNormal];
    dumpButton.frame = CGRectMake(180.0, 40.0, 100.0, 40.0);
    dumpButton.translatesAutoresizingMaskIntoConstraints = YES;
    [dumpButton addTarget:self action:@selector(dumpButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dumpButton];
    
    self.labelOverlays = [NSMutableArray array];
    UILongPressGestureRecognizer *lpRec = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [self.view addGestureRecognizer:lpRec];
    */
}

- (void)undoButtonAction:(id)sender
{
    if (!self.lastOverlay)
        return;
    [self.mapView removeOverlay:self.lastOverlay];
    [self.labelOverlays removeObject:self.lastOverlay];
    self.lastOverlay = nil;
}

- (void)dumpButtonAction:(id)sender
{
    NSMutableArray *array = [NSMutableArray array];
    for (HBCLabelOverlay *overlay in self.labelOverlays) {
        [array addObject:@{@"name": overlay.label, @"lat": @(overlay.coordinate.latitude), @"lon": @(overlay.coordinate.longitude)}];
    }
    NSString *tempDir = NSTemporaryDirectory();
    NSString *path = [tempDir stringByAppendingPathComponent:@"labels.plist"];
    [array writeToFile:path atomically:YES];
    NSLog(@"Wrote label info to file: %@", path);
}

- (void)longPressAction:(UILongPressGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateEnded)
        return;
    CGPoint touchPoint = [sender locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    NSString *mu = [[WTMUManager sharedInstance] muFromLocation:touchMapCoordinate];
    if (!mu)
        return;
    HBCLabelOverlay *newLabel = [[HBCLabelOverlay alloc] init];
    newLabel.coordinate = touchMapCoordinate;
    newLabel.label = mu;
    [self.labelOverlays addObject:newLabel];
    self.lastOverlay = newLabel;
    [self.mapView addOverlay:newLabel level:MKOverlayLevelAboveRoads];
}

- (IBAction)mapTypeValueChanged:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.mapView.mapType = MKMapTypeStandard;
            break;
        case 1:
            self.mapView.mapType = MKMapTypeSatellite;
            break;
        case 2:
            self.mapView.mapType = MKMapTypeHybrid;
            break;
        default:
            break;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:self.mapView.region.center.latitude forKey:@"mapCenterLatitude"];
    [defaults setDouble:self.mapView.region.center.longitude forKey:@"mapCenterLongitude"];
    [defaults setDouble:self.mapView.region.span.latitudeDelta forKey:@"mapSpanLatitude"];
    [defaults setDouble:self.mapView.region.span.longitudeDelta forKey:@"mapSpanLongitude"];
    [defaults synchronize];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleMUsLoadedNotification:(NSNotification *)notification
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSArray <WTManagementUnit *> *allMUs = [[WTMUManager sharedInstance] allManagementUnits];
    [self addMUOverlays:allMUs];
}

- (void)addMUOverlays:(NSArray <WTManagementUnit *> *)muList {
    for (WTManagementUnit *mu in muList) {
        WTMUOverlay *overlay = [[WTMUOverlay alloc] initWithMU:mu];
        [self.mapView addOverlay:overlay level:MKOverlayLevelAboveRoads];
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"labels" ofType:@"plist"];
    NSArray *labelsArray = [NSArray arrayWithContentsOfFile:path];
    for (NSDictionary *dict in labelsArray) {
        HBCLabelOverlay *overlay = [[HBCLabelOverlay alloc] init];
        overlay.label = dict[@"name"];
        NSNumber *lat = dict[@"lat"];
        NSNumber *lon = dict[@"lon"];
        overlay.coordinate = CLLocationCoordinate2DMake([lat doubleValue], [lon doubleValue]);
        [self.mapView addOverlay:overlay level:MKOverlayLevelAboveRoads];
    }
}

#pragma mark - MKMapViewDelegate methods

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[WTMUOverlay class]]) {
        return [(WTMUOverlay *)overlay renderer];
    } else if ([overlay isKindOfClass:[HBCLabelOverlay class]]) {
        return [[HBCLabelOverlayRenderer alloc] initWithOverlay:(HBCLabelOverlay *)overlay];
    }
    return nil;
}

@end
