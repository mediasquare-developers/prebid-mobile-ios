//
//  Code.swift
//  PrebidMobile
//
//  Created by Steven Marie on 18/01/2023.
//  Copyright © 2023 AppNexus. All rights reserved.
//

import Foundation

@objcMembers
public class Code: PBMORTBAbstract {
    
    //MARK: - Properties
    
    public var owner: String? = nil
    public var code: String? = nil
    public var adUnit: String? = nil
    public var bidId: String? = nil
    public var auctionId: String? = nil
    public var transactionId: String? = nil
    
    public var mediaTypes: MediaType = MediaType()
    public var floor: Floor = Floor()
    
    public var isInterstitial: Bool = false
    
    //MARK: - Methods
    
    public override func toJsonDictionary() -> [String : Any] {
        var json:[String : Any] = [:]
        
        json["owner"] = (owner ?? "").isEmpty ? NSNull() : owner!
        json["code"] = (code ?? "").isEmpty ? NSNull() : code!
        json["adUnit"] = (adUnit ?? "").isEmpty ? NSNull() : adUnit!
        json["bidId"] = (bidId ?? "").isEmpty ? generatedUUID() : bidId!
        json["auctionId"] = (auctionId ?? "").isEmpty ? generatedUUID() : auctionId!
        json["transactionId"] = (transactionId ?? "").isEmpty ? NSNull() : transactionId!
        
        json["mediaTypes"] = mediaTypes.toJsonDictionary()
        json["floor"] = floor.toJsonDictionary()
        
        json["instl"] = isInterstitial ? 1 : 0
        
        return json
    }
    
    //MARK: - Utils
    
    fileprivate func generatedUUID() -> String {
        return UUID().uuidString
    }
}
