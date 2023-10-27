//
//  AssetRatio.swift
//  PrebidMobile
//
//  Created by Steven Marie on 26/04/2023.
//  Copyright © 2023 AppNexus. All rights reserved.
//

import Foundation

@objcMembers
public class AssetRatio: PBMORTBAbstract {
    
    // MARK: - Properties
    
    public var minWidth: Int = 0
    public var minHeight: Int = 0
    public var ratioWidth: Int = 0
    public var ratioHeight: Int = 0
    
    
    // MARK: - Methods
    
    public override func toJsonDictionary() -> [String : Any] {
        var jsonObj:[String : Any] = [String : Any]()
        
        jsonObj["min_width"] = minWidth
        jsonObj["min_height"] = minHeight
        jsonObj["ratio_width"] = ratioWidth
        jsonObj["ratio_height"] = ratioHeight
        
        return jsonObj
    }
}
