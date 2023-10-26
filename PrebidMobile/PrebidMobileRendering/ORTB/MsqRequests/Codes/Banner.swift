//
//  Banner.swift
//  PrebidMobile
//
//  Created by Steven Marie on 18/01/2023.
//  Copyright © 2023 AppNexus. All rights reserved.
//

import Foundation

@objcMembers
@objc public class Banner: PBMORTBAbstract {
    
    //MARK: - Properties
    
    public var sizes: [PBMORTBFormat] = [PBMORTBFormat]()
    public var position: Int = 1
    
    //MARK: - Methods
    
    public override func toJsonDictionary() -> [String : Any] {
        var json: [String : Any] = [:]
        
        if !sizes.isEmpty {
            var sizesMutableArray = NSMutableArray()
            
            for size in sizes {
                sizesMutableArray.add(size.toJsonArray())
            }
            
            json["sizes"] = sizesMutableArray
        }
        
        json["pos"] = position
        
        return json
    }
    
    @objc(addSize:)
    public func addSize(rawSize:CGSize) {
        var newSize = PBMORTBFormat()
        
        newSize.h = NSNumber(value: Float(rawSize.height))
        newSize.w = NSNumber(value: Float(rawSize.width))
        
        sizes.append(newSize)
    }
}
