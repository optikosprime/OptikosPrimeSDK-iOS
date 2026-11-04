#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Call on the main thread, just like other UIKit presentation methods.
@interface ObjCSDKExample : NSObject
+ (void)startFromViewController:(UIViewController *)presenter
                    licenseKey:(NSString *)licenseKey
     useDevelopmentEnvironment:(BOOL)useDevelopmentEnvironment
                    completion:(void (^)(NSString *status))completion
    NS_SWIFT_NAME(start(from:licenseKey:useDevelopmentEnvironment:completion:));
+ (void)checkCameraSupportWithLicenseKey:(NSString *)licenseKey
             useDevelopmentEnvironment:(BOOL)useDevelopmentEnvironment
                             completion:(void (^)(NSString *status))completion
    NS_SWIFT_NAME(checkCameraSupport(licenseKey:useDevelopmentEnvironment:completion:));
@end

NS_ASSUME_NONNULL_END
