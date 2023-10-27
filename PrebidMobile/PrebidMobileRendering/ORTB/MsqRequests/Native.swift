//
//  Native.swift
//  PrebidMobile
//
//  Created by Steven Marie on 26/01/2023.
//  Copyright © 2023 AppNexus. All rights reserved.
//

import Foundation

@objcMembers
public class Native: PBMORTBAbstract {
    
    // MARK: - Properties
    
    public var title: MsqNativeAsset? = nil
    
    public var body: MsqNativeAsset? = nil
    
    public var brand: MsqNativeAsset? = nil
    
    public var icon: MsqNativeAsset? = nil
    
    public var image: MsqNativeAsset? = nil
    
    public var clickUrl: MsqNativeAsset? = nil
    
    // MARK: - Methods

    public override init() {
        super.init()
        
        title = MsqNativeAsset()
        if let title = title {
            title.required = true
            title.len = 80
        }
        
        body = MsqNativeAsset()
        body!.required = true
        
        brand = MsqNativeAsset()
        
        icon = MsqNativeAsset()
        icon!.aspectRatio = AssetRatio()
        if let assetRatio = icon!.aspectRatio {
            assetRatio.minWidth = 50
            assetRatio.minHeight = 50
            assetRatio.ratioWidth = 1
            assetRatio.ratioHeight = 1
        }
        
        image = MsqNativeAsset()
        image!.aspectRatio = AssetRatio()
        if let assetRatio = image!.aspectRatio {
            assetRatio.minHeight = 300
            assetRatio.minHeight = 200
            assetRatio.ratioWidth = 3
            assetRatio.ratioHeight = 2
        }
        
        clickUrl = MsqNativeAsset()
        clickUrl!.required = true
    }
    
    public override func toJsonDictionary() -> [String : Any] {
        var json:[String : Any] = [String : Any]()
        
        if let title = title {
            json["title"] = title.toJsonDictionary()
        }
        
        if let body = body {
            json["body"] = body.toJsonDictionary()
        }
        
        if let brand = brand {
            json["brand"] = brand.toJsonDictionary()
        }
        
        if let icon = icon {
            json["icon"] = icon.toJsonDictionary()
        }
        
        if let clickUrl = clickUrl {
            json["clickUrl"] = clickUrl.toJsonDictionary()
        }
        
        return json
    }
}
