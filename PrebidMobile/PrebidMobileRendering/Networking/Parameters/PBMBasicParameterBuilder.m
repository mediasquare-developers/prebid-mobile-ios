/*   Copyright 2018-2021 Prebid.org, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "PBMConstants.h"
#import "PBMMacros.h"
#import "PBMORTB.h"

#import "InternalUserConsentDataManager.h"

#import "PBMBasicParameterBuilder.h"

#import "PrebidMobileSwiftHeaders.h"
#if __has_include("PrebidMobile-Swift.h")
#import "PrebidMobile-Swift.h"
#else
#import <PrebidMobile/PrebidMobile-Swift.h>
#endif

#pragma mark - Internal Extension

@interface PBMBasicParameterBuilder ()

// Note: properties below are marked with 'readwrite' for UnitTests to be able to write 'nil' into them.
// TODO: Prove that 'init' arguments are never nil; convert to 'readonly'; remove redundant checks and tests.

@property (nonatomic, strong, readwrite) PBMAdConfiguration *adConfiguration;
@property (nonatomic, strong, readwrite) Prebid *sdkConfiguration;
@property (nonatomic, strong, readwrite) Targeting *targeting;
@property (nonatomic, copy, readwrite) NSString *sdkVersion;

@end

#pragma mark - Implementation

@implementation PBMBasicParameterBuilder

#pragma mark - Properties

+ (NSString *)platformKey {
    return @"sp";
}

+ (NSString *)platformValue {
    return @"iOS";
}

+ (NSString *)allowRedirectsKey {
    return @"dr";
}

+ (NSString *)allowRedirectsVal {
    return @"true";
}

+ (NSString *)sdkVersionKey {
    return @"sv";
}

+ (NSString *)urlKey {
    return PBMParameterKeysAPP_STORE_URL;
}

+ (NSString*)rewardedVideoKey {
    return @"vrw";
}

+ (NSString*)rewardedVideoValue {
    return @"1";
}

#pragma mark - Initialization

- (instancetype)initWithAdConfiguration:(PBMAdConfiguration *)adConfiguration
                       sdkConfiguration:(Prebid *)sdkConfiguration
                             sdkVersion:(NSString *)sdkVersion
                              targeting:(Targeting *)targeting
{
    if (!(self = [super init])) {
        return nil;
    }
    PBMAssert(adConfiguration && sdkConfiguration && sdkVersion && targeting);
    
    _adConfiguration = adConfiguration;
    _sdkConfiguration = sdkConfiguration;
    _sdkVersion = sdkVersion;
    _targeting = targeting;
    
    return self;
}

#pragma mark - Methods

- (void)buildBidRequest:(PBMORTBBidRequest *)bidRequest {
    if (!(self.adConfiguration && self.sdkConfiguration && self.sdkVersion)) {
        PBMLogError(@"Invalid properties");
        return;
    }

    //Add an impression if none exist
    if ([bidRequest.imp count] == 0) {
        bidRequest.imp = @[[[PBMORTBImp alloc] init]];
    }
    
    for (PBMORTBImp *rtbImp in bidRequest.imp) {
        rtbImp.displaymanager = self.adConfiguration.isOriginalAPI ? nil : @"prebid-mobile";
        rtbImp.displaymanagerver = self.adConfiguration.isOriginalAPI ? nil : self.sdkVersion;
        
        rtbImp.instl = @(self.adConfiguration.presentAsInterstitial ? 1 : 0);
        
        //set secure=1 for https or secure=0 for http
        rtbImp.secure = @1;
        
        rtbImp.clickbrowser = @(self.sdkConfiguration.impClickbrowserType);
    }
    
    bidRequest.regs.coppa = self.targeting.coppa;
    bidRequest.regs.ext[@"gdpr"] = [self.targeting getSubjectToGDPR];
    bidRequest.regs.gpp = InternalUserConsentDataManager.gppHDRString;
    
    if (InternalUserConsentDataManager.gppSID.count > 0) {
        bidRequest.regs.gppSID = InternalUserConsentDataManager.gppSID;
    }
    
    [self appendFormatSpecificParametersForRequest:bidRequest];
}

- (void)appendFormatSpecificParametersForRequest:(PBMORTBBidRequest *)bidRequest {
    if ([self.adConfiguration.adFormats containsObject:AdFormat.banner] || [self.adConfiguration.adFormats containsObject:AdFormat.display]) {
        [self appendDisplayParametersForRequest:bidRequest];
    }
    
    if ([self.adConfiguration.adFormats containsObject:AdFormat.video]) {
        [self appendVideoParametersForRequest:bidRequest];
    }
    
    if ([self.adConfiguration.adFormats containsObject:AdFormat.native]) {
        [self appendNativeParametersForRequest:bidRequest];
    }
}

- (void)appendDisplayParametersForRequest:(PBMORTBBidRequest *)bidRequest {
    //Ensure there's at least 1 banner
    BOOL hasBanner = NO;
    for (PBMORTBImp *imp in bidRequest.imp) {
        if (imp.banner) {
            hasBanner = YES;
            break;
        }
    }
    
    if (!hasBanner) {
        [bidRequest.imp firstObject].banner = [[PBMORTBBanner alloc] init];
    }
}

- (void)appendVideoParametersForRequest:(PBMORTBBidRequest *)bidRequest {
    [bidRequest.imp firstObject].video = [[PBMORTBVideo alloc] init];
}

- (void)appendNativeParametersForRequest:(PBMORTBBidRequest *)bidRequest {
    [bidRequest.imp firstObject].native = [[PBMORTBNative alloc] init];
}

#pragma mark - MSQ Methods

- (void)buildMsqRequest:(nonnull PBMORTBMsqRequest *)bidRequest {
    if (!(self.adConfiguration && self.sdkConfiguration && self.sdkVersion)) {
        PBMLogError(@"Invalid properties");
        return;
    }
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    //Add an empty impression if there is none
    if (bidRequest.codes.count == 0) {
        bidRequest.codes = @[[[Code alloc] init]];
    }
    
    for (Code *code in bidRequest.codes) {
        [self configureCodeObject:code withUuid:uuid];
    }
}

- (void)configureCodeObject:(Code *)code withUuid:(NSString *)uuid {
    code.transactionId = uuid;
    
    if (self.adConfiguration) {
        [self setCommonCodeValues:code];
        
        if([self.adConfiguration.adFormats containsObject: AdFormat.banner]) {
            [self setBannerCodeValues:code];
            
        } else if ([self.adConfiguration.adFormats containsObject: AdFormat.video]) {
            [self setVideoCodeValues:code];
            
        }
    }
}

-(void)setCommonCodeValues:(Code *)code {
    code.owner = @"test";
    code.code = @"publishername_atf_desktop_rg_pave";
    
    code.isInterstitial = self.adConfiguration.isInterstitialAd;
}

-(void)setBannerCodeValues:(Code *)code {
    Banner *banner = [[Banner alloc] init];
    
    if(!self.adConfiguration.isInterstitialAd) {
        [banner addSize:self.adConfiguration.size];
    } else {
        [banner addSize:CGSizeMake(320, 480)];
    }
    
    //TODO: Check if there is an equivalent to Android AdPosition value
    banner.position = 1;
    
    [code.mediaTypes setBanner:banner];
}

- (void)setVideoCodeValues:(Code *)code {
    code.code = @"publishername_atf_desktop_rg_video";
    
    Video *video = [[Video alloc] init];
    
    [video setMimes:PBMConstants.supportedVideoMimeTypes];
    if (CGSizeEqualToSize(self.adConfiguration.size, CGSizeZero)) {
        self.adConfiguration.size = CGSizeMake(640.0f, 480.0f); //default video size
    }
    
    PBMORTBFormat *playerSize = [[PBMORTBFormat alloc] init];
    playerSize.h = [NSNumber numberWithFloat:self.adConfiguration.size.height];
    playerSize.w = [NSNumber numberWithFloat:self.adConfiguration.size.width];
    
    video.playerSizes = [NSArray arrayWithObject:playerSize];
    
    [code.mediaTypes setVideo:video];
}

@end
