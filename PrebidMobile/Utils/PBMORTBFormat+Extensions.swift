//
//  PBMORTBFormat+Extension.swift
//  PrebidMobile
//
//  Created by Steven Marie on 20/10/2023.
//  Copyright © 2023 AppNexus. All rights reserved.
//

import Foundation

extension PBMORTBFormat {
    
    func toJsonArray() -> NSArray {
        let size = NSMutableArray()
        
        size.add(self.w ?? 0)
        size.add(self.h ?? 0)
        
        return size
    }
}
