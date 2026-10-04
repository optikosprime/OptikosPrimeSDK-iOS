#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Call on the main thread, just like other UIKit presentation methods.
@interface ObjCSDKExample : NSObject
+ (void)startFromViewController:(UIViewController *)presenter
                    licenseKey:(NSString *)licenseKey
                    completion:(void (^)(NSString *status))completion
    NS_SWIFT_NAME(start(from:licenseKey:completion:));
+ (void)checkCameraSupportWithLicenseKey:(NSString *)licenseKey
                             completion:(void (^)(NSString *status))completion
    NS_SWIFT_NAME(checkCameraSupport(licenseKey:completion:));
@end

NS_ASSUME_NONNULL_END
