//
//  PBMORTBMsqRequest.swift
//  PrebidMobile
//
//  Created by Steven Marie on 18/01/2023.
//  Copyright © 2023 AppNexus. All rights reserved.
//

import Foundation


@objcMembers
public class PBMORTBMsqRequest: PBMORTBAbstract {
    
    //MARK: - Properties
    
    public var codes: Array<Code> = Array()
    public var referer: String? = nil
    public var pbjs: String? = nil
    public var gdpr: Gdpr =  Gdpr()
    public var debug: Bool = false
    
    //MARK: - Methods
    
    public override func toJsonDictionary() -> [String : Any] {
        var json: [String : Any] = [:]
        
        if !codes.isEmpty {
            let codesMutableArray = NSMutableArray()
            
            for code in codes {
                codesMutableArray.add(code.toJsonDictionary())
            }
            
            json["codes"] = codesMutableArray
        }
        
        json["referer"] = (referer ?? "").isEmpty ? NSNull() : referer!
        json["pbjs"] = (pbjs ?? "").isEmpty ? NSNull() : pbjs!
        
        json["gdpr"] = gdpr.toJsonDictionary()
        
        json["debug"] = debug ? 1 : 0
        
        return json
    }
}
