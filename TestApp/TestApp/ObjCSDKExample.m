#import "ObjCSDKExample.h"
#import <OptikosPrimeSDK/OptikosPrimeSDK-Swift.h>

static NSString *ConclusionName(OptikosPrimeConclusion conclusion) {
    switch (conclusion) {
        case OptikosPrimeConclusionNormal: return @"normal";
        case OptikosPrimeConclusionFinding: return @"finding";
        case OptikosPrimeConclusionInconclusive: return @"inconclusive";
    }
    return @"unknown";
}

static NSString *QuestionnaireName(OptikosPrimeQuestionResult assessment) {
    switch (assessment) {
        case OptikosPrimeQuestionResultNotAnswered: return @"notAnswered";
        case OptikosPrimeQuestionResultNormal: return @"normal";
        case OptikosPrimeQuestionResultMyopia: return @"myopia";
        case OptikosPrimeQuestionResultHyperopia: return @"hyperopia";
        case OptikosPrimeQuestionResultAstigmatism: return @"astigmatism";
        case OptikosPrimeQuestionResultPresbyopia: return @"presbyopia";
    }
    return @"unknown";
}

@implementation ObjCSDKExample

+ (void)startFromViewController:(UIViewController *)presenter
                    licenseKey:(NSString *)licenseKey
                    completion:(void (^)(NSString *))completion {
    NSAssert([NSThread isMainThread], @"Present the SDK on the main thread.");
    if (presenter.presentedViewController != nil) {
        return;
    }

    NSError *error = nil;
    if (![OptikosPrimeSDK isInitialized] && ![OptikosPrimeSDK initializeWithLicenseKey:licenseKey
                                      environment:OptikosPrimeEnvironmentProduction
                                            error:&error]) {
        completion(error.localizedDescription ?: @"SDK initialization failed.");
        return;
    }

    __weak UIViewController *weakPresenter = presenter;
    UIViewController *controller = [OptikosPrimeSDK
        visionCheckViewControllerWithIsOlderThan43:YES
        error:&error
        completion:^(OptikosPrimeOutcome *outcome) {
            [weakPresenter dismissViewControllerAnimated:YES completion:nil];
            switch (outcome.status) {
                case OptikosPrimeStatusCompleted: {
                    OptikosPrimeResult *result = outcome.result;
                    NSString *assessment = result.questionnaire == OptikosPrimeQuestionResultNotAnswered
                        ? @"Camera assessment"
                        : [NSString stringWithFormat:@"Questionnaire assessment: %@",
                           QuestionnaireName(result.questionnaire)];
                    completion([NSString stringWithFormat:@"Completed: %@\n%@\nMeasurement: %@",
                                ConclusionName(result.conclusion), assessment, result.measurementID]);
                    break;
                }
                case OptikosPrimeStatusCancelled:
                    completion(@"The test was cancelled.");
                    break;
                case OptikosPrimeStatusFailed:
                    if ([outcome.error.domain isEqualToString:[OptikosPrimeSDK errorDomain]] &&
                        outcome.error.code == OptikosPrimeErrorCodeDeviceNotSupported) {
                        completion(@"This device is not supported.");
                    } else {
                        completion(outcome.error.localizedDescription);
                    }
                    break;
            }
        }];

    if (controller == nil) {
        completion(error.localizedDescription ?: @"Unable to start the vision check.");
        return;
    }
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [presenter presentViewController:controller animated:YES completion:nil];
}

+ (void)checkCameraSupportWithLicenseKey:(NSString *)licenseKey completion:(void (^)(NSString *))completion {
    NSError *error = nil;
    if (![OptikosPrimeSDK isInitialized] &&
        ![OptikosPrimeSDK initializeWithLicenseKey:licenseKey environment:OptikosPrimeEnvironmentProduction error:&error]) {
        completion(error.localizedDescription);
        return;
    }
    [OptikosPrimeSDK getCameraInfoWithCompletion:^(OptikosPrimeCameraInfo *info, NSError *error) {
        completion(error != nil ? error.localizedDescription :
                   (info.supported ? @"Camera is supported." : @"This device is not supported."));
    }];
}

@end
