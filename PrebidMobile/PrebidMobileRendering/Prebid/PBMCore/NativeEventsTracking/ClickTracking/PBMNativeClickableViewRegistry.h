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

#import "PBMNativeAdMarkupLink.h"
#import "PBMNativeClickTrackerBinderFactoryBlock.h"
#import "PBMNativeViewClickHandlerBlock.h"

NS_ASSUME_NONNULL_BEGIN

@class UIView;


@interface PBMNativeClickableViewRegistry : NSObject

- (instancetype)initWithBinderFactory:(PBMNativeClickTrackerBinderFactoryBlock)binderFactory
                         clickHandler:(PBMNativeViewClickHandlerBlock)clickHandler NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (void)registerLink:(PBMNativeAdMarkupLink *)link forView:(UIView *)view;

/// does NOT overwrite 'url'+'fallback' if 'url' is already present
- (void)registerParentLink:(PBMNativeAdMarkupLink *)link forView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
