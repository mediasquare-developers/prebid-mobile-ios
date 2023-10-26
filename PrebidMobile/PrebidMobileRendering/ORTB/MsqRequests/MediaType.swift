//
//  MediaType.swift
//  PrebidMobile
//
//  Created by Steven Marie on 18/01/2023.
//  Copyright © 2023 AppNexus. All rights reserved.
//

import Foundation

@objcMembers
public class MediaType: PBMORTBAbstract {
    
    //MARK: - Properties (types)
    
    public var banner: Banner?
    public var video: Video?
    
    //MARK: - Methods
    
    public override func toJsonDictionary() -> [String : Any] {
        var json: [String : Any] = [:]
        
        if banner != nil {
            json["banner"] = banner!.toJsonDictionary()
        }
        
        if(video != nil) {
            json["video"] = video!.toJsonDictionary()
        }
        
        return json
    }
}
