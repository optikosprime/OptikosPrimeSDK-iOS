#import "ObjCSDKExample.h"
#import <OptikosPrimeSDK/OptikosPrimeSDK-Swift.h>

@implementation ObjCSDKExample

+ (void)startFromViewController:(UIViewController *)presenter
                    licenseKey:(NSString *)licenseKey
                    completion:(void (^)(NSString *))completion {
    NSAssert([NSThread isMainThread], @"Present the SDK on the main thread.");
    if (presenter.presentedViewController != nil) {
        return;
    }

    NSError *error = nil;
    if (![OptikosPrimeSDK initializeWithLicenseKey:licenseKey
                                      environment:OptikosPrimeEnvironmentProduction
                                            error:&error]) {
        completion(error.localizedDescription ?: @"SDK initialization failed.");
        return;
    }

    __weak UIViewController *weakPresenter = presenter;
    UIViewController *controller = [OptikosPrimeSDK
        visionCheckViewControllerWithIsOlderThan43:YES
        error:&error
        completion:^(NSData *resultJSON, NSString *failure) {
            [weakPresenter dismissViewControllerAnimated:YES completion:nil];
            if ([failure isEqualToString:@"cancelled"]) {
                completion(@"The test was cancelled.");
            } else if (failure != nil) {
                completion([@"The test failed: " stringByAppendingString:failure]);
            } else if (resultJSON != nil) {
                // Objective-C receives the completed result as JSON data.
                NSString *json = [[NSString alloc] initWithData:resultJSON encoding:NSUTF8StringEncoding];
                completion([@"Completed: " stringByAppendingString:json ?: @"No readable result."]);
            } else {
                completion(@"The test returned no result.");
            }
        }];

    if (controller == nil) {
        completion(error.localizedDescription ?: @"Unable to start the vision check.");
        return;
    }
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [presenter presentViewController:controller animated:YES completion:nil];
}

@end
