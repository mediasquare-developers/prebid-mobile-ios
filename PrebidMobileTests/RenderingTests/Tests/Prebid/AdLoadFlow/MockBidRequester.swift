/*   Copyright 2018-2021 Prebid.org, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import XCTest

@testable import PrebidMobile

class MockBidRequester: NSObject, PBMBidRequesterProtocol {
    typealias ExpectedCall = (@escaping (BidResponseForRendering?, Error?)->())->()
    
    private let expectedCalls: [ExpectedCall]
    private var nextCallIndex = 0
    private let syncQueue = DispatchQueue(label: "MockPrimaryAdRequester")
    
    private let file: StaticString
    private let line: UInt
    
    init(expectedCalls: [ExpectedCall], file: StaticString = #file, line: UInt = #line) {
        self.expectedCalls = expectedCalls
        self.file = file
        self.line = line
    }
    
    func requestBids(completion: @escaping (BidResponseForRendering?, Error?) -> Void) {
        let handler: ExpectedCall? = syncQueue.sync {
            guard nextCallIndex < expectedCalls.count else {
                XCTFail("[MockBidRequester] Call index out of bounds: \(nextCallIndex) < \(expectedCalls.count)",
                        file: file, line: line)
                return nil
            }
            let handler = expectedCalls[nextCallIndex]
            nextCallIndex += 1
            return handler
        }
        handler?(completion)
    }
}

extension MockBidRequester {
    class func compose(prefixAction: @escaping ()->(), expectedCall: @escaping ExpectedCall)->ExpectedCall {
        return {
            prefixAction()
            expectedCall($0)
        }
    }
}
