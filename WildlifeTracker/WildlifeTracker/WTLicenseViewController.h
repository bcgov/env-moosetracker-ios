//
//  WTLicenseViewController.h
//  WildlifeTracker
//
//  Created by John Griffith on 2015-09-12.
//  Copyright (c) 2015 John Griffith. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WTLicenseViewControllerDelegate <NSObject>

- (void)didAcceptLicense;

@end

@interface WTLicenseViewController : UIViewController

@property (nonatomic, weak) id<WTLicenseViewControllerDelegate> delegate;

@end
