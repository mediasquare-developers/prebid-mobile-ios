//
//  MsqNativeAsset.swift
//  PrebidMobile
//
//  Created by Steven Marie on 26/04/2023.
//  Copyright © 2023 AppNexus. All rights reserved.
//

import Foundation

@objcMembers
public class MsqNativeAsset: PBMORTBAbstract {
    
    // MARK: - Properties
    
    public var required: Bool = false
    
    public var len: Int? = nil
    
    public var aspectRatio: AssetRatio? = nil
    
    // MARK: - Methods
    
    public override func toJsonDictionary() -> [String : Any] {
        var json:[String : Any] = [String : Any]()
        
        json["required"] = required
        
        if let len = len {
            json["len"] = len
        }
        
        if let aspectRatio = aspectRatio {
            json["aspect_ratio"] = aspectRatio.toJsonDictionary()
        }
        
        return json
    }
}
