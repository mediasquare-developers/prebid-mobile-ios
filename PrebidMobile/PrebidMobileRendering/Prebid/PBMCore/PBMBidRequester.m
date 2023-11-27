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

#import "PBMBidRequester.h"
#import "PBMBidResponseTransformer.h"
#import "PBMError.h"
#import "PBMORTBPrebid.h"
#import "PBMPrebidParameterBuilder.h"
#import "PBMParameterBuilderService.h"
#import "PBMORTBSDKConfiguration.h"

#import "PrebidMobileSwiftHeaders.h"
#if __has_include("PrebidMobile-Swift.h")
#import "PrebidMobile-Swift.h"
#else
#import <PrebidMobile/PrebidMobile-Swift.h>
#endif

#import "PBMMacros.h"

@interface PBMBidRequester ()

@property (nonatomic, strong, nonnull, readonly) id<PrebidServerConnectionProtocol> connection;
@property (nonatomic, strong, nonnull, readonly) Prebid *sdkConfiguration;
@property (nonatomic, strong, nonnull, readonly) Targeting *targeting;
@property (nonatomic, strong, nonnull, readonly) AdUnitConfig *adUnitConfiguration;

@property (nonatomic, copy, nullable) void (^completion)(BidResponse *, NSError *);

@end

@implementation PBMBidRequester

- (instancetype)initWithConnection:(id<PrebidServerConnectionProtocol>)connection
                  sdkConfiguration:(Prebid *)sdkConfiguration
                         targeting:(Targeting *)targeting
               adUnitConfiguration:(AdUnitConfig *)adUnitConfiguration {
    if (!(self = [super init])) {
        return nil;
    }
    _connection = connection;
    _sdkConfiguration = sdkConfiguration;
    _targeting = targeting;
    _adUnitConfiguration = adUnitConfiguration;
    return self;
}

- (void)requestBidsWithCompletion:(void (^)(BidResponse *, NSError *))completion {
    NSError * const setupError = [self findErrorInSettings];
    if (setupError) {
        completion(nil, setupError);
        return;
    }
    
    if (self.completion) {
        completion(nil, [PBMError requestInProgress]);
        return;
    }
    
    self.completion = completion ?: ^(BidResponse *r, NSError *e) {};
    
    NSString * const requestString = [self getRTBRequest];
    
    PBMLogInfo(@"Bid Request: %@", requestString);
    
    NSError * hostURLError = nil;
    NSString * const requestServerURL = [Host.shared getHostURLWithHost:self.sdkConfiguration.prebidServerHost error:&hostURLError];
    
    if (hostURLError) {
        completion(nil, hostURLError);
        return;
    }
    
    const NSInteger rawTimeoutMS_onRead     = self.sdkConfiguration.timeoutMillis;
    NSNumber * const dynamicTimeout_onRead  = self.sdkConfiguration.timeoutMillisDynamic;
        
    const NSTimeInterval postTimeout = (dynamicTimeout_onRead
                                        ? dynamicTimeout_onRead.doubleValue
                                        : (rawTimeoutMS_onRead / 1000.0));
    
    @weakify(self);
    NSDate * const requestDate = [NSDate date];
    [self.connection post:requestServerURL
                     data:[requestString dataUsingEncoding:NSUTF8StringEncoding]
                  timeout:postTimeout
                 callback:^(PrebidServerResponse * _Nonnull serverResponse) {
        @strongify(self);
        if (!self) { return; }
        
        void (^ const completion)(BidResponse *, NSError *) = self.completion;
        self.completion = nil;
        
        if (serverResponse.statusCode == 204) {
            completion(nil, PBMError.blankResponse);
            return;
        }
        
        if (serverResponse.error) {
            PBMLogInfo(@"Bid Request Error: %@", [serverResponse.error localizedDescription]);
            completion(nil, serverResponse.error);
            return;
        }
        
        PBMLogInfo(@"Bid Response: %@", [[NSString alloc] initWithData:serverResponse.rawData encoding:NSUTF8StringEncoding]);
        
        NSError *trasformationError = nil;
        BidResponse * const _Nullable bidResponse = [PBMBidResponseTransformer transformResponse:serverResponse error:&trasformationError];
        
        if (bidResponse && !trasformationError) {
            NSDate * const responseDate = [NSDate date];
            
            NSNumber * const tmaxrequest = bidResponse.tmaxrequest;
            if (tmaxrequest) {
                const NSTimeInterval bidResponseTimeout = tmaxrequest.doubleValue / 1000.0;
                const NSTimeInterval remoteTimeout = ([responseDate timeIntervalSinceDate:requestDate]
                                                      + bidResponseTimeout
                                                      + 0.2);
                NSString * const currentServerURL = [Host.shared getHostURLWithHost:self.sdkConfiguration.prebidServerHost error:nil];
                if (self.sdkConfiguration.timeoutMillisDynamic == nil && [currentServerURL isEqualToString:requestServerURL]) {
                    const NSInteger rawTimeoutMS_onWrite = self.sdkConfiguration.timeoutMillis;
                    const NSTimeInterval appTimeout = rawTimeoutMS_onWrite / 1000.0;
                    const NSTimeInterval updatedTimeout = MIN(remoteTimeout, appTimeout);
                    self.sdkConfiguration.timeoutMillisDynamic = @(updatedTimeout);
                    self.sdkConfiguration.timeoutUpdated = true;
                };
            }
            
            PBMORTBSDKConfiguration *pbsSDKConfig = [bidResponse.ext.extPrebid.passthrough filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(PBMORTBExtPrebidPassthrough *_Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                return [evaluatedObject.type isEqual: @"prebidmobilesdk"];
            }]].firstObject.sdkConfiguration;
            
            if(pbsSDKConfig) {
                if(pbsSDKConfig.cftBanner) {
                    Prebid.shared.creativeFactoryTimeout = pbsSDKConfig.cftBanner.doubleValue;
                }
                
                if(pbsSDKConfig.cftPreRender) {
                    Prebid.shared.creativeFactoryTimeoutPreRenderContent = pbsSDKConfig.cftPreRender.doubleValue;
                }
            }
            
            //TODO: call pixel TAG
            if (bidResponse.winningBid != nil) {
                id responseJson = [NSJSONSerialization JSONObjectWithData:serverResponse.rawData options:0 error:nil];
                [self callPixelTagWithResponse:responseJson andResponseTime:[responseDate timeIntervalSinceDate:requestDate]];
            }
        }
        
        completion(bidResponse, trasformationError);
    }];
}

- (NSString *)getRTBRequest {
    
    PBMPrebidParameterBuilder * const
    prebidParamsBuilder = [[PBMPrebidParameterBuilder alloc] initWithAdConfiguration:self.adUnitConfiguration
                                                                    sdkConfiguration:self.sdkConfiguration
                                                                           targeting:self.targeting
                                                                    userAgentService:self.connection.userAgentService];
    
    NSDictionary<NSString *, NSString *> * const
    params = [PBMParameterBuilderService buildParamsDictWithAdConfiguration:self.adUnitConfiguration.adConfiguration
                                                     extraParameterBuilders:@[prebidParamsBuilder]];
        
    return params[@"openrtb"];
}

- (NSError *)findErrorInSettings {
    if (!CGSizeEqualToSize(self.adUnitConfiguration.adSize, CGSizeZero)) {
        
        if ([self isInvalidSize:[NSValue valueWithCGSize:self.adUnitConfiguration.adSize]]) {
            return [PBMError prebidInvalidSize];
        }
    }
    if (self.adUnitConfiguration.additionalSizes) {
        for (NSValue *nextSize in self.adUnitConfiguration.additionalSizes) {
            if ([self isInvalidSize:nextSize]) {
                return [PBMError prebidInvalidSize];
            }
        }
    }
    if ([self isInvalidID:self.adUnitConfiguration.configId]) {
        return [PBMError prebidInvalidConfigId];
    }
    if ([self isInvalidID:self.sdkConfiguration.prebidServerAccountId]) {
        return [PBMError prebidInvalidAccountId];
    }
    return nil;
}

- (BOOL)isInvalidSize:(NSValue *)sizeObj {
    CGSize const size = sizeObj.CGSizeValue;
    return (size.width < 0 || size.height < 0);
}

- (BOOL)isInvalidID:(NSString *)idString {
    return (!idString || [idString isEqualToString:@""] || [[idString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet] length] == 0);
}

// Function to perform the POST request
- (void)callPixelTagWithResponse:(id )responseJson andResponseTime:(NSTimeInterval)responseTime {
    
    // API endpoint URL
    NSURL *url = [NSURL URLWithString:@"https://pbs-front.mediasquare.fr/winning"];

    // Create a mutable URL request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];

    // Set the request headers
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    responseJson = [[responseJson objectForKey:@"responses"] objectAtIndex:0];
    id requestJson = [NSJSONSerialization JSONObjectWithData:[[self getRTBRequest] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSDictionary *code =  [[requestJson objectForKey:@"codes"] objectAtIndex:0];
    
    bool gdprConsent = (long)[[requestJson objectForKey:@"gdpr"] objectForKey:@"consent_required"] == 1 && ![[[requestJson objectForKey:@"gdpr"] objectForKey:@"consent_string"] isEmpty];
    
    // Create JSON data from a dictionary
    NSDictionary *jsonDictionary = @{
        @"pbjs": [requestJson objectForKey:@"pbjs"],
        @"referer": [requestJson objectForKey:@"referer"],
        @"bidder": [responseJson objectForKey:@"bidder"],
        @"code": [code objectForKey:@"code"],
        @"hasConsent": [NSNumber numberWithBool:gdprConsent],
        @"increment": [responseJson objectForKey:@"increment"],
        @"ova": [responseJson objectForKey:@"ova"],
        @"cpm": [responseJson objectForKey:@"cpm"],
        @"size": [NSString stringWithFormat:@"%dx%d", (int)[responseJson objectForKey:@"width"], (int)[responseJson objectForKey:@"height"]],
        @"mediaType": [[[code objectForKey:@"mediaTypes"] allKeys] objectAtIndex:0],
        @"currency": [responseJson objectForKey:@"currency"],
        @"creativeId": [responseJson objectForKey:@"creative_id"],
        @"adUnitCode": [requestJson objectForKey:@"adUnit"],
        @"timeToRespond": [NSString stringWithFormat:@"%.f",round(responseTime * 1000)],
        @"requestId": [responseJson objectForKey:@"bid_id"],
        @"auctionId": [code objectForKey:@"auctionId"],
        @"originalCpm": [responseJson objectForKey:@"cpm"],
        @"originalCurrency": [responseJson objectForKey:@"currency"]
    };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];

    if (!jsonData) {
        NSLog(@"Error creating JSON data: %@", error.localizedDescription);
        return;
    }

    // Set the request body with JSON data
    [request setHTTPBody:jsonData];

    // Create a session configuration
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];

    // Create a session using the configuration
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    // Create a data task with the request
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
        } else {
            // Handle the response data
            NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Response: %@", result);
        }
    }];

    // Resume the task to initiate the request
    [dataTask resume];
    
}

@end
