#import "JTSReachability.h"
#import "NetworkController.h"

@interface NetworkController ()

@property (nonatomic, strong) NSOperationQueue *queue;

@end

@implementation NetworkController

+ (NetworkController *)sharedInstance
{
    static NetworkController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NetworkController alloc] init];
    });
    return sharedInstance;
}

- (id)init {

    self = [super init];
    if (self) {
        NSLog (@"Network Controller initialized");
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1; // Serial queue - only one outgoing request at a time
    }
    return self;
}

- (NSDictionary *)getDictionaryFrom:(NSData *)responseData {
    NSLog(@"%s data: %@", __PRETTY_FUNCTION__, responseData);
    
    NSError *error;
    NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
    if (!responseDictionary) {
        NSLog(@"Failed to convert data to dictionary: %@", error);
    } else {
        NSLog(@"Dictionary constructed out of data: %@", responseDictionary);
    }
    return responseDictionary;
}

- (NSString *)getJSONStringFrom:(NSDictionary *)valuesDictionary
{
    if ([NSJSONSerialization isValidJSONObject:valuesDictionary]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:valuesDictionary options:0 error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    } else {
        NSLog(@"Passed in an invalid NSDictionary");
        return nil;
    }
}

/*
- (void)printTypes:(NSDictionary *)valuesDictionary {
    NSLog(@"Type of values dictionary: %i", [valuesDictionary isKindOfClass:[NSDictionary class]]);
    NSLog(@"Type of value of dateString: %i", [[valuesDictionary objectForKey:@"date"] isKindOfClass:[NSString class]]);
    NSLog(@"number of cows is a string: %i", [[valuesDictionary objectForKey:@"numCows"] isKindOfClass:[NSString class]]);
    NSLog(@"number of bulls is a string: %i", [[valuesDictionary objectForKey:@"numBulls"] isKindOfClass:[NSString class]]);
    NSLog(@"number of calves is a string: %i", [[valuesDictionary objectForKey:@"numCalves"] isKindOfClass:[NSString class]]);
    NSLog(@"number of unknown is a string: %i", [[valuesDictionary objectForKey:@"numUnknown"] isKindOfClass:[NSString class]]);
    NSLog(@"number of hours is a string: %i", [[valuesDictionary objectForKey:@"numHours"] isKindOfClass:[NSString class]]);
}
 */
 

- (NSMutableURLRequest *)prepareAndGetURLRequestWithURL:(NSString *)urlString AndContent:(NSString *)jsonString
{
    NSLog(@"Trying to upload to server");
    NSLog(@"The URL: %@", urlString);
    NSURL *urlObject = [NSURL URLWithString:urlString];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:urlObject];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest addValue:@"form-data" forHTTPHeaderField:@"Content-Disposition"];
    [urlRequest setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"URL REQUEST: %@", urlRequest);    
    return urlRequest;
}

- (void)sendAsynchronousRequestWithDictionary:(NSDictionary *)requestValuesDictionary atURL:(NSString *)urlString completion:(void (^)(NSDictionary *, NSError *))completion
{
    NSString *jsonString = [self getJSONStringFrom:requestValuesDictionary];
    NSLog(@"%s JSON string: %@", __PRETTY_FUNCTION__, jsonString);
    NSMutableURLRequest *request = [self prepareAndGetURLRequestWithURL:urlString AndContent:jsonString];
    NSBlockOperation *blockOp = [NSBlockOperation blockOperationWithBlock:^{
        NSURLResponse *urlResponse;
        NSError *urlError;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&urlError];
        if (!responseData) {
            completion(nil, [NSError errorWithDomain:@"BCMooseTracker" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to create synchronous URLConnection"}]);
        } else if (urlError) {
            completion(nil, urlError);
        } else {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)urlResponse;
            if (response.statusCode != 200) {
                NSString *errMsg = [NSString stringWithFormat:@"Request failed with code %ld (%@) response: %@",
                                    (long)response.statusCode,
                                    [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode],
                                    [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]];
                completion(nil, [NSError errorWithDomain:@"BCMooseTracker" code:2 userInfo:@{NSLocalizedDescriptionKey: errMsg}]);
            } else {
                NSDictionary *responseDict = [self getDictionaryFrom:responseData];
                if (responseDict) {
                    completion(responseDict, nil);
                } else {
                    NSString *errMsg = [NSString stringWithFormat:@"Failed to parse JSON from response: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]];
                    completion(nil, [NSError errorWithDomain:@"BCMooseTracker" code:3 userInfo:@{NSLocalizedDescriptionKey: errMsg}]);
                }
            }
        }
    }];
    [self.queue addOperation:blockOp];
}

- (BOOL)serverIsReachable
{
    JTSReachability *reach = [JTSReachability reachabilityWithHostName:@"moose.nprg.ca"];
//    JTSReachability *reach = [JTSReachability reachabilityWithHostName:@"huntbuddybc.com"];
    JTSNetworkStatus internetStatus = [reach currentReachabilityStatus];
    if (internetStatus == NotReachable) {
        return NO;
    }
    return YES;
}

@end
