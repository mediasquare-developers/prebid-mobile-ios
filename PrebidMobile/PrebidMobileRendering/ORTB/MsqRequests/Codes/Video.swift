//
//  Video.swift
//  PrebidMobile
//
//  Created by Steven Marie on 26/01/2023.
//  Copyright © 2023 AppNexus. All rights reserved.
//

import Foundation

@objcMembers
public class Video: PBMORTBAbstract {
    
    public var context: String = "outstream"
    
    public var playerSizes: [PBMORTBFormat] = [PBMORTBFormat]()
    
    public var mimes: [String] = [String]()
    
    // MARK: - Methods
    
    public override func toJsonDictionary() -> [String : Any] {
        var json:[String : Any] = [String : Any]()
        
        json["context"] = context
        
        if (!playerSizes.isEmpty) {
            var sizesArray: NSMutableArray = NSMutableArray()
            
            for size in playerSizes {
                sizesArray.add(size.toJsonArray())
            }
            
            json["playerSize"] = sizesArray
        }
        
        if (!mimes.isEmpty) {
            var mimesArray: NSMutableArray = NSMutableArray()
            
            for mime in mimes {
                mimesArray.add(mime)
            }
            
            json["mimes"] = mimesArray
        }
        
        return json
    }
}
