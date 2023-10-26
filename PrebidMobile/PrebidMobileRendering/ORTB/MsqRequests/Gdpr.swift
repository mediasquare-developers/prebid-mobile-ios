//
//  Gdpr.swift
//  PrebidMobile
//
//  Created by Steven Marie on 18/01/2023.
//  Copyright © 2023 AppNexus. All rights reserved.
//

import Foundation

@objcMembers
public class Gdpr: PBMORTBAbstract {
    
    //TODO: - TEST VALUES -> must be deleted after development
    private let testConsentString: String = "CPagOwAPagOwAAKApAENCTCsAP_AAH_AAAqII0Nd_X__bX9j-_5_bft0eY1P9_r37uQzjhfFs-8F3L_W_LwXw2E7NF36pq4KuR4Eu3LBIQNlHMHUTUmwaokVrzHsak2cpyNKJ7LEknMZO2dYGH9Pn9lDuYKY7_5___bx3D-t_t_-39T378Xf3_d5_2_--vCfV599jbn9fV_7_9nP___9v-_8__________wQpAJMNS4AC7MscGSSMIoUQIQrCQqAUAFFAMLRFYAMDgp2VgEOoIGACAVIRgRAgxBRgwCAAASAJCIgJACwQCIAiAQAAgAQAIQAETAILACwMAgAFANCxACgAECQgyICI5TAgKgSiglsrAEoK9jTCAMo8AKBRGRUACJJIQSAgJCwcxwAAAAgAAEAAAAA.f_gAAAAAAAAA"
    private let testConsentRequired: Bool = true
    
    //MARK: - Properties
    
    public var consentString: String? = nil
    public var consentRequired: Bool = false
    
    //MARK: - Methods
    
    public override func toJsonDictionary() -> [String : Any] {
        var json: [String : Any] = [:]
        
        //TODO: - TEST VALUES -> must be deleted after development
        if (consentString == nil || consentString!.isEmpty) {
            consentString = testConsentString
            consentRequired = testConsentRequired
        }
        
        json["consent_string"] = consentString
        json["consent_required"] = consentRequired
        
        return json
    }
}
